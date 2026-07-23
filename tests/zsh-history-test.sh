#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ZSH_BIN="$(command -v zsh)"
TEST_TMPDIR="$(mktemp -d)"
TEST_HOME="$TEST_TMPDIR/sandbox"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

mkdir -p "$TEST_HOME/project"
cat > "$TEST_HOME/.zshhistory" <<'HISTORY'
: 100:0;global-only
: 120:0;global-multiline\
second-line
: 130:0;printf '] * ?'
: 200:0;duplicate-command
HISTORY
cat > "$TEST_HOME/project/.zshhistory" <<'HISTORY'
: 150:0;project-only
: 240:0;printf '] * ?'
: 250:0;duplicate-command
HISTORY

env \
    HOME="$TEST_HOME" \
    HISTFILE="$TEST_TMPDIR/inherited/.zshhistory" \
    NO_TMUX=1 \
    ROOT="$ROOT" \
    TERM_PROGRAM= \
    TMX_AUTO_ATTACH=0 \
    "$ZSH_BIN" -dfi -c '
        cd "$HOME/project"
        source "$ROOT/_zshrc" >/dev/null 2>"$HOME/zshrc.err"

        [[ "$HISTFILE" == "$HOME/project/.zshhistory" ]] || {
            print -u2 "FAIL: project history file was not selected: $HISTFILE"
            exit 1
        }

        if export -p | command grep -q "HISTFILE="; then
            print -u2 "FAIL: HISTFILE is exported to child shells"
            exit 1
        fi

        child_histfile=$(
            /bin/bash --noprofile --norc -ic \
                '\''printf "%s" "$HISTFILE"'\'' 2>/dev/null
        )
        [[ "$child_histfile" == "$HOME/.bash_history" ]] || {
            print -u2 "FAIL: child Bash selected $child_histfile"
            exit 1
        }

        fc -R "$HISTFILE"
        print -s -- __history_test_sentinel__
        zmodload -F zsh/parameter p:history
        history_before="${(j:\x1f:)history[@]}"

        typeset -a candidate_commands
        while IFS= read -r -d $'\''\0'\'' candidate_command; do
            candidate_commands+=("$candidate_command")
        done < <(_fzf_history_candidates "$HOME/.zshhistory")

        [[ ${#candidate_commands} == 5 ]] || {
            print -u2 "FAIL: expected 5 unique candidates, got ${#candidate_commands}"
            exit 1
        }
        [[ "${candidate_commands[1]}" == global-only ]] || {
            print -u2 "FAIL: unexpected candidate order: ${(j:|:)candidate_commands}"
            exit 1
        }
        [[ "${candidate_commands[2]}" == $'\''global-multiline\nsecond-line'\'' ]] || {
            print -u2 "FAIL: multiline history was not preserved"
            exit 1
        }
        [[ "${candidate_commands[3]}" == project-only ]] || {
            print -u2 "FAIL: project history did not follow global history"
            exit 1
        }
        [[ "${candidate_commands[4]}" == *"] * ?"* ]] || {
            print -u2 "FAIL: metacharacter command was not deduplicated safely"
            exit 1
        }
        [[ "${candidate_commands[5]}" == duplicate-command ]] || {
            print -u2 "FAIL: project duplicate did not override global duplicate"
            exit 1
        }
        [[ "${(j:\x1f:)history[@]}" == "$history_before" ]] || {
            print -u2 "FAIL: collecting global history changed project history"
            exit 1
        }

        widget_source="${functions[init_fzf]}"
        [[ "$widget_source" == *"_fzf_history_candidates"* ]] || {
            print -u2 "FAIL: Ctrl-R widget does not use combined candidates"
            exit 1
        }
        [[ "$widget_source" == *"--read0"* ]] || {
            print -u2 "FAIL: Ctrl-R widget does not preserve multiline records"
            exit 1
        }
        [[ "$widget_source" == *"--print0"* ]] || {
            print -u2 "FAIL: Ctrl-R widget output is not NUL framed"
            exit 1
        }
        [[ "$widget_source" != *"candidate_commands"* ]] || {
            print -u2 "FAIL: Ctrl-R widget still builds a command lookup map"
            exit 1
        }
    '

printf 'zsh history tests passed\n'
