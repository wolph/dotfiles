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
ln -sf "$HOME/.mpv" "$HOME/.config/mpv"
ln -sf "$HOME/.vim" "$HOME/.config/nvim"
ln -sf "$HOME/.vimrc" "$HOME/.config/nvim/init.vim"
ln -sf vim.lua "$HOME/.config/nvim/init.lua"

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
