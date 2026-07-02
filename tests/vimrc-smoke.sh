#!/bin/sh
# Smoke tests for the layered vimrc.
# - universal checks always run (nvim startup, stock vim compatibility)
# - [modern] checks run only when nvim >= 0.11 and pyright/ruff exist
# - [fzf] check runs only when an fzf installation directory exists
# Exit 0 iff every applicable check passes.
#
# NOTE: this harness tests the INSTALLED config (~/.vimrc, ~/.vim), which the
# dotfiles install.sh symlinks into place from this repo. On an uninstalled
# clone (install.sh never run), results reflect whatever is already installed
# on the machine, not the files in this repo checkout.

fail=0
pass(){ printf 'PASS: %s\n' "$*"; }
failed(){ printf 'FAIL: %s\n' "$*"; fail=1; }

tmpdir=$(mktemp -d) || exit 1
trap 'rm -rf "$tmpdir"' EXIT
# Run from an empty dir: no .session.vim auto-restore, no exrc side effects.
cd "$tmpdir" || exit 1

# 1. nvim headless startup produces no output (errors/warnings print here)
if command -v nvim >/dev/null 2>&1; then
    out=$(nvim --headless -c 'qa!' 2>&1)
    if [ -z "$out" ]; then
        pass "nvim headless startup clean"
    else
        failed "nvim startup output: $out"
    fi
else
    printf 'SKIP: nvim not installed\n'
fi

# 2. stock vim can source the vimrc (compatibility floor for old systems)
if [ -x /usr/bin/vim ]; then
    if /usr/bin/vim -es -N -u "$HOME/.vimrc" -c 'qa!' </dev/null >/dev/null 2>&1; then
        pass "stock vim sources vimrc without errors"
    else
        failed "stock vim errored sourcing vimrc (run: /usr/bin/vim -N -u ~/.vimrc)"
    fi
else
    printf 'SKIP: /usr/bin/vim not present\n'
fi

# 3. [modern] pyright + ruff attach to Python buffers
modern=0
if command -v nvim >/dev/null 2>&1 \
   && nvim --headless -c 'if has("nvim-0.11") | qa! | else | cq | endif' >/dev/null 2>&1; then
    modern=1
fi
if [ "$modern" = 1 ] && command -v pyright-langserver >/dev/null 2>&1 \
   && command -v ruff >/dev/null 2>&1; then
    printf 'x = 1\n' > smoke.py
    n=$(nvim --headless smoke.py \
        -c 'lua vim.wait(15000, function() return #vim.lsp.get_clients() >= 2 end)' \
        -c 'lua io.stdout:write(tostring(#vim.lsp.get_clients()))' \
        -c 'qa!' 2>/dev/null)
    if [ "$n" = "2" ]; then
        pass "LSP: 2 clients (pyright + ruff) attached to .py buffer"
    else
        failed "LSP: ${n:-0} clients attached to .py buffer (want 2)"
    fi
else
    printf 'SKIP: modern LSP check (needs nvim>=0.11 + pyright-langserver + ruff)\n'
fi

# 4. [fzf] :FZF command is wired when fzf is installed
if [ -d /opt/homebrew/opt/fzf ] || [ -d /usr/local/opt/fzf ] || [ -d "$HOME/.fzf" ]; then
    if command -v nvim >/dev/null 2>&1; then
        r=$(nvim --headless \
            -c 'lua io.stdout:write(tostring(vim.fn.exists(":FZF")))' \
            -c 'qa!' 2>/dev/null)
        if [ "$r" = "2" ]; then
            pass ":FZF command defined"
        else
            failed ":FZF exists() = ${r:-?} (want 2) - fzf plugin not wired"
        fi
    else
        printf 'SKIP: fzf present but nvim not installed to verify :FZF\n'
    fi
else
    printf 'SKIP: no fzf installation directory found\n'
fi

exit "$fail"
