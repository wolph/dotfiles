# Stale Process Watchdog Implementation Plan

**For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task.

**Goal:** Install a root cron watchdog that terminates stale ReportCrash and Reolink processes without touching unrelated or reused PIDs.

**Architecture:** A zsh executable reads a single macOS `ps` snapshot, validates each record, selects exact executable paths older than one hour, and records PID identity. It sends all selected processes `TERM`, sleeps once, then checks executable path and launch time before any `KILL`. A fixture-based zsh test replaces `ps`, `kill`, `sleep`, and `date` through configurable absolute command variables and directs logs to a temporary file.

**Tech Stack:** zsh, macOS `ps`, `kill`, `sleep`, `date`, root cron, shell fixture tests

---

### Task 1: Add the watchdog test harness and implementation

**Files:**

- Create: `tests/stale-process-watchdog-test.zsh`
- Create: `bin/stale-process-watchdog`

- [ ] **Step 1: Write the failing fixture test**

Create `tests/stale-process-watchdog-test.zsh` with a temporary fixture directory and fake executables. The fake `ps` must return a configurable initial snapshot for `-axo pid=,etime=,lstart=,comm=` and configurable per-PID identity for `-p PID -o lstart=,comm=`. The fake `kill` appends `SIGNAL PID` to a log. The fake `sleep` appends `sleep 10` to the same log and removes PIDs listed by the test as graceful exits. The watchdog appends messages to a separate fixture log.

Invoke the watchdog with these overrides:

```zsh
env \
  WATCHDOG_PS="$fixture_bin/ps" \
  WATCHDOG_KILL="$fixture_bin/kill" \
  WATCHDOG_SLEEP="$fixture_bin/sleep" \
  WATCHDOG_DATE="$fixture_bin/date" \
  WATCHDOG_LOG_FILE="$message_log" \
  FIXTURE_PROCESS_FILE="$process_file" \
  FIXTURE_IDENTITY_DIR="$identity_dir" \
  FIXTURE_ACTION_LOG="$action_log" \
  FIXTURE_GRACEFUL_PIDS="${graceful_pids:-}" \
  /bin/zsh "$WATCHDOG_BIN"
```

Define independent cases that reset the fixtures before each run and assert exact action ordering. Cover these records:

```text
101 59:59 Wed Aug 21 09:00:00 2026 /System/Library/CoreServices/ReportCrash
102 01:00:00 Wed Aug 21 08:59:59 2026 /System/Library/CoreServices/ReportCrash
103 01:00:01 Wed Aug 21 08:59:58 2026 /System/Library/CoreServices/ReportCrash
104 02:00:01 Wed Aug 21 07:59:58 2026 /Applications/Reolink.app/Contents/MacOS/Reolink
105 1-00:00:01 Tue Aug 20 09:59:58 2026 /Applications/Reolink.app/Contents/Frameworks/Reolink Helper.app/Contents/MacOS/Reolink Helper
106 999:99 Wed Aug 21 09:00:00 2026 /System/Library/CoreServices/ReportCrash
107 02:00:01 Wed Aug 21 07:59:58 2026 /tmp/ReportCrash
108 02:00:01 Wed Aug 21 07:59:58 2026 /Applications/Reolink Backup.app/Contents/MacOS/Reolink
```

Expected first-pass actions are:

```text
TERM 103
TERM 104
TERM 105
sleep 10
KILL 103
KILL 104
KILL 105
```

Add separate cases proving a PID listed in `FIXTURE_GRACEFUL_PIDS` is not killed and a PID whose identity changes after `TERM` is not killed. Cover exact elapsed widths and ranges, byte-exact launch identity, malformed or missing launch fields, exact action-log order, and exact message-log records. Assert preserved young, boundary, unrelated, and identity-mismatched processes do not create log records. Run the test against a temporary watchdog copy with termination logging removed and require the expected log assertion to fail.

- [ ] **Step 2: Run the focused test and verify RED**

Run:

```bash
/bin/zsh tests/stale-process-watchdog-test.zsh
```

Expected: nonzero exit because `bin/stale-process-watchdog` does not exist.

- [ ] **Step 3: Implement the watchdog**

Create executable `bin/stale-process-watchdog` with `#!/bin/zsh`, `set -u`, and typed zsh variables. Default command variables to absolute system paths while allowing fixture overrides:

```zsh
typeset -r PS_COMMAND="${WATCHDOG_PS:-/bin/ps}"
typeset -r KILL_COMMAND="${WATCHDOG_KILL:-/bin/kill}"
typeset -r SLEEP_COMMAND="${WATCHDOG_SLEEP:-/bin/sleep}"
typeset -r DATE_COMMAND="${WATCHDOG_DATE:-/bin/date}"
typeset -r LOG_FILE="${WATCHDOG_LOG_FILE:-/var/log/stale-process-watchdog.log}"
typeset -ri MAX_AGE_SECONDS=3600
typeset -ri TERM_GRACE_SECONDS=10
typeset -r SNAPSHOT_RECORD_PATTERN='^[[:space:]]*([^[:space:]]+)[[:space:]]+([^[:space:]]+)[[:space:]]+(.{24})[[:space:]]+(.*)$'
typeset -r IDENTITY_RECORD_PATTERN='^[[:space:]]*(.{24})[[:space:]]+(.*)$'
typeset -r LAUNCH_TIME_PATTERN='^(Sun|Mon|Tue|Wed|Thu|Fri|Sat) (Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec) ( [1-9]|[12][0-9]|3[01]) ([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9] [0-9]{4}$'
typeset -r TARGET_AT_END_PATTERN='[[:space:]](/System/Library/CoreServices/ReportCrash|/Applications/Reolink[.]app/.*)$'
```

Implement these functions with the exact interfaces below:

```zsh
elapsed_seconds() {
  typeset -r elapsed="$1"
  typeset -i days=0 hours=0 minutes=0 seconds=0

  if [[ "$elapsed" == <->:[0-9][0-9] ]]; then
    minutes=${elapsed%%:*}
    seconds=${elapsed##*:}
    (( seconds <= 59 )) || return 1
  elif [[ "$elapsed" == [0-9][0-9]:[0-9][0-9]:[0-9][0-9] ]]; then
    hours=${elapsed%%:*}
    typeset -r remainder="${elapsed#*:}"
    minutes=${remainder%%:*}
    seconds=${remainder##*:}
    (( hours <= 23 && minutes <= 59 && seconds <= 59 )) || return 1
  elif [[ "$elapsed" == <->-[0-9][0-9]:[0-9][0-9]:[0-9][0-9] ]]; then
    days=${elapsed%%-*}
    typeset -r clock="${elapsed#*-}"
    hours=${clock%%:*}
    typeset -r remainder="${clock#*:}"
    minutes=${remainder%%:*}
    seconds=${remainder##*:}
    (( hours <= 23 && minutes <= 59 && seconds <= 59 )) || return 1
  else
    return 1
  fi

  print -r -- $((days * 86400 + hours * 3600 + minutes * 60 + seconds))
}

is_target_executable() {
  typeset -r executable="$1"
  [[ "$executable" == /System/Library/CoreServices/ReportCrash ||
     "$executable" == /Applications/Reolink.app/* ]]
}

valid_launch_time() {
    typeset -r launch_time="$1"
    [[ "$launch_time" =~ ${LAUNCH_TIME_PATTERN} ]]
}

recognizable_target() {
    typeset -r record="$1"
    [[ "$record" =~ ${TARGET_AT_END_PATTERN} ]] || return 1
    print -r -- "$match[1]"
}

log_record() {
    typeset -r executable="$1"
    typeset -r pid="$2"
    typeset -r elapsed="$3"
    typeset -r signal_name="$4"
    typeset -r outcome="$5"
    typeset -r timestamp="$("$DATE_COMMAND" '+%Y-%m-%dT%H:%M:%S%z')"
    print -r -- "$timestamp executable=$executable pid=$pid elapsed=$elapsed signal=$signal_name outcome=$outcome" >> "$LOG_FILE"
}
```

Read the initial snapshot with:

```zsh
"$PS_COMMAND" -axo pid=,etime=,lstart=,comm=
```

Parse PID, elapsed time, the exact 24-byte macOS launch time, and the remaining executable path. Validate launch time weekday, month, day width, clock widths and ranges, and year width before selection. Reject nonnumeric PIDs, missing fields, malformed elapsed times, and target records without valid launch identity. Recognize a target executable at the end of malformed records so it can be logged without signalling. Only select targets where age is strictly greater than 3600. Store each selected PID, executable path, launch time, and elapsed value in associative arrays.

Before `TERM`, read identity with:

```zsh
"$PS_COMMAND" -p "$pid" -o lstart=,comm=
```

Require the returned launch time and executable path to match the snapshot byte-for-byte. Send `"$KILL_COMMAND" -TERM -- "$pid"` for every matching candidate and record only successful signals for the final pass. If at least one `TERM` succeeds, call `"$SLEEP_COMMAND" "$TERM_GRACE_SECONDS"` exactly once. Re-read each successful PID and send `"$KILL_COMMAND" -KILL -- "$pid"` only when both identity fields still match. Log each signal outcome and each malformed target record with timestamp, PID, elapsed value, executable path, signal, and result. Do not evaluate process output.

- [ ] **Step 4: Run the focused test and verify GREEN**

Run:

```bash
/bin/zsh tests/stale-process-watchdog-test.zsh
/bin/zsh -n bin/stale-process-watchdog tests/stale-process-watchdog-test.zsh
```

Expected: both commands exit zero and the test prints `stale process watchdog tests passed`.

- [ ] **Step 5: Run the full repository suite**

Run:

```bash
for test_file in tests/*; do
  case "$test_file" in
    *.zsh) /bin/zsh "$test_file" ;;
    *.sh) /bin/bash "$test_file" ;;
  esac
done
```

Expected: every test exits zero.

- [ ] **Step 6: Commit the implementation**

```bash
git add bin/stale-process-watchdog tests/stale-process-watchdog-test.zsh docs/superpowers/plans/2026-08-21-stale-process-watchdog.md
git commit -m "feat: add stale process watchdog"
```

### Task 2: Install and schedule the watchdog

**Files:**

- Install: `/usr/local/sbin/stale-process-watchdog`
- Create if absent: `/var/log/stale-process-watchdog.log`
- Modify through `crontab`: root crontab

- [ ] **Step 1: Capture and validate current state**

Run read-only checks and save the exact user and root crontabs in temporary files created with `mktemp -d`:

```bash
crontab -l
sudo -n crontab -l
sudo -n launchctl print system/com.vix.cron
```

Require the user entry `0 3 * * * /Users/rick/bin/update_tools.sh` and root entry `0 6 * * * /Users/rick/bin/daily-process-cleanup.sh` before changing root cron. # path-ok

- [ ] **Step 2: Install the root-owned files**

```bash
sudo -n /usr/bin/install -o root -g wheel -m 0755 bin/stale-process-watchdog /usr/local/sbin/stale-process-watchdog
sudo -n /usr/bin/touch /var/log/stale-process-watchdog.log
sudo -n /usr/sbin/chown root:wheel /var/log/stale-process-watchdog.log
sudo -n /bin/chmod 0640 /var/log/stale-process-watchdog.log
```

- [ ] **Step 3: Add the cron line without duplicates**

Build a temporary root crontab from the captured root crontab. Remove any exact existing watchdog line, append exactly one line, then install it:

```cron
*/5 * * * * /usr/local/sbin/stale-process-watchdog
```

Do not change any other root crontab line. Compare the old and proposed files before calling `sudo -n crontab proposed-root-crontab`.

- [ ] **Step 4: Run the installed watchdog once**

```bash
sudo -n /usr/local/sbin/stale-process-watchdog
```

Expected: exit zero. Any matching process older than one hour receives `TERM`, then receives `KILL` only if it remains with the same identity after ten seconds.

- [ ] **Step 5: Verify the live installation**

Run:

```bash
/usr/bin/stat -f '%Su:%Sg %Sp %N' /usr/local/sbin/stale-process-watchdog /var/log/stale-process-watchdog.log
crontab -l
sudo -n crontab -l
sudo -n launchctl print system/com.vix.cron
sudo -n /bin/ps -axo pid=,etime=,lstart=,comm=
sudo -n /usr/bin/tail -n 50 /var/log/stale-process-watchdog.log
```

Require `root:wheel -rwxr-xr-x` for the executable, `root:wheel -rw-r-----` for the log, both original cron entries unchanged, the watchdog line exactly once, cron active, and no stale target left with unchanged identity after the manual run.

- [ ] **Step 6: Re-run source verification**

```bash
/bin/zsh tests/stale-process-watchdog-test.zsh
/bin/zsh -n bin/stale-process-watchdog tests/stale-process-watchdog-test.zsh
git status --short
```

Expected: tests and syntax checks exit zero. The worktree has no uncommitted changes.
