---
status: "accepted"
date: 2026-07-21
decision-makers:
  - "Tyler Evans"
consulted: []
informed: []
---

# Centralize hand-made git worktrees with location-agnostic discovery

## Context and Problem Statement

Git worktrees were already in daily use across roughly a quarter of the repos in
`~/workspace`, created by three tools that know nothing about each other:

- Claude Code, at `<repo>/.claude/worktrees/<name>`
- opencode, at `~/.local/share/opencode/worktree/<repo-hash>/<name>`
- by hand, as sibling directories such as `~/workspace/mig-ccloudui-followup-cleanup`

There was also an empty `~/workspace/copilot-worktrees/` left over from an earlier
attempt at a shared convention.

Nothing tied these together. When an agent created a worktree, the only way into
it from the terminal was to copy a path out of that agent's UI, which made an
otherwise ordinary checkout awkward to open in Neovim or run commands against.

## Decision Drivers

- agent tools choose their own worktree locations and will not adopt ours
- `~/workspace` is a flat list of 63 repos that stays browsable only if nothing else lands there
- nested checkouts inside a repo get traversed by ripgrep, fzf, and LSP root scans
- switching has to be fast enough to sit behind a keybinding

## Considered Options

- Central root: `~/worktrees/<repo>/<slug>`
- In-repo: `<repo>/.worktrees/<slug>`
- Sibling directories: `~/workspace/<repo>--<slug>`

## Decision Outcome

Chosen option: "Central root", because it is the only option that keeps both the
workspace listing and the repo trees clean, and the concern it trades away —
locality — is handled by discovery rather than by layout.

The decision splits into two halves that are worth stating separately:

- **Creation** is centralized. `wt new` writes to `$WT_ROOT/<repo>/<slug>`,
  defaulting to `~/worktrees`.
- **Discovery** is location-agnostic. `wt` reads `git worktree list --porcelain`
  and classifies each result by path into `main`, `claude`, `opencode`, `wt`, or
  `other`.

This decision means:

- agent-created worktrees are first-class in the picker without any tool changing its behavior
- the flat `~/workspace` listing and the existing Kitty project picker keep working unchanged
- repos gain no new gitignore entries and no nested checkouts

### Consequences

- Positive: a single command reaches every worktree on the machine, whoever made it.
- Positive: classification is derived, so a new agent tool with a new location
  still appears — as `other` — rather than disappearing.
- Negative: worktrees are no longer next to their repo, so `cd ..` does not reach
  the primary checkout. Switching goes through `wt` instead.
- Negative: the origin classification is a path heuristic. If a tool changes
  where it writes worktrees, the tag silently degrades to `other`.

## Confirmation

`scripts/test-wt.sh` builds a fixture repo with a worktree at each origin
location and asserts the classification of every one, so a regression in the
heuristic fails the test rather than quietly mislabeling rows.
