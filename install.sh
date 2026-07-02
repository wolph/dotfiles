#!/bin/sh

delete=false
replace=false

git submodule init
git submodule update

while getopts dr o
do
    case "$o" in
        d) delete=true;;
        r) replace=true;;
        [?]) print >&2 "Usage: $0 [-r] [-d]"
    esac
done

link(){
    source="$1"
    destination="$2"

    if [ -h "$destination" ]; then
        echo "$destination already linked, not linking."
        return
    elif [ -e "$destination" ]; then
        if [ $replace ]; then
            mv -vi "$destination" "${destination}.bak"
        elif [ $delete ]; then
            rm -vi "$destination"
        fi
    fi

    if [ -e "$destination" ]; then
        echo "$destination already exists, not linking."
    else
        ln -sv "$source" "$destination"
    fi
}

for file in _*; do
    destination="$HOME/$(echo $file | sed 's/^_/./')"
    source=$PWD/$file
    link "$source" "$destination"
done

mkdir -p "$HOME/bin"
for file in bin/*; do
    destination="$HOME/$file"
    source=$PWD/$file
    link "$source" "$destination"
done

mkdir -p "$HOME/.config"
mkdir -p "$HOME/.vim/autoload"
ln -sfn "$HOME/.mpv" "$HOME/.config/mpv"
ln -sfn "$HOME/.vim" "$HOME/.config/nvim"
ln -sfn "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"
# vim.lua is the modern-nvim layer, loaded by the vimrc itself (nvim 0.11+
# guard). It must NOT exist as ~/.config/nvim/init.lua: nvim would treat it
# as a conflicting entry point. Clean up links from older installs.
rm -f "$HOME/.vim/init.lua"
rm -f "$HOME/.config/nvim/init.lua"
ln -sfn "$PWD/vim.lua" "$HOME/.vim/vim.lua"

# AI agent config: track only individual portable files; ~/.claude, ~/.codex and
# ~/.gemini hold runtime state (sessions, plugins, settings/config with secrets)
# and must not be linked wholesale.
mkdir -p "$HOME/.claude" "$HOME/.codex" "$HOME/.gemini"
ln -sf "$PWD/claude/statusline.js" "$HOME/.claude/statusline.js"
# Generate CLAUDE.md / AGENTS.md / GEMINI.md from the shared base + per-tool overrides.
"$PWD/bin/sync-agent-config"

# Git security hooks: lefthook runs bin/git-scan (secrets, machine paths,
# sensitive filenames, shell syntax) on pre-commit and pre-push. gitleaks is
# the primary secret engine; without it git-scan warns and uses a weaker
# builtin fallback scan.
ensure_tool(){
    tool="$1"
    formula="$2"
    gopkg="$3"
    if command -v "$tool" > /dev/null 2>&1; then
        return 0
    fi
    if command -v brew > /dev/null 2>&1 && brew install "$formula" && command -v "$tool" > /dev/null 2>&1; then
        return 0
    fi
    if command -v go > /dev/null 2>&1 && go install "$gopkg"; then
        # go installs into GOPATH/bin, which is often not on PATH yet.
        PATH="$PATH:$(go env GOPATH 2>/dev/null || echo "$HOME/go")/bin"
        export PATH
        if command -v "$tool" > /dev/null 2>&1; then
            return 0
        fi
    fi
    if [ "$tool" = lefthook ] && command -v npm > /dev/null 2>&1 && npm install -g lefthook && command -v "$tool" > /dev/null 2>&1; then
        return 0
    fi
    return 1
}

if ensure_tool lefthook lefthook github.com/evilmartians/lefthook@latest; then
    lefthook install
else
    echo "WARNING: could not install lefthook (no brew/go/npm); git security hooks NOT active."
    echo "         Install lefthook manually, then run: lefthook install"
fi
if ! ensure_tool gitleaks gitleaks github.com/gitleaks/gitleaks/v8@latest; then
    echo "WARNING: gitleaks unavailable; secret scan uses the weaker builtin fallback."
fi

# Download a URL to stdout with whichever of curl/wget this system has.
fetch(){
    url="$1"
    if command -v curl > /dev/null 2>&1; then
        curl -LsSf "$url"
    elif command -v wget > /dev/null 2>&1; then
        wget -qO- "$url"
    else
        return 1
    fi
}

# uv: Python package/project manager. Official installer puts it in
# ~/.local/bin (zshrc adds that to PATH permanently).
if ! command -v uv > /dev/null 2>&1; then
    fetch https://astral.sh/uv/install.sh | sh
fi

# fzf: brew where available, else the official git install into ~/.fzf
# (zshrc sources ~/.fzf.zsh, vimrc probes ~/.fzf - both already wired).
if ! command -v fzf > /dev/null 2>&1 && [ ! -d "$HOME/.fzf" ]; then
    if command -v brew > /dev/null 2>&1; then
        brew install fzf
    else
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" \
            && "$HOME/.fzf/install" --key-bindings --completion --no-update-rc
    fi
fi

# claude: Claude Code CLI, official native installer (installs to ~/.local/bin).
if ! command -v claude > /dev/null 2>&1; then
    fetch https://claude.ai/install.sh | bash
fi

# codex: OpenAI Codex CLI - brew, else npm.
if ! command -v codex > /dev/null 2>&1; then
    if command -v brew > /dev/null 2>&1; then
        brew install codex
    elif command -v npm > /dev/null 2>&1; then
        npm install -g @openai/codex
    fi
fi

# Installers above drop binaries in ~/.local/bin; make them visible to the
# rest of this run (zshrc handles PATH permanently). Pipe exit codes lie
# (`fetch|sh` returns sh's status even when the download failed), so success
# is checked by locating each binary instead.
PATH="$PATH:$HOME/.local/bin:$HOME/.fzf/bin"
export PATH
for tool in uv fzf claude codex; do
    if ! command -v "$tool" > /dev/null 2>&1; then
        echo "WARNING: $tool not installed; install it manually."
    fi
done

# kubernetes aliases
if type kubectl > /dev/null; then
    ./generate-kubernetes-aliases.sh
    for file in kubernetes-aliases/*; do
        destination="$HOME/bin/$(basename $file)"
        source=$PWD/$file
        link "$source" "$destination"
    done
fi

curl -L https://iterm2.com/shell_integration/zsh \
    -o ~/.iterm2_shell_integration.zsh

if [ ! -d ~/.tmux/plugins/tundle ]; then
    git clone --depth=1 https://github.com/javier-lopez/tundle \
        ~/.tmux/plugins/tundle
fi

if [ "$TMUX" ]; then
    tmux source-file ~/.tmux.conf
    ~/.tmux/plugins/tundle/scripts/install_plugins.sh
    ~/.tmux/plugins/tundle/scripts/update_plugins.sh all
fi
