#!/usr/bin/env bash
set -euo pipefail

# The claude() wrapper in _zshrc names the task list after the repository
# so every session started in the same checkout (or a linked worktree of
# it) reads and writes one list under ~/.claude/tasks/repo-<name>/.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

mkdir -p "$TMPDIR/bin"
cat > "$TMPDIR/bin/claude" <<'FAKE'
#!/bin/sh
printf 'TASK_LIST_ID=%s\n' "${CLAUDE_CODE_TASK_LIST_ID-<unset>}"
printf 'ARGS=%s\n' "$*"
FAKE
chmod +x "$TMPDIR/bin/claude"

# Extract only the function so the test does not depend on the rest of _zshrc.
sed -n '/^claude() {/,/^}/p' "$ROOT/_zshrc" > "$TMPDIR/claude.zsh"

git_quiet() {
    git -c user.name=test -c user.email=test@example.invalid -c init.defaultBranch=master -c commit.gpgsign=false "$@"
}

make_repo() {
    local dir="$1"
    mkdir -p "$dir"
    git_quiet -C "$dir" init -q
    git_quiet -C "$dir" commit -q --allow-empty -m init
}

make_repo "$TMPDIR/alpha"
mkdir -p "$TMPDIR/alpha/src"
git_quiet -C "$TMPDIR/alpha" worktree add -q "$TMPDIR/alpha-wt" -b wt
make_repo "$TMPDIR/my project"
mkdir -p "$TMPDIR/plain"

failures=0

# run_case <name> <dir> <expected-line> [VAR=value ...]
run_case() {
    local name="$1" dir="$2" expected="$3"
    shift 3
    local output
    output="$(cd "$dir" && env "$@" PATH="$TMPDIR/bin:$PATH" zsh -f -c "source '$TMPDIR/claude.zsh'; claude --version" 2>&1 || true)"
    if grep -qxF -- "$expected" <<< "$output"; then
        echo "ok $name"
    else
        echo "FAIL $name: expected '$expected', got:"
        sed 's/^/    /' <<< "$output"
        failures=$((failures + 1))
    fi
}

run_case "repo root names the list"        "$TMPDIR/alpha"      "TASK_LIST_ID=repo-alpha"
run_case "flag is kept and args pass through" "$TMPDIR/alpha"   "ARGS=--allow-dangerously-skip-permissions --version"
run_case "subdirectory resolves to the root" "$TMPDIR/alpha/src" "TASK_LIST_ID=repo-alpha"
run_case "linked worktree shares the list"  "$TMPDIR/alpha-wt"   "TASK_LIST_ID=repo-alpha"
run_case "space in the repo name"           "$TMPDIR/my project" "TASK_LIST_ID=repo-my project"
run_case "outside git stays unset"          "$TMPDIR/plain"      "TASK_LIST_ID=<unset>"
run_case "exported value wins"              "$TMPDIR/alpha"      "TASK_LIST_ID=custom"  CLAUDE_CODE_TASK_LIST_ID=custom
run_case "session sentinel unsets"          "$TMPDIR/alpha"      "TASK_LIST_ID=<unset>" CLAUDE_CODE_TASK_LIST_ID=session

if [ "$failures" -ne 0 ]; then
    echo "$failures case(s) failed"
    exit 1
fi
echo "all cases passed"
