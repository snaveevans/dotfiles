---
status: "accepted"
date: 2026-08-12
decision-makers:
  - "Tyler Evans"
consulted: []
informed: []
---

# Restrict worktree discovery to wt-created worktrees

## Context and Problem Statement

ADR-0002 made `wt` location-agnostic: it discovers worktrees wherever Claude
Code, opencode, or a human puts them, and classifies each by path into
`main`, `claude`, `opencode`, `wt`, or `other`. That worked while `wt` was
read-only with respect to agent-owned worktrees — it could list one and
switch to it, but nothing more.

`wt` has since grown a full lifecycle: `wt new` (and Kitty's `cmd+enter c`)
create a worktree, `cmd+enter w`/`r` switch to one, and `wt clean` removes
any worktree in scope that's merged, clean, and has no open Kitty tab —
regardless of who created it. That last part is the problem: Claude Code and
opencode manage their own worktrees' lifecycles independently of `wt`, and a
worktree `wt clean` judges "done" from git and Kitty state alone may still be
one an agent is mid-task in, or expects to find again later. Deleting it out
from under that tool is exactly the kind of destructive-by-heuristic action
`wt clean`'s own safety gates exist to avoid for `wt`-owned worktrees.

Separately, now that creation, switching, and cleanup are all handled by one
tool, there's no longer a reason to create a worktree any other way.

## Decision Drivers

- `wt clean` acting on agent-owned worktrees risks deleting one Claude Code
  or opencode still considers live, since neither tool coordinates with `wt`
- the tool now covers the whole lifecycle, so mixing in worktrees created
  outside it no longer adds capability, only risk
- `~/worktrees` is the one location every `wt` command already assumes for
  writes (`wt new`); narrowing reads to match keeps the mental model to one
  directory

## Considered Options

- Keep location-agnostic discovery everywhere, unchanged
- Keep location-agnostic discovery for `list`/`rm`/`tab`, but exclude agent
  locations from `wt clean` specifically
- Exclude `.claude/worktrees/` and `.local/share/opencode/worktree/` from
  discovery entirely (this decision)

## Decision Outcome

Chosen option: exclude agent locations from discovery entirely, because a
worktree `wt` cannot see is also a worktree `wt clean` cannot delete, and a
single rule ("everything under `$WT_ROOT`") is easier to reason about than
"agent worktrees are visible everywhere except this one destructive command."

This decision means:

- worktrees under `<repo>/.claude/worktrees/` and
  `~/.local/share/opencode/worktree/` no longer appear in `wt`, `wt list`,
  `wt rm`, `wt tab`, or `wt clean`, in any repo
- `wt new` (and `cmd+enter c`) becomes the only supported way to create a
  worktree `wt` will manage
- `classify_origin` narrows to `main`, `wt`, `other` — the `claude` and
  `opencode` origins from ADR-0002 are gone, not just hidden

### Consequences

- Positive: `wt clean` can no longer delete a worktree an agent tool still
  considers its own.
- Positive: one rule to reason about ("under `$WT_ROOT`, or it doesn't exist
  as far as `wt` is concerned") instead of a five-way classification.
- Negative: loses the original motivating benefit of ADR-0002 — an
  agent-created worktree still needs the agent's own UI (or a manual `cd`)
  to reach, since `wt` no longer indexes it.
- Negative: existing worktrees under the excluded locations become invisible
  to `wt` outright; they still exist on disk and in git, just unmanaged by
  this tool until migrated to `$WT_ROOT` by hand — a one-time cleanup, not
  something `wt` does for you.

## Confirmation

`scripts/test-wt.sh` creates a worktree under each excluded location
alongside the ones that should remain visible, and asserts both that they're
absent from every listing format and that `wt clean` leaves them untouched.

Supersedes [ADR-0002](./ADR-0002-centralize-hand-made-git-worktrees-with-location-agnostic-discovery.md).
