#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STATE_BIN="$ROOT/bin/tmux-tab-state"
FORMAT_BIN="$ROOT/bin/tmux-tab-format"
COMPAT_STATE_BIN="$ROOT/bin/tmux-ai-tab-state"
COMPAT_FORMAT_BIN="$ROOT/bin/tmux-ai-tab-format"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

export XDG_RUNTIME_DIR="$TMPDIR/run"
export UID_FOR_TEST="${UID:-$(id -u)}"
export TMUX_PANE="%1"
export TMUX_STUB_LOG="$TMPDIR/tmux.log"
export PATH="$TMPDIR/bin:$PATH"

mkdir -p "$TMPDIR/bin" "$XDG_RUNTIME_DIR"

cat > "$TMPDIR/bin/tmux" <<'TMUX'
#!/usr/bin/env bash
set -euo pipefail

case "$1" in
  display-message)
    shift
    target=""
    format=""
    while [ "$#" -gt 0 ]; do
      case "$1" in
        -p) shift ;;
        -t) target="$2"; shift 2 ;;
        *) format="$1"; shift ;;
      esac
    done
    case "$target:$format" in
      "%1:#{window_id}") echo "@7" ;;
      "%1:#{window_name}") echo "codex" ;;
      "@7:#{window_id}") echo "@7" ;;
      "@7:#{window_index}") echo "3" ;;
      "@7:#{window_name}") echo "codex" ;;
      *) exit 1 ;;
    esac
    ;;
  list-panes)
    echo "%1 codex"
    ;;
  capture-pane)
    printf 'waiting for approval\n'
    ;;
  set-window-option)
    printf 'set-window-option %s\n' "$*" >> "$TMUX_STUB_LOG"
    exit 0
    ;;
  refresh-client)
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
TMUX
chmod +x "$TMPDIR/bin/tmux"

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'expected output to contain %q, got: %s\n' "$needle" "$haystack" >&2
    exit 1
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" == *"$needle"* ]]; then
    printf 'expected output not to contain %q, got: %s\n' "$needle" "$haystack" >&2
    exit 1
  fi
}

assert_file_contains() {
  local file="$1"
  local needle="$2"
  if ! grep -Fq "$needle" "$file"; then
    printf 'expected %s to contain %q\n' "$file" "$needle" >&2
    sed -n '1,120p' "$file" >&2 || true
    exit 1
  fi
}

json_out="$(printf '{}' | "$STATE_BIN" codex waiting Stop)"
[ "$json_out" = "{}" ]
assert_file_contains "$TMUX_STUB_LOG" "set-window-option -q -t @7 @tmux_tab_waiting 1"

highlight="$("$FORMAT_BIN" "@7" 0)"
assert_contains "$highlight" "3:codex"
assert_contains "$highlight" "bg=colour"
assert_contains "$highlight" "fg=colour16"
assert_contains "$highlight" "bold"

printf '{}' | "$STATE_BIN" codex busy UserPromptSubmit >/dev/null
assert_file_contains "$TMUX_STUB_LOG" "set-window-option -q -u -t @7 @tmux_tab_waiting"
busy="$("$FORMAT_BIN" "@7" 0)"
assert_contains "$busy" "3:codex"
assert_not_contains "$busy" "fg=colour16"

printf '{}' | "$STATE_BIN" codex clear SessionEnd >/dev/null
assert_file_contains "$TMUX_STUB_LOG" "set-window-option -q -u -t @7 @tmux_tab_waiting"
cleared="$("$FORMAT_BIN" "@7" 0)"
assert_contains "$cleared" "3:codex"
assert_not_contains "$cleared" "fg=colour16"

ag_out="$(printf '{}' | "$STATE_BIN" antigravity waiting Stop)"
[ "$ag_out" = '{"decision":"allow"}' ]

printf '{}' | "$COMPAT_STATE_BIN" legacy waiting Stop >/dev/null
compat_highlight="$("$COMPAT_FORMAT_BIN" "@7" 0)"
assert_contains "$compat_highlight" "3:codex"
assert_contains "$compat_highlight" "fg=colour16"

window_format="$(grep -F "set -g window-status-format" "$ROOT/_tmux.conf")"
current_format="$(grep -F "set -g window-status-current-format" "$ROOT/_tmux.conf")"
assert_contains "$window_format" "#{window_index}:#{window_name}"
assert_contains "$current_format" "#{window_index}:#{window_name}"
assert_not_contains "$window_format" "#("
assert_not_contains "$current_format" "#("

printf 'tmux tab state tests passed\n'
