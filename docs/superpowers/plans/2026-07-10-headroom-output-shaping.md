# Headroom Output Shaping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Upgrade the active persistent Headroom deployment to 0.31.0 and enable learned output shaping with a 10% unshaped measurement holdout.

**Architecture:** Keep the existing `default` launchd deployment and its routing/memory policy. Upgrade only the global `uv` tool, learn verbosity from all Claude transcripts, persist the two output-shaping variables in both the deployment manifest and generated launcher, then perform one managed restart with a complete rollback snapshot available.

**Tech Stack:** Headroom CLI 0.31.0, `uv` tools, launchd, Bash, JSON, `jq`, `curl`

---

### Task 1: Capture Baseline and Rollback State

**Files:**
- Read: `$HOME/.headroom/deploy/default/manifest.json`
- Read: `$HOME/.headroom/deploy/default/run-headroom.sh`
- Create: `$HOME/.headroom/backups/2026-07-10-output-shaping/manifest.json`
- Create: `$HOME/.headroom/backups/2026-07-10-output-shaping/run-headroom.sh`
- Create: `$HOME/.headroom/backups/2026-07-10-output-shaping/version.txt`
- Create: `$HOME/.headroom/backups/2026-07-10-output-shaping/perf-72h.json`
- Create: `$HOME/.headroom/backups/2026-07-10-output-shaping/doctor-before.json`

- [ ] **Step 1: Verify the expected pre-change version and deployment**

Run:

```sh
headroom --version
headroom install status --profile default
launchctl print "gui/$(id -u)/com.headroom.default" | rg 'state =|pid =|program ='
```

Expected: Headroom reports `0.30.0`; the `default` deployment reports healthy; launchd reports `state = running` and a PID.

- [ ] **Step 2: Create the rollback directory and copy the durable configuration**

Run:

```sh
backup_dir=$HOME/.headroom/backups/2026-07-10-output-shaping
test ! -e "$backup_dir"
mkdir -p "$backup_dir"
cp -p $HOME/.headroom/deploy/default/manifest.json "$backup_dir/manifest.json"
cp -p $HOME/.headroom/deploy/default/run-headroom.sh "$backup_dir/run-headroom.sh"
if [ -f $HOME/.headroom/verbosity.json ]; then cp -p $HOME/.headroom/verbosity.json "$backup_dir/verbosity.json"; fi
if [ -f $HOME/.headroom/output_savings.json ]; then cp -p $HOME/.headroom/output_savings.json "$backup_dir/output_savings.json"; fi
```

Expected: the directory is created once and contains byte-for-byte copies of the manifest and launcher; existing shaping data is copied when present.

- [ ] **Step 3: Record the performance and health baseline**

Run:

```sh
backup_dir=$HOME/.headroom/backups/2026-07-10-output-shaping
headroom --version > "$backup_dir/version.txt"
headroom perf --hours 72 --format json > "$backup_dir/perf-72h.json"
headroom doctor --json > "$backup_dir/doctor-before.json"
jq '{savings_pct,tokens_saved,cache_hit_pct,by_model}' "$backup_dir/perf-72h.json"
```

Expected: valid JSON is saved; the current 72-hour report remains available for later comparison.

### Task 2: Upgrade Only Headroom

**Files:**
- Modify: `$HOME/workspace/.uv/tools/headroom-ai/` through `uv tool upgrade`

- [ ] **Step 1: Upgrade Headroom to the approved version**

Run:

```sh
uv tool upgrade 'headroom-ai==0.31.0'
```

Expected: `uv` reports `headroom-ai` upgraded from 0.30.0 to 0.31.0 without upgrading unrelated tools.

- [ ] **Step 2: Verify the new CLI before touching the running deployment**

Run:

```sh
test "$(headroom --version)" = 'headroom, version 0.31.0'
headroom proxy --help | rg 'output|read-maturation'
headroom learn --help | rg -- '--verbosity'
headroom output-savings --help >/dev/null
```

Expected: all commands exit 0 and the output-shaping CLI surfaces are present.

- [ ] **Step 3: Roll back immediately if the CLI verification fails**

Run only if Step 2 fails:

```sh
uv tool install --force 'headroom-ai[all]==0.30.0'
test "$(headroom --version)" = 'headroom, version 0.30.0'
```

Expected: the CLI returns to 0.30.0; stop execution and report the upgrade failure without restarting the service.

### Task 3: Learn and Seed the Output-Shaping Baseline

**Files:**
- Create or modify: `$HOME/.headroom/verbosity.json`
- Create or modify: `$HOME/.headroom/output_savings.json`

- [ ] **Step 1: Preview learned verbosity across all Claude projects**

Run:

```sh
headroom learn --verbosity --all
```

Expected: at least one project is analyzed and a recommended verbosity level is printed; the command ends with the dry-run notice.

- [ ] **Step 2: Persist the learned level and baseline**

Run:

```sh
headroom learn --verbosity --apply --all
```

Expected: the command writes `$HOME/.headroom/verbosity.json` and `$HOME/.headroom/output_savings.json`, reports a non-zero baseline sample count, and hot-enables the output shaper on port 8787.

- [ ] **Step 3: Verify the persisted learning artifacts**

Run:

```sh
jq -e '.level >= 0 and .level <= 4 and (.source | length > 0)' $HOME/.headroom/verbosity.json
jq -e '.baseline.total_samples > 0' $HOME/.headroom/output_savings.json
headroom output-savings
```

Expected: both `jq` checks exit 0 and `headroom output-savings` reports the seeded baseline. A measured reduction is not required before shaped and holdout traffic accumulates.

### Task 4: Persist the Shaper and Holdout

**Files:**
- Modify: `$HOME/.headroom/deploy/default/manifest.json`
- Modify: `$HOME/.headroom/deploy/default/run-headroom.sh`

- [ ] **Step 1: Prove the durable settings are absent before editing**

Run:

```sh
! jq -e '.base_env.HEADROOM_OUTPUT_SHAPER == "1" and .base_env.HEADROOM_OUTPUT_HOLDOUT == "0.1"' $HOME/.headroom/deploy/default/manifest.json
! rg -q '^export HEADROOM_OUTPUT_SHAPER=1$|^export HEADROOM_OUTPUT_HOLDOUT=0\.1$' $HOME/.headroom/deploy/default/run-headroom.sh
```

Expected: both negated checks exit 0, proving the persistent service is not configured yet.

- [ ] **Step 2: Add the settings to the deployment manifest**

Apply this patch with `apply_patch`:

```diff
*** Begin Patch
*** Update File: $HOME/.headroom/deploy/default/manifest.json
@@
-    "HEADROOM_RETRY_MAX_ATTEMPTS": "1"
+    "HEADROOM_RETRY_MAX_ATTEMPTS": "1",
+    "HEADROOM_OUTPUT_SHAPER": "1",
+    "HEADROOM_OUTPUT_HOLDOUT": "0.1"
*** End Patch
```

Expected: only the two approved `base_env` keys are added.

- [ ] **Step 3: Add the settings to the generated launcher**

Apply this patch with `apply_patch`:

```diff
*** Begin Patch
*** Update File: $HOME/.headroom/deploy/default/run-headroom.sh
@@
 export HEADROOM_RETRY_MAX_ATTEMPTS=1
+# Shape model output using the learned verbosity profile. Keep 10% of
+# conversations unshaped so output savings can be measured directly.
+export HEADROOM_OUTPUT_SHAPER=1
+export HEADROOM_OUTPUT_HOLDOUT=0.1
 exec $HOME/.local/bin/headroom install agent run --profile default
*** End Patch
```

Expected: the launcher exports both settings immediately before starting the deployment agent.

- [ ] **Step 4: Validate the configuration without restarting**

Run:

```sh
jq empty $HOME/.headroom/deploy/default/manifest.json
bash -n $HOME/.headroom/deploy/default/run-headroom.sh
jq -e '.base_env.HEADROOM_OUTPUT_SHAPER == "1" and .base_env.HEADROOM_OUTPUT_HOLDOUT == "0.1"' $HOME/.headroom/deploy/default/manifest.json
rg -n '^export HEADROOM_OUTPUT_(SHAPER|HOLDOUT)=' $HOME/.headroom/deploy/default/run-headroom.sh
```

Expected: every command exits 0; JSON and shell syntax are valid.

- [ ] **Step 5: Confirm no existing deployment policy changed**

Run:

```sh
backup_dir=$HOME/.headroom/backups/2026-07-10-output-shaping
jq -S '.base_env | del(.HEADROOM_OUTPUT_SHAPER, .HEADROOM_OUTPUT_HOLDOUT)' "$backup_dir/manifest.json" > /tmp/headroom-base-env-before.json
jq -S '.base_env | del(.HEADROOM_OUTPUT_SHAPER, .HEADROOM_OUTPUT_HOLDOUT)' $HOME/.headroom/deploy/default/manifest.json > /tmp/headroom-base-env-after.json
diff -u /tmp/headroom-base-env-before.json /tmp/headroom-base-env-after.json
```

Expected: `diff` exits 0 with no output.

### Task 5: Restart Once and Verify the Live Runtime

**Files:**
- Read: `$HOME/.headroom/deploy/default/manifest.json`
- Read: `$HOME/.headroom/verbosity.json`
- Read: `$HOME/.headroom/output_savings.json`

- [ ] **Step 1: Restart through the managed lifecycle**

Run:

```sh
headroom install restart --profile default
```

Expected: the command reports `Restarted deployment 'default'.` without a launchd bootstrap error.

- [ ] **Step 2: Verify launchd and proxy readiness**

Run:

```sh
launchctl print "gui/$(id -u)/com.headroom.default" | rg 'state =|pid =|program ='
curl --fail --silent --show-error http://127.0.0.1:8787/readyz
headroom install status --profile default
```

Expected: launchd reports running with a PID, `/readyz` succeeds, and Headroom reports the deployment healthy.

- [ ] **Step 3: Verify routing and runtime settings**

Run:

```sh
headroom doctor --json | tee /tmp/headroom-doctor-after.json | jq .
curl --fail --silent http://127.0.0.1:8787/health | jq -e '.runtime_env.HEADROOM_OUTPUT_SHAPER == "1" and .runtime_env.HEADROOM_OUTPUT_HOLDOUT == "0.1"'
```

Expected: doctor reports passing proxy, Claude, Codex, shell/config, and deployment checks; the live runtime exposes both approved values.

- [ ] **Step 4: Verify preserved memory and performance interfaces**

Run:

```sh
headroom memory stats --db-path $HOME/.headroom/memory.db
headroom output-savings
headroom perf --hours 72
```

Expected: the existing memory database is readable, output savings shows its learned baseline, and the 72-hour performance report remains readable.

- [ ] **Step 5: Roll back if any post-restart health or routing check fails**

Run only if Steps 2-4 fail:

```sh
backup_dir=$HOME/.headroom/backups/2026-07-10-output-shaping
cp -p "$backup_dir/manifest.json" $HOME/.headroom/deploy/default/manifest.json
cp -p "$backup_dir/run-headroom.sh" $HOME/.headroom/deploy/default/run-headroom.sh
uv tool install --force 'headroom-ai[all]==0.30.0'
headroom install restart --profile default
headroom --version
headroom doctor --json
```

Expected: Headroom reports 0.30.0 and the pre-change deployment returns healthy. Preserve the failed 0.31.0 diagnostics and report the exact failing check.
