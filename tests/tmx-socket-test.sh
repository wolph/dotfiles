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
if [ "${TMUX_MOCK_ACTIVE:-0}" = "1" ]; then
    case "$*" in
        *list-windows*-a*)
            printf "my-active-proj\t0:zsh*\n"
            ;;
        *list-sessions*)
            printf "my-active-proj\t1\t1\t1788000000\t1788000000\t$HOME/workspace/my-active-proj\n"
            ;;
    esac
fi
exit 0
SH
chmod +x "$TMPDIR/bin/tmux"

cat > "$TMPDIR/bin/fzf" <<'SH'
#!/bin/sh
if [ -n "${FZF_INPUT_LOG:-}" ]; then
    cat > "$FZF_INPUT_LOG"
fi
if [ "${FZF_EXIT_CODE:-0}" != "0" ]; then
    exit "${FZF_EXIT_CODE}"
fi
if [ -n "${FZF_MOCK_QUERY+x}" ] || [ -n "${FZF_MOCK_SELECTION+x}" ]; then
    printf '%s\n%s\n' "${FZF_MOCK_QUERY:-}" "${FZF_MOCK_SELECTION:-}"
    exit 0
fi
exit 0
SH
chmod +x "$TMPDIR/bin/fzf"

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

default_dir="$TMPDIR/workspace/my-test-proj"
mkdir -p "$default_dir"
default_log="$TMPDIR/tmux-default-dir.log"
: > "$default_log"
(
    cd "$default_dir"
    env \
        HOST=lappie \
        ITERM_PROFILE= \
        NO_TMUX=0 \
        OSTYPE=darwin \
        PATH="$TMPDIR/bin:$REAL_PATH" \
        TERM_PROGRAM=iTerm.app \
        TMUX= \
        TMUX_LOG="$default_log" \
        TMX_SOCKET_NAME=tmx-interactive \
        TMX_WORKSPACE_DIR="$TMPDIR/workspace" \
        "$ZSH_BIN" "$ROOT/bin/tmx" \
        >/dev/null
)

if ! grep -q -- "-s my-test-proj" "$default_log"; then
    printf 'FAIL: tmx without arguments did not use current directory name:\n' >&2
    cat "$default_log" >&2
    exit 1
fi

home_log="$TMPDIR/tmux-home-dir.log"
: > "$home_log"
home_out="$TMPDIR/tmux-home-out.log"
: > "$home_out"
(
    cd "$TMPDIR"
    env \
        HOME="$TMPDIR" \
        HOST=lappie \
        ITERM_PROFILE= \
        NO_TMUX=0 \
        OSTYPE=darwin \
        PATH="$TMPDIR/bin:$REAL_PATH" \
        TERM_PROGRAM=iTerm.app \
        TMUX= \
        TMUX_LOG="$home_log" \
        TMX_SOCKET_NAME=tmx-interactive \
        TMX_WORKSPACE_DIR="$TMPDIR/workspace" \
        "$ZSH_BIN" "$ROOT/bin/tmx" \
        >"$home_out"
)

if ! grep -q "Available sessions:" "$home_out"; then
    printf 'FAIL: tmx without arguments in home directory did not list available sessions:\n' >&2
    cat "$home_out" >&2
    exit 1
fi

if grep -q "new-session" "$home_log"; then
    printf 'FAIL: tmx without arguments in home directory created a new session:\n' >&2
    cat "$home_log" >&2
    exit 1
fi

mkdir -p "$TMPDIR/workspace/my-workspace-option"
table_log="$TMPDIR/tmux-table.log"
table_out="$TMPDIR/tmux-table-out.log"
: > "$table_log"
: > "$table_out"
(
    cd "$TMPDIR"
    env \
        HOME="$TMPDIR" \
        HOST=lappie \
        ITERM_PROFILE= \
        NO_TMUX=0 \
        OSTYPE=darwin \
        PATH="$TMPDIR/bin:$REAL_PATH" \
        TERM_PROGRAM=iTerm.app \
        TMUX= \
        TMUX_LOG="$table_log" \
        TMUX_MOCK_ACTIVE=1 \
        TMX_SOCKET_NAME=tmx-interactive \
        TMX_WORKSPACE_DIR="$TMPDIR/workspace" \
        "$ZSH_BIN" "$ROOT/bin/tmx" ls \
        >"$table_out"
)

if ! grep -q "^S  " "$table_out" || ! grep -q "my-active-proj" "$table_out" || ! grep -q "my-workspace-option" "$table_out"; then
    printf 'FAIL: tmx table output missing active or workspace options:\n' >&2
    cat "$table_out" >&2
    exit 1
fi

home_explicit_log="$TMPDIR/tmux-home-explicit.log"
: > "$home_explicit_log"
(
    cd "$TMPDIR"
    env \
        HOME="$TMPDIR" \
        HOST=lappie \
        ITERM_PROFILE= \
        NO_TMUX=0 \
        OSTYPE=darwin \
        PATH="$TMPDIR/bin:$REAL_PATH" \
        TERM_PROGRAM=iTerm.app \
        TMUX= \
        TMUX_LOG="$home_explicit_log" \
        TMX_SOCKET_NAME=tmx-interactive \
        TMX_WORKSPACE_DIR="$TMPDIR/workspace" \
        "$ZSH_BIN" "$ROOT/bin/tmx" explicit-session \
        >/dev/null
)

if ! grep -q -- "-s explicit-session" "$home_explicit_log"; then
    printf 'FAIL: tmx with explicit session in home directory failed to create session:\n' >&2
    cat "$home_explicit_log" >&2
    exit 1
fi

printf 'tmx socket tests passed\n'
