## Task Management

- Multi-step work gets a task per step with TaskCreate before the first edit.
  Dependencies go in with addBlockedBy. Status moves to in_progress before a
  step starts and to completed only after verification.
  Why: the list is shared per repository (CLAUDE_CODE_TASK_LIST_ID is set by
  the claude shell function, launches from herdr, ccmux or an IDE get a
  per-session list), so the next session in this repo starts from it, and
  Ctrl+T shows it to the user while work runs.
- A task is completed only when its description carries a line
  `Verified: <check> -> <result>` or `Unverified: <reason>`. A TaskCompleted
  hook rejects anything else. Write the line with TaskUpdate first.
  Why: the verification rule above was prose. The hook makes it a gate.
- At session start in a repo with open tasks, run /open before anything else
  and continue from the in_progress task unless the user says otherwise.

## Background Agents (Claude Code)

- A hook injects `Running agents: ...` on every user turn while Agent-tool
  subagents run. An agent absent from that line has
  not started. One marked `over 10 min` is stopped and its work taken over,
  as the global rule says. Teammates in tmux panes are not on the line.

## Long-running and recurring work

- Monitor watches a process or file and reports each line. Use it for test
  runs, builds and agent progress files instead of polling with sleep.
- /loop (self-paced) or CronCreate (fixed interval, this session only) for
  checks that repeat: CI status, a deploy, a remote queue. Never a sleep loop
  in Bash.
- Workflow only when the user asks for one by name or says "ultracode".
- EnterWorktree for feature work that must not touch the current checkout.
  settings.json sets worktree.baseRef to fresh, so a worktree starts from
  the remote default branch.
  Why: these tools exist in Claude Code 2.1.312 and were unused because
  nothing named them.

## Resource lifetime

- Use ordinary subagents for delegated tasks. Persistent agent teams require
  an explicit need for continued inter-agent coordination. Defaults disable
  experimental teams and use in-process teammates when a team is enabled.
- Release a teammate when its assigned work is complete. The TeammateIdle hook
  requests termination. Verify completion and process exit before treating
  that as successful cleanup. Spawn a fresh worker for later independent work.
- The independent Claude guard supervises each session including its helpers
  at 8 GiB, after two consecutive healthy over-limit samples. Only the user's
  explicit permission allows a session override in
  ~/.config/agent-resource-guard/config.json. This is sampled supervision,
  not a kernel allocation limit. Do not raise a limit to keep your work running.
- Audit RAM disks belong to the whole run, not an individual sandbox command.
  Register the real long-lived coordinator PID at run creation using
  python3 ~/workspace/ai/scripts/resource_guard/audit_guard.py --register-run
  <run-directory> --owner-pid <coordinator-pid>. Verify registration succeeds.
  A one-shot tool shell's PID is not the coordinator PID.
- Stop owned workers and preserve their evidence before finalising an audit.
  Run python3 ~/workspace/ai/scripts/resource_guard/finalize_audit.py --run
  <run-directory> --apply under a 110-second outer timeout. The finaliser
  verifies archiving and resource retirement before setting run_status complete.
  Missing result.json is not grounds for leaving a cancelled agent's RAM disk
  indefinitely. Preserve data and report a blocked cleanup for a busy resource.
- Keep the independent launchd Claude and audit guards enabled. They recover
  missed lifecycle hooks and interrupted finalisation. Do not delete team
  configuration or send broad process-name kills to simulate cleanup.
