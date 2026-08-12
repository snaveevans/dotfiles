---
status: "accepted"
date: 2026-08-12
decision-makers:
  - "Tyler Evans"
consulted: []
informed: []
---

# Surface Claude Code job state in wt's worktree listing

## Context and Problem Statement

`wt list` (and the Kitty pickers built on it) show every worktree in scope,
but nothing about what's happening inside them. With several worktrees open
at once, picking which one to jump back into means opening each one to check:
is an agent still working here, is it stuck waiting on input, did it finish,
did it fail. That's exactly the information needed to prioritize, and it
already exists - Claude Code writes it to disk for its own use.

Every Claude Code session, background or interactive, is backed by a job
directory under `~/.claude/jobs/<id>/state.json` containing (among other
things) the session's `cwd` and a `state` of `working`, `blocked`, `done`, or
`failed`. A worktree's path can be matched against those `cwd` values to
answer "is an agent in here, and how urgently does it need me."

## Decision Drivers

- the data already exists on disk, updated by Claude Code itself; no new
  process, polling, or API integration is needed to get it
- reading it is cheap (local JSON files, no git calls), unlike the dirty
  marker, which costs a `git status` per worktree and stays opt-in
- `wt clean`'s existing gates (merged, no uncommitted changes, no open Kitty
  tab) already exist to avoid deleting a worktree that's still in use; a live
  agent job is the same category of "still in use" the Kitty tab check covers

## Considered Options

- Don't surface it - keep `wt` scoped to git state only
- Surface it as a separate command (`wt agents`) rather than a column on `wt list`
- Add it as a column on `wt list`, computed by default, and reuse the same
  signal as a `wt clean` gate (this decision)

## Decision Outcome

Chosen option: add it as a column and reuse it as a clean gate, because the
whole point is to see it at a glance while picking a worktree, not to look it
up separately - and a worktree `wt clean` would delete out from under a
working agent is the exact failure ADR-0003 already exists to prevent for
Kitty tabs.

This decision means:

- `wt list` gains a trailing status column: `● working`, `⏸ needs input`,
  `✗ failed`, or `✓ done`, with a `×N` suffix when more than one session
  matches
- a worktree "has" a session if that session's `cwd` is at or under the
  worktree's path, not just an exact match, since agents often work a few
  directories deep
- when multiple sessions match, the most attention-worthy state wins:
  `blocked` > `failed` > `working` > `done`
- `wt clean` additionally skips a worktree with a `working` or `blocked`
  session pointed at it, alongside its existing gates
- `CLAUDE_JOBS_DIR` (default `~/.claude/jobs`) joins `WT_ROOT`/`WT_WORKSPACE`
  as a configurable root

### Consequences

- Positive: the picker answers "which of these do I actually need to go
  back to" without opening each worktree.
- Positive: `wt clean` can no longer delete a worktree a live Claude Code
  session is still working in or waiting on.
- Negative: this reads Claude Code's own internal job state, which is not a
  documented or versioned interface. A future CLI update could change its
  shape and silently stop populating the column - degrading gracefully to no
  glyph, not an error, but still a dependency on unstable internals.
- Negative: only sessions backed by a job directory are visible. A bare
  `claude` invocation with no job directory (if one exists outside this
  mechanism) won't show up.

## Confirmation

`scripts/test-wt.sh` fabricates job state files under a fake
`$CLAUDE_JOBS_DIR`, and asserts both that `wt list` surfaces the resulting
glyph (including the multi-session precedence and count) and that `wt clean`
skips a worktree with a `working` session until that job's state changes.
