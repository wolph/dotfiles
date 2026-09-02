#!/usr/bin/env bash
set -euo pipefail

# fixterm must undo every terminal mode a full-screen program (Claude Code,
# herdr, tmux, vim, htop, less) can leave behind when it dies without its
# teardown, typically because the ssh connection carrying it dropped.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSH_BIN="$(command -v zsh)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

ESC=$'\e'

# Extract only the function so the test does not depend on the rest of _zshrc.
sed -n '/^function fixterm()/,/^}/p' "$ROOT/_zshrc" > "$TMPDIR/fixterm.zsh"
if [ ! -s "$TMPDIR/fixterm.zsh" ]; then
    printf 'FAIL: fixterm function not found in _zshrc\n' >&2
    exit 1
fi

# fixterm must succeed even without a tty (stty sane has nothing to fix then).
if ! "$ZSH_BIN" -f -c "source '$TMPDIR/fixterm.zsh'; fixterm" \
    > "$TMPDIR/out" 2> "$TMPDIR/err" < /dev/null; then
    printf 'FAIL: fixterm exited nonzero\n' >&2
    cat "$TMPDIR/err" >&2
    exit 1
fi

if [ -s "$TMPDIR/err" ]; then
    printf 'FAIL: fixterm wrote to stderr:\n' >&2
    cat "$TMPDIR/err" >&2
    exit 1
fi

# Every sequence with its symptom when left switched on.
required=(
    "${ESC}[?1049l"   # alternate screen (xterm): prompt draws over the old frame
    "${ESC}[?1047l"   # alternate screen, no cursor save (older programs)
    "${ESC}[?47l"     # alternate screen, legacy
    "${ESC}[!p"       # DECSTR soft reset: cursor keys, keypad, margins, SGR, charsets
    "${ESC}[?1000l"   # mouse: clicks -> bell + garbage in zle
    "${ESC}[?1002l"   # mouse: button motion
    "${ESC}[?1003l"   # mouse: any motion -> continuous bells
    "${ESC}[?1005l"   # mouse: UTF-8 coordinates
    "${ESC}[?1006l"   # mouse: SGR coordinates
    "${ESC}[?1015l"   # mouse: urxvt coordinates
    "${ESC}[?1016l"   # mouse: SGR pixel coordinates
    "${ESC}[?1004l"   # focus reporting: clicking the tab sends ESC [ I
    "${ESC}[?2004l"   # bracketed paste
    "${ESC}[?1007l"   # alternate scroll: wheel becomes arrow keys
    "${ESC}[?2026l"   # synchronized output: frames withheld
    "${ESC}[<u"       # kitty keyboard protocol: pop pushed flags
    "${ESC}[=0;1u"    # kitty keyboard protocol: clear flags outright
    "${ESC}[>4;0m"    # modifyOtherKeys off
    "${ESC}[?7h"      # autowrap on
    "${ESC}[?1l"      # cursor keys normal
    "${ESC}>"         # keypad numeric
    "${ESC}[?25h"     # cursor visible
    "${ESC}[0 q"      # cursor style default
    "${ESC}[0m"       # SGR attributes
    "${ESC}(B"        # G0 charset ASCII
)
for seq in "${required[@]}"; do
    if ! grep -qaF -- "$seq" "$TMPDIR/out"; then
        printf 'FAIL: fixterm output lacks %q\n' "$seq" >&2
        exit 1
    fi
done

offset_of() {
    grep -aboF -- "$1" "$TMPDIR/out" | head -n 1 | cut -d: -f1
}
alt_off="$(offset_of "${ESC}[?1049l")"
sgr_off="$(offset_of "${ESC}[0m")"
if [ "$alt_off" -ge "$sgr_off" ]; then
    printf 'FAIL: fixterm must leave the alternate screen before resetting attributes\n' >&2
    exit 1
fi

# iTerm2 3.6 only leaves the alternate screen for the pair 1049h + 1049l.
if ! grep -qaF -- "${ESC}[?1049h${ESC}[?1049l" "$TMPDIR/out"; then
    printf 'FAIL: fixterm must send 1049h immediately followed by 1049l\n' >&2
    exit 1
fi

# A bare DECSTBM homes the cursor, which makes the next prompt overwrite the
# top of the screen. DECSTR already resets the margins.
if grep -qaE -- "${ESC}\[[0-9;]*r" "$TMPDIR/out"; then
    printf 'FAIL: fixterm must not send DECSTBM (ESC [ r)\n' >&2
    exit 1
fi

# Nothing else may be switched on except autowrap and cursor visibility.
if perl -ne 'exit 1 if /\e\[\?(?!7h|25h|1049h\e\[\?1049l)[0-9;]+h/' "$TMPDIR/out"; then :; else
    printf 'FAIL: fixterm switches a private mode on:\n' >&2
    cat -v "$TMPDIR/out" >&2
    exit 1
fi

# Only escape sequences: no printable text may reach the terminal.
leftover="$(perl -pe 's/\e\[[0-9;?<=>!]* ?[A-Za-z@~]|\e[()][A-Za-z0-9]|\e[=>]//g' "$TMPDIR/out")"
if [ -n "$leftover" ]; then
    printf 'FAIL: fixterm printed text besides escape sequences: %q\n' "$leftover" >&2
    exit 1
fi

# The wrappers must call fixterm after the remote command returns.
for fn in ssh mosh; do
    body="$TMPDIR/$fn.zsh"
    sed -n "/^function $fn()/,/^}/p" "$ROOT/_zshrc" > "$body"
    cmd_line="$(grep -nE '^\s*(/usr/bin/ssh|command mosh) ' "$body" | tail -n 1 | cut -d: -f1)"
    fix_line="$(grep -nE '^\s*fixterm$' "$body" | tail -n 1 | cut -d: -f1)"
    if [ -z "$cmd_line" ] || [ -z "$fix_line" ] || [ "$fix_line" -le "$cmd_line" ]; then
        printf 'FAIL: %s() does not call fixterm after the remote command\n' "$fn" >&2
        exit 1
    fi
done

printf 'fixterm tests passed\n'
