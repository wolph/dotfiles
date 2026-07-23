#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSH_BIN="$(command -v zsh)"
REAL_GREP="$(command -v grep)"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/sandbox/.ssh" "$TMPDIR/minimal-bin"

cat > "$TMPDIR/minimal-bin/grep" <<'SH'
#!/bin/sh
for arg in "$@"; do
    case "$arg" in
        --color=*|--directories=*)
            exit 2
            ;;
    esac
done
exec "$REAL_GREP" "$@"
SH
chmod +x "$TMPDIR/minimal-bin/grep"

cat > "$TMPDIR/minimal-bin/ls" <<'SH'
#!/bin/sh
for arg in "$@"; do
    case "$arg" in
        --color|--color=*)
            exit 2
            ;;
    esac
done
exit 0
SH
chmod +x "$TMPDIR/minimal-bin/ls"

for command_name in date less rm; do
    command_path="$(command -v "$command_name")"
    ln -s "$command_path" "$TMPDIR/minimal-bin/$command_name"
done

syntax_output="$("$ZSH_BIN" -n "$ROOT/_zshrc" 2>&1)"
if [ -n "$syntax_output" ]; then
    printf 'FAIL: zsh syntax check emitted output:\n%s\n' "$syntax_output" >&2
    exit 1
fi

env \
    ROOT="$ROOT" \
    REAL_GREP="$REAL_GREP" \
    TMPDIR="$TMPDIR" \
    HOME="$TMPDIR/sandbox" \
    PATH="$TMPDIR/minimal-bin" \
    NO_TMUX=1 \
    TMX_AUTO_ATTACH=0 \
    SSH_AUTH_SOCK="$TMPDIR/sandbox/.ssh/auth_sock" \
    "$ZSH_BIN" -f <<'ZSH'
ROOT="${ROOT:?}"
cd "$ROOT"

OSTYPE=linux-gnu
if ! source "$ROOT/_zshrc" >/dev/null 2>"$TMPDIR/zshrc.err"; then
    print -u2 'FAIL: _zshrc failed to source for linux-gnu'
    cat "$TMPDIR/zshrc.err" >&2
    exit 1
fi

failures=0

for alias_name in ${(k)aliases}; do
    alias_value="${aliases[$alias_name]}"
    if [[ "$alias_value" == /* ]]; then
        print -u2 "FAIL: linux alias $alias_name pins absolute command: $alias_value"
        failures=1
    fi
done

for alias_name in locate updatedb-all; do
    if (( $+aliases[$alias_name] )); then
        print -u2 "FAIL: linux should not override $alias_name: ${aliases[$alias_name]}"
        failures=1
    fi
done

minimal_absent_aliases=(
    vlc
    git
    qmv
    push
    vim
    vimdiff
    view
    vi
    parallel
    feh
    montage
    tb
    ssh-copy-id
    docker-compose
    claude
    codex
    gemini
    agy
    s
)

for alias_name in $minimal_absent_aliases; do
    if (( $+aliases[$alias_name] )); then
        print -u2 "FAIL: minimal linux should not define $alias_name: ${aliases[$alias_name]}"
        failures=1
    fi
done

if (( $+aliases[ls] )) && [[ "${aliases[ls]}" == *--color* ]]; then
    print -u2 "FAIL: ls alias uses unsupported color flags: ${aliases[ls]}"
    failures=1
fi

if (( $+aliases[grep] )) && [[ "${aliases[grep]}" == *--color* || "${aliases[grep]}" == *--directories=* ]]; then
    print -u2 "FAIL: grep alias uses unsupported GNU flags: ${aliases[grep]}"
    failures=1
fi

if (( failures )); then
    exit 1
fi

ZSH

cat > "$TMPDIR/minimal-bin/tmux" <<'SH'
#!/bin/sh

socket_name=''
if [ "$1" = -L ]; then
    socket_name="$2"
    shift 2
fi

case "$1" in
    list-sessions)
        exit 1
        ;;
    new-session)
        printf -- '-L %s %s\n' "$socket_name" "$*" >> "$TMUX_LOG"
        exit 0
        ;;
    has-session)
        exit 1
        ;;
esac

exit 0
SH
chmod +x "$TMPDIR/minimal-bin/tmux"

TMUX_LOG="$TMPDIR/tmux.log"
export TMUX_LOG

run_keeper_shell() {
    env \
        ROOT="$ROOT" \
        REAL_GREP="$REAL_GREP" \
        TMPDIR="$TMPDIR" \
        HOME="$TMPDIR/sandbox" \
        HOST=lappie \
        OSTYPE=darwin \
        PATH="$TMPDIR/minimal-bin" \
        NO_TMUX=0 \
        TMUX_AUTO_ATTACH=0 \
        TMX_KEEPER="$1" \
        TERM_PROGRAM=iTerm.app \
        SSH_AUTH_SOCK="$TMPDIR/sandbox/.ssh/auth_sock" \
        "$ZSH_BIN" -fic 'source "$ROOT/_zshrc"' \
        >/dev/null 2>"$TMPDIR/keeper-zshrc.err"
}

: > "$TMUX_LOG"
if ! run_keeper_shell 1; then
    printf 'FAIL: keeper shell failed:\n' >&2
    cat "$TMPDIR/keeper-zshrc.err" >&2
    exit 1
fi

expected_keeper_call="-L tmx-interactive new-session -d -s __tmux_keeper -c $TMPDIR/sandbox"
actual_keeper_call="$(cat "$TMUX_LOG")"
if [ "$actual_keeper_call" != "$expected_keeper_call" ]; then
    printf 'FAIL: expected keeper call %s, got %s\n' \
        "$expected_keeper_call" "$actual_keeper_call" >&2
    exit 1
fi

: > "$TMUX_LOG"
if ! run_keeper_shell 0; then
    printf 'FAIL: disabled keeper shell failed:\n' >&2
    cat "$TMPDIR/keeper-zshrc.err" >&2
    exit 1
fi

if [ -s "$TMUX_LOG" ]; then
    printf 'FAIL: TMX_KEEPER=0 started tmux: %s\n' "$(cat "$TMUX_LOG")" >&2
    exit 1
fi

printf 'zsh portability tests passed\n'
