#!/usr/bin/env bash
set -euo pipefail

# claude/statusline.sh prints the upstream (herdr) line unchanged and then,
# only when the session's task list holds tasks, one line of task counts
# that fits the terminal width.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/claude/statusline.sh"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT
export LC_ALL=en_US.UTF-8

task() {
    # task <dir> <id> <status> <subject> [blockedBy-json]
    mkdir -p "$1"
    jq -n --arg id "$2" --arg st "$3" --arg subj "$4" --argjson bb "${5:-[]}" \
        '{id: $id, subject: $subj, description: "", status: $st, blocks: [], blockedBy: $bb}' \
        > "$1/$2.json"
}

T="$TMPDIR/tasks"
task "$T/repo-alpha" 1 in_progress "Wire statusline segment"
task "$T/repo-alpha" 2 pending     "Document the report"
task "$T/repo-alpha" 3 pending     "Release"                  '["1"]'
task "$T/repo-alpha" 4 completed   "Design"
task "$T/repo-alpha" 5 in_progress "Second active task"
long_subject="$(printf 'line one\nline two \033[31mred\033[0m %s' "$(printf 'x%.0s' $(seq 1 200))")"
task "$T/repo-long" 1 in_progress "$long_subject"
task "$T/session-abcdef12" 1 in_progress "Session scoped work"
mkdir -p "$T/repo-empty"

INPUT='{"session_id":"abcdef12-0000-0000-0000-000000000000","workspace":{"current_dir":"/nowhere"}}'
export CLAUDE_STATUSLINE_UPSTREAM='cat >/dev/null; echo UPSTREAM-LINE'
export CLAUDE_TASKS_DIR="$T"

failures=0
fail() { echo "FAIL $1"; failures=$((failures + 1)); }
strip_ansi() { sed $'s/\x1b\\[[0-9;]*m//g'; }

# run <list-id or ""> <COLUMNS>; output in $out, line count in $lines
run() {
    if [ -n "$1" ]; then
        out="$(printf '%s' "$INPUT" | CLAUDE_CODE_TASK_LIST_ID="$1" COLUMNS="$2" bash "$SCRIPT" 2>&1)" || true
    else
        out="$(printf '%s' "$INPUT" | env -u CLAUDE_CODE_TASK_LIST_ID COLUMNS="$2" bash "$SCRIPT" 2>&1)" || true
    fi
    lines="$(printf '%s\n' "$out" | wc -l | tr -d ' ')"
}

run repo-alpha 80
line1="$(sed -n 1p <<< "$out")"
line2="$(sed -n 2p <<< "$out" | strip_ansi)"
[ "$lines" = 2 ] && echo "ok populated list prints two lines" || fail "populated list: $lines lines: $out"
[ "$line1" = "UPSTREAM-LINE" ] && echo "ok upstream line comes first" || fail "upstream line: $line1"
expected='tasks 2 active ▸ 1 ready ▸ 1 blocked ▸ 1 done │ Wire statusline segment'
[[ "$line2" == "$expected"* ]] && echo "ok counts and first active subject" || fail "counts line: '$line2'"

run repo-long 60
line2="$(sed -n 2p <<< "$out" | strip_ansi)"
len="$(printf '%s' "$line2" | wc -m | tr -d ' ')"
[ "$lines" = 2 ] && echo "ok long subject stays on one line" || fail "long subject: $lines lines"
if printf '%s' "$line2" | LC_ALL=C grep -q $'\x1b'; then fail "escape byte survived: $line2"; else echo "ok control characters removed"; fi
[ "$len" -le 60 ] && echo "ok line fits COLUMNS ($len <= 60)" || fail "line too long: $len > 60"

run "" 80
[ "$lines" = 2 ] && [[ "$out" == *"tasks 1 active"* ]] && echo "ok session fallback directory" || fail "session fallback: $out"

rm -r "$T/session-abcdef12"
run "" 80
[ "$lines" = 1 ] && [ "$out" = "UPSTREAM-LINE" ] && echo "ok no session list prints upstream only" || fail "no session list: $out"

run repo-empty 80
[ "$lines" = 1 ] && [ "$out" = "UPSTREAM-LINE" ] && echo "ok empty directory prints upstream only" || fail "empty directory: $out"

if [ "$failures" -ne 0 ]; then
    echo "$failures check(s) failed"
    exit 1
fi
echo "all checks passed"
