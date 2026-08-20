#!/bin/zsh

set -eu

typeset -r REPOSITORY_ROOT="${0:A:h:h}"
typeset -r WATCHDOG_BIN="$REPOSITORY_ROOT/bin/stale-process-watchdog"
typeset -r FIXTURE_ROOT="$(/usr/bin/mktemp -d "${TMPDIR:-/tmp}/stale-process-watchdog-test.XXXXXX")"
typeset -r FIXTURE_BIN="$FIXTURE_ROOT/bin"

trap '/bin/rm -rf "$FIXTURE_ROOT"' EXIT

/bin/mkdir -p "$FIXTURE_BIN"

/bin/cat > "$FIXTURE_BIN/ps" <<'EOF'
#!/bin/zsh

set -u

if [[ "$*" == "-axo pid=,etime=,lstart=,comm=" ]]; then
    /bin/cat "$FIXTURE_PROCESS_FILE"
    exit 0
fi

if (( $# == 4 )) && [[ "$1" == "-p" && "$3" == "-o" && "$4" == "lstart=,comm=" ]]; then
    typeset -r identity_file="$FIXTURE_IDENTITY_DIR/$2"
    [[ -f "$identity_file" ]] || exit 1
    /bin/cat "$identity_file"
    exit 0
fi

exit 2
EOF

/bin/cat > "$FIXTURE_BIN/kill" <<'EOF'
#!/bin/zsh

set -u

typeset -r signal_name="${1#-}"
typeset -r pid="$3"
print -r -- "$signal_name $pid" >> "$FIXTURE_ACTION_LOG"
EOF

/bin/cat > "$FIXTURE_BIN/sleep" <<'EOF'
#!/bin/zsh

set -u

print -r -- "sleep $1" >> "$FIXTURE_ACTION_LOG"

typeset pid
for pid in ${=FIXTURE_GRACEFUL_PIDS}; do
    /bin/rm -f "$FIXTURE_IDENTITY_DIR/$pid"
done

typeset change_file
for change_file in "$FIXTURE_IDENTITY_DIR"/*.after(N); do
    /bin/mv "$change_file" "${change_file%.after}"
done
EOF

/bin/cat > "$FIXTURE_BIN/date" <<'EOF'
#!/bin/zsh

print -r -- "2026-08-21T12:00:00+0200"
EOF

/bin/chmod 0755 "$FIXTURE_BIN/ps" "$FIXTURE_BIN/kill" "$FIXTURE_BIN/sleep" "$FIXTURE_BIN/date"

typeset CASE_ROOT=""
typeset PROCESS_FILE=""
typeset IDENTITY_DIR=""
typeset ACTION_LOG=""
typeset MESSAGE_LOG=""

reset_case() {
    typeset -r case_name="$1"
    CASE_ROOT="$FIXTURE_ROOT/$case_name"
    PROCESS_FILE="$CASE_ROOT/processes"
    IDENTITY_DIR="$CASE_ROOT/identities"
    ACTION_LOG="$CASE_ROOT/actions"
    MESSAGE_LOG="$CASE_ROOT/messages"
    /bin/mkdir -p "$IDENTITY_DIR"
    : > "$PROCESS_FILE"
    : > "$ACTION_LOG"
    : > "$MESSAGE_LOG"
}

set_identity() {
    typeset -r pid="$1"
    typeset -r identity="$2"
    print -r -- "$identity" > "$IDENTITY_DIR/$pid"
}

set_changed_identity() {
    typeset -r pid="$1"
    typeset -r identity="$2"
    print -r -- "$identity" > "$IDENTITY_DIR/$pid.after"
}

run_watchdog() {
    typeset -r graceful_pids="${1:-}"
    /usr/bin/env \
        WATCHDOG_PS="$FIXTURE_BIN/ps" \
        WATCHDOG_KILL="$FIXTURE_BIN/kill" \
        WATCHDOG_SLEEP="$FIXTURE_BIN/sleep" \
        WATCHDOG_DATE="$FIXTURE_BIN/date" \
        WATCHDOG_LOG_FILE="$MESSAGE_LOG" \
        FIXTURE_PROCESS_FILE="$PROCESS_FILE" \
        FIXTURE_IDENTITY_DIR="$IDENTITY_DIR" \
        FIXTURE_ACTION_LOG="$ACTION_LOG" \
        FIXTURE_GRACEFUL_PIDS="$graceful_pids" \
        /bin/zsh "$WATCHDOG_BIN"
}

assert_file_equals() {
    typeset -r expected="$1"
    typeset -r actual_file="$2"
    typeset -r description="$3"
    typeset -r actual="$(/bin/cat "$actual_file")"

    if [[ "$actual" != "$expected" ]]; then
        print -u2 -r -- "FAIL: $description"
        print -u2 -r -- "expected:"
        print -u2 -r -- "$expected"
        print -u2 -r -- "actual:"
        print -u2 -r -- "$actual"
        return 1
    fi
}

assert_contains() {
    typeset -r expected="$1"
    typeset -r actual_file="$2"
    typeset -r description="$3"

    if ! /usr/bin/grep -Fq -- "$expected" "$actual_file"; then
        print -u2 -r -- "FAIL: $description"
        print -u2 -r -- "missing: $expected"
        print -u2 -r -- "actual:"
        /bin/cat "$actual_file" >&2
        return 1
    fi
}

if [[ ! -f "$WATCHDOG_BIN" ]]; then
    print -u2 -r -- "FAIL: watchdog executable is absent: $WATCHDOG_BIN"
    exit 1
fi

reset_case selection
/bin/cat > "$PROCESS_FILE" <<'EOF'
101 59:59 Wed Aug 21 09:00:00 2026 /System/Library/CoreServices/ReportCrash
102 01:00:00 Wed Aug 21 08:59:59 2026 /System/Library/CoreServices/ReportCrash
103 01:00:01 Wed Aug 21 08:59:58 2026 /System/Library/CoreServices/ReportCrash
104 02:00:01 Wed Aug 21 07:59:58 2026 /Applications/Reolink.app/Contents/MacOS/Reolink
105 1-00:00:01 Tue Aug 20 09:59:58 2026 /Applications/Reolink.app/Contents/Frameworks/Reolink Helper.app/Contents/MacOS/Reolink Helper
106 999:99 Wed Aug 21 09:00:00 2026 /System/Library/CoreServices/ReportCrash
107 02:00:01 Wed Aug 21 07:59:58 2026 /tmp/ReportCrash
108 02:00:01 Wed Aug 21 07:59:58 2026 /Applications/Reolink Backup.app/Contents/MacOS/Reolink
EOF
set_identity 103 "Wed Aug 21 08:59:58 2026 /System/Library/CoreServices/ReportCrash"
set_identity 104 "Wed Aug 21 07:59:58 2026 /Applications/Reolink.app/Contents/MacOS/Reolink"
set_identity 105 "Tue Aug 20 09:59:58 2026 /Applications/Reolink.app/Contents/Frameworks/Reolink Helper.app/Contents/MacOS/Reolink Helper"
run_watchdog
assert_file_equals $'TERM 103\nTERM 104\nTERM 105\nsleep 10\nKILL 103\nKILL 104\nKILL 105' "$ACTION_LOG" \
    "select only stale exact ReportCrash and Reolink bundle executables"
assert_contains "executable=/System/Library/CoreServices/ReportCrash pid=106 elapsed=999:99 signal=none outcome=malformed" \
    "$MESSAGE_LOG" "log malformed target elapsed time"

reset_case graceful_exit
print -r -- "201 01:00:01 Wed Aug 21 08:59:58 2026 /System/Library/CoreServices/ReportCrash" > "$PROCESS_FILE"
set_identity 201 "Wed Aug 21 08:59:58 2026 /System/Library/CoreServices/ReportCrash"
run_watchdog "201"
assert_file_equals $'TERM 201\nsleep 10' "$ACTION_LOG" "avoid KILL after graceful exit"

reset_case changed_launch_time
print -r -- "301 01:00:01 Wed Aug 21 08:59:58 2026 /Applications/Reolink.app/Contents/MacOS/Reolink" > "$PROCESS_FILE"
set_identity 301 "Wed Aug 21 08:59:58 2026 /Applications/Reolink.app/Contents/MacOS/Reolink"
set_changed_identity 301 "Wed Aug 21 11:59:58 2026 /Applications/Reolink.app/Contents/MacOS/Reolink"
run_watchdog
assert_file_equals $'TERM 301\nsleep 10' "$ACTION_LOG" "avoid KILL after PID launch time changes"

reset_case byte_exact_launch_time
print -r -- "351 01:00:01 Thu Aug  7 08:59:58 2026 /System/Library/CoreServices/ReportCrash" > "$PROCESS_FILE"
set_identity 351 "Thu Aug 7 08:59:58 2026 /System/Library/CoreServices/ReportCrash"
run_watchdog
assert_file_equals "" "$ACTION_LOG" "require byte-exact launch time before TERM"

reset_case malformed_target
print -r -- "401 invalid Wed Aug 21 08:59:58 2026 /Applications/Reolink.app/Contents/MacOS/Reolink" > "$PROCESS_FILE"
run_watchdog
assert_file_equals "" "$ACTION_LOG" "fail closed for malformed target record"
assert_contains "executable=/Applications/Reolink.app/Contents/MacOS/Reolink pid=401 elapsed=invalid signal=none outcome=malformed" \
    "$MESSAGE_LOG" "describe malformed target without signalling it"

print -r -- "stale process watchdog tests passed"
