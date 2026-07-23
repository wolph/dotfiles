#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSH_BIN="$(command -v zsh)"
REAL_PATH="$PATH"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/bin" "$TMPDIR/workspace"

cat > "$TMPDIR/bin/tmux" <<'SH'
#!/bin/sh
printf '%s\n' "$*" >> "$TMUX_LOG"
exit 0
SH
chmod +x "$TMPDIR/bin/tmux"

run_socket_case() {
    local host_name="$1"
    local ostype="$2"
    local socket_name="$3"
    local expected_socket="$4"
    local log_file="$TMPDIR/tmux-$host_name-$expected_socket.log"

    : > "$log_file"
    env \
        HOST="$host_name" \
        ITERM_PROFILE= \
        NO_TMUX=0 \
        OSTYPE="$ostype" \
        PATH="$TMPDIR/bin:$REAL_PATH" \
        TERM_PROGRAM=iTerm.app \
        TMUX= \
        TMUX_LOG="$log_file" \
        TMX_SOCKET_NAME="$socket_name" \
        TMX_WORKSPACE_DIR="$TMPDIR/workspace" \
        "$ZSH_BIN" "$ROOT/bin/tmx" ls \
        >/dev/null

    if [ ! -s "$log_file" ]; then
        printf 'FAIL: tmx did not invoke tmux for socket %s\n' "$expected_socket" >&2
        exit 1
    fi

    if grep -Evq "^-L $expected_socket( |$)" "$log_file"; then
        printf 'FAIL: tmx bypassed socket %s:\n' "$expected_socket" >&2
        cat "$log_file" >&2
        exit 1
    fi
}

run_socket_case lappie darwin '' tmx-interactive
run_socket_case lappie darwin default default
run_socket_case linux-host linux-gnu '' default
run_socket_case linux-host linux-gnu shared shared

cross_socket_log="$TMPDIR/tmux-cross-socket.log"
: > "$cross_socket_log"
if env \
        HOST=lappie \
        ITERM_PROFILE= \
        OSTYPE=darwin \
        PATH="$TMPDIR/bin:$REAL_PATH" \
        TERM_PROGRAM=iTerm.app \
        TMUX="$TMPDIR/tmux-501/default,123,0" \
        TMUX_LOG="$cross_socket_log" \
        TMX_SOCKET_NAME=tmx-interactive \
        TMX_WORKSPACE_DIR="$TMPDIR/workspace" \
        "$ZSH_BIN" "$ROOT/bin/tmx" ls \
        >/dev/null 2>"$TMPDIR/cross-socket.err"; then
    printf 'FAIL: tmx allowed nested access from socket default to socket tmx-interactive\n' >&2
    exit 1
fi

if ! grep -q "tmux socket 'default'" "$TMPDIR/cross-socket.err"; then
    printf 'FAIL: tmx did not explain the cross-socket refusal:\n' >&2
    cat "$TMPDIR/cross-socket.err" >&2
    exit 1
fi

completion_log="$TMPDIR/tmux-completion.log"
: > "$completion_log"
env \
    HOME="$TMPDIR" \
    PATH="$TMPDIR/bin:$REAL_PATH" \
    ROOT="$ROOT" \
    TMUX_LOG="$completion_log" \
    TMX_SOCKET_NAME=tmx-interactive \
    "$ZSH_BIN" -fc 'function _wanted(){ return 0 }; source "$ROOT/_zsh/site-functions/_tmx"' \
    >/dev/null

if [ ! -s "$completion_log" ] || grep -Evq '^-L tmx-interactive( |$)' "$completion_log"; then
    printf 'FAIL: tmx completion bypassed socket tmx-interactive:\n' >&2
    cat "$completion_log" >&2
    exit 1
fi

printf 'tmx socket tests passed\n'
