#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCAN_BIN="$ROOT/bin/git-scan"

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

# Fixtures are assembled at runtime so this file never contains a literal
# token or machine path that would trip the hooks scanning this repo itself.
FAKE_TOKEN="ghp_""9f4Kq2Lm8Zx3Vb7Nc1Rt5Wy0Pd6Sg4Hj2Ek8"
BAD_PATH="$(printf '/%s/%s/secret' Users nobody)"

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'expected output to contain %q, got: %s\n' "$needle" "$haystack" >&2
    exit 1
  fi
}

# expect_status <expected-exit> <description> <cmd...>
expect_status() {
  local expected="$1" desc="$2" status=0
  shift 2
  "$@" > "$TMPDIR/last.out" 2>&1 || status=$?
  if [ "$status" -ne "$expected" ]; then
    printf 'FAIL %s: expected exit %s, got %s\noutput:\n' "$desc" "$expected" "$status" >&2
    cat "$TMPDIR/last.out" >&2
    exit 1
  fi
  printf 'ok: %s\n' "$desc"
}

make_repo() {
  local dir="$1"
  git init -q "$dir"
  git -C "$dir" config user.email test@example.com
  git -C "$dir" config user.name test
  git -C "$dir" commit -q --allow-empty -m init
}

expect_status 2 "no arguments is a usage error" "$SCAN_BIN"
expect_status 2 "unknown subcommand is a usage error" "$SCAN_BIN" bogus

expect_status 1 "names blocks .env" "$SCAN_BIN" names .env
expect_status 1 "names blocks nested pem" "$SCAN_BIN" names conf/tls/server.pem
expect_status 1 "names blocks id_rsa" "$SCAN_BIN" names .ssh/id_rsa
expect_status 0 "names allows normal files" "$SCAN_BIN" names _zshrc bin/tmx README.rst
expect_status 0 "names with no files is clean" "$SCAN_BIN" names
assert_contains "$("$SCAN_BIN" names .env 2>&1 || true)" "blocked sensitive filename"
assert_contains "$("$SCAN_BIN" names .env 2>&1 || true)" "LEFTHOOK=0"

make_repo "$TMPDIR/paths-repo"
printf 'export CACHE="%s"\n' "$BAD_PATH" > "$TMPDIR/paths-repo/rc"
git -C "$TMPDIR/paths-repo" add rc
( cd "$TMPDIR/paths-repo" && expect_status 1 "paths blocks staged machine path" "$SCAN_BIN" paths --staged )
( cd "$TMPDIR/paths-repo" && assert_contains "$("$SCAN_BIN" paths --staged 2>&1 || true)" "rc:1" )
printf 'export CACHE="%s" # path-ok\n' "$BAD_PATH" > "$TMPDIR/paths-repo/rc"
git -C "$TMPDIR/paths-repo" add rc
( cd "$TMPDIR/paths-repo" && expect_status 0 "path-ok marker allows the line" "$SCAN_BIN" paths --staged )
printf 'export CACHE="$HOME/cache"\n' > "$TMPDIR/paths-repo/rc"
git -C "$TMPDIR/paths-repo" add rc
( cd "$TMPDIR/paths-repo" && expect_status 0 "HOME-based path is clean" "$SCAN_BIN" paths --staged )

expect_status 2 "paths without a mode is a usage error" "$SCAN_BIN" paths

RESTRICTED_PATH="/usr/bin:/bin"
make_repo "$TMPDIR/secrets-repo"
printf 'token = "%s"\n' "$FAKE_TOKEN" > "$TMPDIR/secrets-repo/conf"
git -C "$TMPDIR/secrets-repo" add conf
( cd "$TMPDIR/secrets-repo" && expect_status 1 "fallback blocks staged token" \
    env PATH="$RESTRICTED_PATH" "$SCAN_BIN" secrets --staged )
( cd "$TMPDIR/secrets-repo" && assert_contains \
    "$(env PATH="$RESTRICTED_PATH" "$SCAN_BIN" secrets --staged 2>&1 || true)" \
    "WARNING: gitleaks not installed" )
printf 'greeting = "hello world, nothing secret"\n' > "$TMPDIR/secrets-repo/conf"
git -C "$TMPDIR/secrets-repo" add conf
( cd "$TMPDIR/secrets-repo" && expect_status 0 "fallback passes clean staged content" \
    env PATH="$RESTRICTED_PATH" "$SCAN_BIN" secrets --staged )

expect_status 2 "secrets without a mode is a usage error" env PATH="$RESTRICTED_PATH" "$SCAN_BIN" secrets

if command -v gitleaks > /dev/null 2>&1; then
  printf 'token = "%s"\n' "$FAKE_TOKEN" > "$TMPDIR/secrets-repo/conf"
  git -C "$TMPDIR/secrets-repo" add conf
  ( cd "$TMPDIR/secrets-repo" && expect_status 1 "gitleaks blocks staged token" \
      "$SCAN_BIN" secrets --staged )
  git -C "$TMPDIR/secrets-repo" rm -q --cached conf
else
  printf 'skip: gitleaks not installed\n'
fi

printf 'token = "%s" # gitleaks:allow\n' "$FAKE_TOKEN" > "$TMPDIR/secrets-repo/conf"
git -C "$TMPDIR/secrets-repo" add conf
( cd "$TMPDIR/secrets-repo" && expect_status 0 "builtin honors gitleaks:allow marker" \
    env PATH="$RESTRICTED_PATH" "$SCAN_BIN" secrets --staged )
git -C "$TMPDIR/secrets-repo" rm -q --cached conf

make_repo "$TMPDIR/range-repo"
printf 'token = "%s"\n' "$FAKE_TOKEN" > "$TMPDIR/range-repo/creds.txt"
git -C "$TMPDIR/range-repo" add creds.txt
git -C "$TMPDIR/range-repo" commit -q --no-verify -m "sneaky"
( cd "$TMPDIR/range-repo" && expect_status 1 "range scan catches committed secret" \
    "$SCAN_BIN" secrets --range )
printf 'cache = "%s"\n' "$BAD_PATH" > "$TMPDIR/range-repo/paths.txt"
git -C "$TMPDIR/range-repo" add paths.txt
git -C "$TMPDIR/range-repo" commit -q --no-verify -m "sneaky path"
( cd "$TMPDIR/range-repo" && expect_status 1 "range scan catches committed machine path" \
    "$SCAN_BIN" paths --range )
make_repo "$TMPDIR/range-clean"
printf 'nothing here\n' > "$TMPDIR/range-clean/note"
git -C "$TMPDIR/range-clean" add note
git -C "$TMPDIR/range-clean" commit -q -m "clean"
( cd "$TMPDIR/range-clean" && expect_status 0 "range scan passes clean history" \
    "$SCAN_BIN" secrets --range )

printf '#!/usr/bin/env zsh\nif true; then\n' > "$TMPDIR/broken.zsh"
printf '#!/usr/bin/env zsh\nprint ok\n' > "$TMPDIR/fine-shebang"
printf '#!/bin/sh\nif [ 1 ]; then echo y; fi\n' > "$TMPDIR/fine.sh"
printf 'just text, not a script\n' > "$TMPDIR/notes.txt"
expect_status 1 "syntax blocks broken zsh" "$SCAN_BIN" syntax "$TMPDIR/broken.zsh"
expect_status 0 "syntax passes zsh shebang file" "$SCAN_BIN" syntax "$TMPDIR/fine-shebang"
expect_status 0 "syntax passes valid sh" "$SCAN_BIN" syntax "$TMPDIR/fine.sh"
expect_status 0 "syntax skips non-shell files" "$SCAN_BIN" syntax "$TMPDIR/notes.txt"
expect_status 0 "syntax with no files is clean" "$SCAN_BIN" syntax

if command -v lefthook > /dev/null 2>&1; then
  make_repo "$TMPDIR/hook-repo"
  mkdir -p "$TMPDIR/hook-repo/bin"
  cp "$SCAN_BIN" "$TMPDIR/hook-repo/bin/git-scan"
  cp "$ROOT/lefthook.yml" "$ROOT/.gitleaks.toml" "$TMPDIR/hook-repo/"
  ( cd "$TMPDIR/hook-repo" && lefthook install > /dev/null )
  printf 'token = "%s"\n' "$FAKE_TOKEN" > "$TMPDIR/hook-repo/leak.txt"
  git -C "$TMPDIR/hook-repo" add leak.txt
  ( cd "$TMPDIR/hook-repo" && expect_status 1 "pre-commit hook blocks a staged token" \
      git commit -m leak )
  git -C "$TMPDIR/hook-repo" rm -q --cached leak.txt
  printf 'all fine\n' > "$TMPDIR/hook-repo/fine.txt"
  git -C "$TMPDIR/hook-repo" add fine.txt
  ( cd "$TMPDIR/hook-repo" && expect_status 0 "pre-commit hook passes a clean commit" \
      git commit -q -m fine )
else
  printf 'skip: lefthook not installed\n'
fi

expect_status 0 "names allows public keys" "$SCAN_BIN" names id_rsa.pub .ssh/id_ed25519.pub

printf 'git-scan tests passed\n'
