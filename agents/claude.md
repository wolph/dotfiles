## Task Management

- Multi-step work gets a task per step with TaskCreate before the first edit.
  Dependencies go in with addBlockedBy. Status moves to in_progress before a
  step starts and to completed only after verification.
  Why: Ctrl+T shows the list to the user while work runs.
- Each session has its own task list (session-<first 8 of the session id>),
  which /resume keeps and an agent team shares with its lead. The claude
  shell function drops CLAUDE_CODE_TASK_LIST_ID. Never set it to share a
  list between sessions.
  Why: a list shared per repository was used by every concurrent session in
  that repository and kept old sessions' tasks, so new sessions started on
  unrelated work (removed 2026-11-13).
- A task is completed only when its description carries a line
  `Verified: <check> -> <result>` or `Unverified: <reason>`. A TaskCompleted
  hook rejects anything else. Write the line with TaskUpdate first.
  Why: the verification rule above was prose. The hook makes it a gate.
- Work left unfinished at the end of a session goes into the remember notes,
  not into a task list for a later session. A new session starts from the
  user's request. /open reports git, GitHub and the remember notes when the
  user asks where they were.

## Background Agents (Claude Code)

- A hook injects `Running agents: ...` on every user turn while Agent-tool
  subagents run. An agent absent from that line has
  not started. One marked `over 10 min` is stopped and its work taken over,
  as the global rule says. Teammates in tmux panes are not on the line.

## Agent teams (Claude Code)

- The Parallel Work rule above is carried out with an agent team. Spawn every
  teammate in one message, each an Agent call with a `name` (a named Agent
  call launches as a teammate while teams are enabled), and put the shared
  work on the task list with TaskCreate so teammates can claim it.
- Pick a fitting subagent type per teammate (Explore for read-only sweeps,
  security-reviewer, general-purpose for edits) and name the model in the
  spawn prompt when a cheaper one does the job.
- Parallel edits in one repository: each teammate owns its own files. When
  ownership cannot be split, use an unnamed Agent call with
  `isolation: "worktree"` instead, which runs as a subagent in its own
  worktree.
- An unnamed Agent call or a fork stays an ordinary subagent. Use that for a
  single focused lookup whose result is all that matters.
- Teammates cannot spawn teammates and their own subagents run in the
  foreground. `/resume` does not bring in-process teammates back: after a
  resume, spawn a new team.
- The lead waits for the idle notifications instead of implementing the
  delegated parts itself, and asks each teammate to shut down once its work
  is verified.

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

- Agent teams are enabled (CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1) with
  in-process teammates (teammateMode in-process), so teammates live inside
  the lead's process and stay under the resource guard.
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
