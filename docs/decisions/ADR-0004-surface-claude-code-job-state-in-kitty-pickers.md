---
status: "accepted"
date: 2026-08-12
decision-makers:
  - "Tyler Evans"
consulted: []
informed: []
---

# Surface Claude Code job state in the Kitty pickers

## Context and Problem Statement

`wt list` (and the Kitty pickers built on it) show every worktree in scope,
but nothing about what's happening inside them. With several worktrees open
at once, picking which one to jump back into means opening each one to check:
is an agent still working here, is it stuck waiting on input, did it finish,
did it fail. That's exactly the information needed to prioritize, and it
already exists - Claude Code writes it to disk for its own use.

Claude Code exposes its own session list via `claude agents --json`,
documented (`claude agents --help`) as "for scripting; does not require a
TTY." It reports every active session - background jobs and live
interactive ones - with a `cwd` and either a `state` (`working`/`blocked`/
`done`/`failed`, for background jobs) or a `status` (`busy`/`waiting`/
`idle`/`shell`, for interactive ones). A worktree's path can be matched
against those `cwd` values to answer "is an agent in here, and how urgently
does it need me."

An earlier version of this read `~/.claude/jobs/<id>/state.json` directly
instead of going through the CLI. That only ever surfaced background jobs:
a plain `claude` session sitting live in a terminal has no job directory,
only background jobs get one - so the majority of real usage (an
interactive session in a Kitty tab, which is what `cmd+enter o` is *for*)
was invisible. `claude agents --json` covers both in one call.

## Decision Drivers

- Claude Code already tracks this and exposes it as a documented CLI
  surface (`claude agents --json`); no polling, daemon, or API integration
  of our own is needed to get it
- reading it is cheap (one local subprocess call, no git calls), unlike the
  dirty marker, which costs a `git status` per worktree and stays opt-in
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
  `✗ failed`, `✓ done`, or `○ idle`, with a `×N` suffix when more than one
  session matches. `idle` covers both an interactive session's `idle` and
  `shell` statuses - there's no interactive equivalent of `done`/`failed`,
  since the process just isn't there anymore once it exits
- a worktree "has" a session if that session's `cwd` is at or under the
  worktree's path, not just an exact match, since agents often work a few
  directories deep
- when multiple sessions match, the most attention-worthy state wins:
  `blocked` > `failed` > `working` > `done` > `idle`
- `wt clean` additionally skips a worktree with a `working`, `blocked`, or
  `idle` session pointed at it, alongside its existing gates. `idle` counts
  here even though it's lowest-priority to *display* - an idle interactive
  session is still a live process sitting in the worktree, and deleting it
  out from under that process would be disruptive regardless of whether
  there's anything urgent to show about it
- the same glyphs also appear in Kitty's `cmd+enter o` (pick an already-open
  tab) - the picker actually used day to day - matched against each tab's
  window `cwd` rather than a worktree path. That picker is a Python kitten,
  not `wt`, so the matching logic is duplicated in `kitty_selector.py` rather
  than shared
- `$HOME` is never used as a match anchor, in either implementation. A shell
  sitting bare at home isn't "inside" a project, and every job's cwd is a
  descendant of home, so treating it as an anchor would match nearly every
  job on the machine - which is exactly what happened to a split-pane
  `cmd+enter o` tab with one window parked at home
- `$WT_WORKSPACE` and `$WT_ROOT` get a narrower version of the same rule:
  they're containers whose children are separate projects, so they only
  match a job whose cwd is exactly the container path, never a descendant.
  Unlike `$HOME`, a tab sitting bare at `~/workspace` is a real, intentional
  workflow (cloning a new repo, running something that isn't scoped to one
  project), so the fix is narrower matching, not exclusion

### Consequences

- Positive: the picker answers "which of these do I actually need to go
  back to" without opening each worktree.
- Positive: `wt clean` can no longer delete a worktree a live Claude Code
  session is still working in or waiting on.
- Positive: interactive sessions are visible at all, not just background
  jobs - this is what caught the original bug (a job-directory-only version
  showed nothing for a live session in the "rosetta:doc-regen" tab, since
  interactive sessions never had a job directory to read).
- Negative: `claude agents --json` is Claude Code's own CLI surface, not a
  documented, versioned wire format. A future CLI update could change its
  shape and silently stop populating the column - degrading gracefully to no
  glyph, not an error, but still a dependency on unstable internals. This
  replaced an earlier, even less stable dependency (raw job-directory files),
  so it's a strict improvement, not a new risk.
- Negative: the matching/priority/label logic exists twice - once in bash
  (`wt`), once in Python (`kitty_selector.py`) - because `cmd+enter o` isn't
  a `wt` command. A change to the glyphs or precedence rules has to be made
  in both places.

## Confirmation

`scripts/test-wt.sh` fakes the `claude` binary on `PATH` (the same
established pattern the suite already used for `kitty`) so `claude agents
--json` returns fixture sessions instead of whatever's really running, and
asserts `wt list` surfaces the resulting glyph (multi-session precedence and
count, and an interactive session's `status` translating correctly), and
that `wt clean` skips a worktree with a `working` session, and separately an
`idle` one, until that session's state changes.

`scripts/test-kitty-selector.sh` covers the Python side the same way, by
monkeypatching `subprocess.run` instead of faking a binary on `PATH` (both
achieve the same thing: a hermetic double for `claude agents --json`) -
precedence including `idle` as the lowest tier, nested-path matching, no
false match on a similarly-named sibling, `$HOME` exclusion (including a
home-anchored pane not leaking into a real project window sharing its tab),
`$WT_WORKSPACE`/`$WT_ROOT` exact-only matching, and `claude` being missing or
erroring degrading to no jobs rather than raising - by importing
`kitty_selector.py` with `kitty.boss` stubbed out, since that module only
exists inside Kitty's own runtime.

One implementation pitfall worth recording: `wt`'s bash side originally
joined fields with a tab and split them with `IFS=$'\t' read`, which
silently misaligned columns whenever `state` or `status` was empty (always
true for one of them, since a session has one or the other, never both) -
bash treats tab as "IFS whitespace" and collapses/strips empty fields even
when IFS is set to just a tab. Switched to a pipe, which isn't IFS
whitespace and isn't a character a real cwd would contain.

Verified against the real machine both ways: `wt list --all` and the
`cmd+enter o` picker both picked up a live `idle` interactive session
(`rosetta:doc-regen`) that a job-directory-only read had missed entirely.
