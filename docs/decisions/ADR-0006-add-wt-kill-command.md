---
status: "accepted"
date: 2026-08-13
decision-makers:
  - "Tyler Evans"
consulted: []
informed: []
---

# Add a `wt kill` command

## Context and Problem Statement

`wt rm` and `wt clean` (ADR-0004) are both deliberately careful: they refuse
a worktree with uncommitted changes, refuse an unmerged branch, refuse one
with an open Kitty tab or a live agent job. That caution is right for
cleaning up after normal work, but it means finishing with a throwaway
worktree - a quick experiment, a spike that didn't pan out - takes several
steps: close the tab, run `wt rm --force` (and maybe `--delete-branch`),
possibly fight with the picker if you don't remember the exact branch name.
The ask was for a single command, run from inside the worktree itself, that
tears down all of it at once - the tab, every pane in it, the directory, and
the worktree registration - without going through `wt rm`'s safety gates
first.

## Decision Drivers

- the worktrees this targets are, by definition, ones the user has already
  decided are disposable - re-running `wt rm`'s merged/clean checks against
  them is friction, not protection
- it still needs *some* safety net: a single mistimed keypress that deletes
  uncommitted work and kills the tab it's typed in, with zero confirmation,
  is one accidental chord away from real data loss
- it needs to work from any subdirectory inside the worktree, not just the
  root, since that's where an interactive session is often sitting
- closing "the tab" has to mean the literal Kitty tab this command was run
  from, not a tab picked from a list - there's no picker step in the ask

## Considered Options

- Add a `--force`-like flag to `wt rm` that also bypasses the dirty/merged
  checks and closes the invoking tab
- A new `wt kill` command, scoped to `$PWD`'s own worktree, with its own
  (lighter) safety gate
- No confirmation at all - the keybinding itself is the confirmation

## Decision Outcome

Chosen option: a new `wt kill` command. Overloading `wt rm` was rejected
because `rm`'s whole contract is "pick one, remove it carefully with a
picker or `--path`" - bolting "also skip every check and close my tab" onto
that as a flag combination would make `rm` harder to reason about for the
common case it already serves well. `kill` instead:

- always resolves its target from `$PWD` via `git rev-parse
  --show-toplevel`, so it works from any depth inside the worktree, no
  `--path` or picker needed
- always runs `git worktree remove --force`, dirty or not - the checks `rm`
  enforces are exactly the ones this command exists to skip
- asks for a typed `yes` before doing anything, unless `--force` is passed -
  note `--force` means something different here than it does for `rm`: for
  `kill` there's no dirty-check to bypass, so `--force` only skips the
  prompt
- reuses `rm`'s existing `--delete-branch` flag unchanged (opt-in, off by
  default) rather than inventing new flag names for the same concept
- refuses the primary checkout, the same non-negotiable guard `rm` has
- closes the Kitty tab via `kitty @ close-tab --match "window_id:$KITTY_WINDOW_ID"`
  - `$KITTY_WINDOW_ID` is set in every Kitty window's environment already,
    so no picker or tab-title lookup is needed to identify "this tab"
  - resolves to "no-op, not an error" when `$KITTY_WINDOW_ID` is unset
    (outside Kitty entirely - SSH, tmux, a plain terminal) or `kitty` isn't
    on PATH, the same fail-open posture `wt`'s other Kitty integrations
    already take

No-confirmation-at-all was rejected: the keybinding is one chord
(`cmd+enter k`), easy to fire by muscle memory meant for a different chord,
and the action it triggers is unrecoverable (deleted working tree, no
trash/undo). A typed `yes` is cheap for the deliberate case and a real
speed bump for the accidental one.

The Kitty binding runs `wt kill` inside `launch --type=overlay --cwd=current
--hold`, not by sending keystrokes into the existing pane
(`send_text`). An overlay avoids corrupting whatever the user was already
mid-typing at their shell prompt, and `--hold` keeps the overlay open if
`wt kill` exits non-zero (refused or aborted) so the reason is visible
instead of flashing and vanishing. On the success path `--hold` never
matters, because `wt kill` itself closes the whole tab - overlay included -
before the shell would otherwise sit at "press enter to exit."

### Consequences

- Positive: tearing down a disposable worktree - tab, panes, directory,
  registration - is one chord and one typed confirmation, instead of
  closing the tab by hand and separately remembering `wt rm --force
  --delete-branch <name>`.
- Positive: `wt rm`'s contract is unchanged - no new flag combinations to
  reason about there.
- Negative: `wt kill` and `wt rm --force` now both exist and mean different
  things (`rm --force` bypasses the dirty check but still needs a target and
  still leaves the tab open; `kill` always bypasses the dirty check, always
  targets `$PWD`, and always closes the tab) - a reader skimming `--force`
  across both commands has to know it means something different in each.
  Documented in both `wt --help` and this ADR rather than papered over.
- Negative: unlike `wt clean`, `wt kill` does not check for a live agent job
  (Claude Code or OpenCode) in the worktree before removing it. This is
  intentional, not an oversight - `kill` is an explicit, deliberate command
  run by a human sitting in that exact tab, not an unattended sweep like
  `clean`, so the premise is that the human already knows what's running
  there. Worth revisiting if this ever gets scripted or run unattended.

## Confirmation

`scripts/test-wt.sh` extends the fake `kitty` binary (introduced in
ADR-0005) to also answer `close-tab`, logging its arguments to a file the
test points at via `FAKE_KITTY_CLOSE_TAB_LOG` - the same env-var-fixture
pattern used throughout this test file. Covers: refusing the main worktree;
aborting (and leaving the worktree in place) when the typed confirmation
isn't exactly `yes`; force-removing a dirty worktree with no
`--delete-branch` leaving the branch intact; force-removing with
`--delete-branch` also deleting the branch; closing exactly the tab
matching a given `$KITTY_WINDOW_ID`; and running with `$KITTY_WINDOW_ID`
unset (outside Kitty) still removing the worktree without attempting to
close anything.
