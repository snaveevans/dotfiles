---
status: "accepted"
date: 2026-08-14
decision-makers:
  - "Tyler Evans"
consulted: []
informed: []
---

# Surface Pi session state in the Kitty pickers

## Context and Problem Statement

ADR-0004 and ADR-0005 added an agent-status column driven by Claude Code
(`claude agents --json`) and OpenCode (process table + `lsof`). Pi is now in
daily use in the same Kitty tabs, and those sessions are invisible to
`wt list` and `cmd+enter o` even though they are the thing the picker is
supposed to help prioritize.

Pi has no equivalent of `claude agents --json`. Its CLI can list models and
manage extensions, but nothing enumerates live interactive sessions or what
they are doing. Process-table detection (the OpenCode approach) also fails
here: `pi` is a Node script (`#!/usr/bin/env node` →
`@earendil-works/pi-coding-agent/dist/cli.js`), so `ps -eo pid,comm` reports
`node`, not `pi`. Matching every `node` process and then guessing which ones
are Pi would be both noisy and still unable to tell working from idle.

Pi does expose the missing state internally. Extensions can subscribe to
`agent_start` / `agent_settled` and call `ctx.isIdle()`, which is exactly
the working-vs-idle distinction the picker already understands.

## Decision Drivers

- the status column only answers "which tab do I need to go back to" if it
  covers every agentic tool actually in use
- claiming working-vs-idle for Pi is only honest if Pi itself publishes
  that distinction; inventing it from the process table would be a
  precision the data does not support
- `wt clean`'s live-session gate needs to know about Pi sessions for the
  same reason it needs to know about Claude and OpenCode: a worktree a
  session is sitting in should not be deleted out from under it

## Considered Options

- Don't surface Pi at all - wait for it to ship something equivalent to
  `claude agents --json`
- Detect running Pi processes via the process table, the way ADR-0005 does
  for OpenCode
- Have a Pi extension write a small per-process status file, and have `wt`
  / `kitty_selector.py` read those files (this decision)

## Decision Outcome

Chosen option: a tiny extension that publishes live state. Pi already runs
user extensions from `~/.pi/agent/extensions/*.ts`, and those extensions
see `agent_start`, `agent_settled`, and `ctx.isIdle()`. Writing
`~/.pi/agent/status/<pid>.json` on those events is the smallest surface
that gives the pickers a real working/idle signal without waiting on an
upstream CLI or pretending `node` processes are Pi sessions.

This decision means:

- `home/.pi/agent/extensions/session-status.ts` is a tracked, auto-loaded
  Pi extension. In TUI mode it writes `{ pid, cwd, state, updatedAt }` to
  `~/.pi/agent/status/<pid>.json` on `session_start` / `agent_start` /
  `agent_settled`, and deletes that file on `session_shutdown`. Print and
  RPC modes write nothing - those are not Kitty-tab sessions
- `state` is only `working` or `idle`. Pi has no documented equivalent of
  Claude Code's `blocked` / `done` / `failed` (no background-job
  vocabulary, and no extension hook for "a confirm/select dialog is
  open"), so those states are not invented
- those two states reuse the existing Claude Code labels and priorities
  (`● working`, `○ idle`) rather than adding a catch-all `pi` tier like
  OpenCode. The picker is about attention, not which binary is running,
  and unlike OpenCode we actually know working from idle
- `wt` and `kitty_selector.py` each grow a `load_pi_jobs` that reads every
  `*.json` in the status directory, drops files whose pid is no longer
  alive (`kill -0` / `os.kill(pid, 0)`), and unions the rest with Claude
  and OpenCode jobs. A dead pid is also unlinked, so a crash cannot leave
  a stale glyph behind
- `wt clean` needs no new gate: a live Pi session reports `working` or
  `idle`, both of which already block cleanup
- the three loaders stay independent, so one tool being missing or
  erroring never hides the others

### Consequences

- Positive: Pi sessions show up in the same place as Claude and OpenCode,
  with an honest working/idle distinction instead of a catch-all "a
  process is here."
- Positive: `wt clean` can no longer delete a worktree a live Pi session
  is sitting in, closing the same gap ADR-0004 / ADR-0005 closed for the
  other two tools.
- Negative: status is only as fresh as the last event the extension saw.
  A hard kill (`SIGKILL`) leaves a file until the next `wt` / picker read
  notices the pid is dead and removes it. That is a brief stale window,
  not a permanent lie, and it is the same class of problem a crashed
  Claude session would have if `claude agents --json` lagged.
- Negative: another local, unversioned contract - this time one we own
  (`~/.pi/agent/status/<pid>.json`) rather than one we scrape. A shape
  change has to be made in three places (the extension, `wt`,
  `kitty_selector.py`), same duplication ADR-0004 already accepted.
- Negative: `blocked` / `done` / `failed` stay Claude-only. A Pi session
  waiting on a confirm dialog looks idle to the picker. That is an
  intentional gap (no hook exists) rather than a false "needs input."

## Confirmation

`scripts/test-wt.sh` writes fixture files under the fake `$HOME/.pi/agent/status/`
already used for the rest of the suite. A file whose pid is the test
process itself is treated as live; a file whose pid is a number `kill -0`
rejects is ignored (and removed). Covers: a live working session surfacing
as `● working`; a live idle session surfacing as `○ idle`; a dead-pid file
producing no glyph; a Pi session sharing a worktree with a higher-priority
Claude job adding to the count without changing the winning label; and
`wt clean` skipping a worktree with a live Pi session until that file is
gone.

`scripts/test-kitty-selector.py` covers the same cases by pointing
`pi_status_dir()` at a temp directory and writing the same fixture shape,
including malformed JSON and a missing status directory degrading to no
jobs rather than raising.
