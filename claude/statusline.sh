#!/usr/bin/env bash
# Claude Code status line: the herdr quota/context line first, then one line
# of task counts for this session's task list when that list holds tasks.
#
# Input: Claude Code's status line JSON on stdin. The task list directory is
# ~/.claude/tasks/$CLAUDE_CODE_TASK_LIST_ID (set by the claude() function in
# _zshrc) or ~/.claude/tasks/session-<first 8 of session_id> without it.
#
# Overrides, for tests: CLAUDE_STATUSLINE_UPSTREAM (the upstream command,
# run with bash -c and the JSON on its stdin) and CLAUDE_TASKS_DIR.
#
# A later `herdr-agent-quota configure claude` run overwrites
# statusLine.command in ~/.claude/settings.json with its own binary and backs
# this path up as the "original". The fix is to point statusLine.command
# back at ~/.claude/statusline.sh. The upstream command below is the single
# place to change when herdr changes its invocation.
set -u

UPSTREAM="${CLAUDE_STATUSLINE_UPSTREAM:-HERDR_PLUGIN_STATE_DIR=\"\$HOME/.local/state/herdr/plugins/herdr-agent-quota\" \"\$HOME/workspace/herdr-agent-quota/target/release/herdr-agent-quota\" claude-statusline}"
TASKS_DIR="${CLAUDE_TASKS_DIR:-$HOME/.claude/tasks}"
COLS="${COLUMNS:-80}"

GRAY=$'\033[38;5;241m'
YELLOW=$'\033[38;5;214m'
RESET=$'\033[0m'

input="$(cat)"

# Capture rather than stream: herdr prints its line without a trailing
# newline, and the task line below must land on its own row.
upstream_out="$(printf '%s' "$input" | bash -c "$UPSTREAM" 2>/dev/null || true)"
[ -n "$upstream_out" ] && printf '%s\n' "$upstream_out"

list_id="${CLAUDE_CODE_TASK_LIST_ID:-}"
if [ -z "$list_id" ]; then
    sid="$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)"
    [ -n "$sid" ] && list_id="session-${sid:0:8}"
fi
[ -n "$list_id" ] || exit 0

dir="$TASKS_DIR/$list_id"
shopt -s nullglob
files=("$dir"/*.json)
[ "${#files[@]}" -gt 0 ] || exit 0

summary="$(jq -rs '
    [ .[] | select(type == "object") ] | sort_by(.id | tonumber? // 0) as $t
    | ([$t[] | select(.status == "in_progress")] | length) as $active
    | ([$t[] | select(.status == "completed") | .id]) as $done
    | ([$t[] | select(.status == "pending" and ([(.blockedBy // [])[] | select(. as $b | ($done | index($b)) == null)] | length) == 0)] | length) as $ready
    | ([$t[] | select(.status == "pending" and ([(.blockedBy // [])[] | select(. as $b | ($done | index($b)) == null)] | length) > 0)] | length) as $blocked
    | ([$t[] | select(.status == "completed")] | length) as $done
    | (first($t[] | select(.status == "in_progress") | .subject // "") // "") as $subject
    | [$active, $ready, $blocked, $done, ($subject | gsub("[[:cntrl:]]"; ""))]
    | @tsv' "${files[@]}" 2>/dev/null)" || exit 0
[ -n "$summary" ] || exit 0

IFS=$'\t' read -r active ready blocked done subject <<< "$summary"
subject="$(printf '%s' "$subject" | tr -d '\000-\037\177')"

plain="tasks $active active ▸ $ready ready ▸ $blocked blocked ▸ $done done"
sep="${GRAY}▸${RESET}"
line="tasks $active active $sep $ready ready $sep $blocked blocked $sep $done done"

if [ -n "$subject" ]; then
    avail=$(( COLS - ${#plain} - 3 ))
    if [ "$avail" -ge 8 ]; then
        line="${line} ${GRAY}│${RESET} ${YELLOW}${subject:0:avail}${RESET}"
    fi
fi
printf '%s\n' "$line"
