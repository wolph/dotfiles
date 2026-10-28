#!/usr/bin/env bash
# bin/sync-codex-config: shared keys land in a machine config.toml without
# touching anything else, multi-line arrays are replaced whole, a second run
# is a no-op, and an empty target gets a complete file.
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "${tmp:?}"' EXIT

cat > "$tmp/config.toml" <<'TOML'
# machine comment
model = "gpt-old"
model_reasoning_effort = "low"
notify = ["/usr/bin/true", "turn-ended"]

[tui]
status_line = [
    "model-with-reasoning",
    "current-dir",
]
screen_reader_detection_done = true

[mcp_servers.local]
command = "/usr/bin/true"

[features]
js_repl = true
TOML

"$repo/bin/sync-codex-config" "$tmp/config.toml" >/dev/null
python3 - "$tmp/config.toml" "$repo/codex/config.shared.toml" <<'PY'
import sys, tomllib
got = tomllib.load(open(sys.argv[1], "rb"))
shared = tomllib.load(open(sys.argv[2], "rb"))
for key, value in shared.items():
    if isinstance(value, dict):
        for sub, sub_value in value.items():
            assert got[key][sub] == sub_value, (key, sub, got[key].get(sub))
    else:
        assert got[key] == value, (key, got.get(key))
assert got["notify"] == ["/usr/bin/true", "turn-ended"], "machine key lost"
assert got["tui"]["screen_reader_detection_done"] is True, "machine tui key lost"
assert got["mcp_servers"]["local"]["command"] == "/usr/bin/true", "mcp server lost"
assert got["features"]["js_repl"] is True, "machine feature lost"
PY
grep -q '^# machine comment$' "$tmp/config.toml" || { echo "comment lost"; exit 1; }
ls "$tmp"/config.toml.bak-* >/dev/null || { echo "no backup written"; exit 1; }
out="$("$repo/bin/sync-codex-config" "$tmp/config.toml")"
case "$out" in *"already in sync"*) ;; *) echo "second run not a no-op: $out"; exit 1 ;; esac

: > "$tmp/empty.toml"
"$repo/bin/sync-codex-config" "$tmp/empty.toml" >/dev/null
python3 -c 'import sys, tomllib; d = tomllib.load(open(sys.argv[1], "rb")); assert d["features"]["hooks"] is True' "$tmp/empty.toml"
echo "sync-codex-config tests passed"
