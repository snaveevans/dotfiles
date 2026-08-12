# Git Worktrees

`wt` lists and switches between git worktrees from the terminal, Kitty, and Neovim.

It only tracks worktrees created with `wt new`, which land under `$WT_ROOT`.
Claude Code and opencode create worktrees of their own for background-job
isolation (`<repo>/.claude/worktrees/`, `~/.local/share/opencode/worktree/<repo-hash>/`),
but `wt` no longer discovers those - if you want a worktree `wt` can see,
create it with `wt new`.

## The loop

1. `wt new tyler/CCLOUD-1234-thing` creates a worktree under `$WT_ROOT` and
   leaves you in it (`cmd+enter c` in Kitty does the same and opens a tab into it).
2. Work normally: `nvim`, run the tests, run the app.
3. `cmd+enter w` to jump between that worktree and the primary checkout. Each
   gets its own Kitty tab, so each keeps its own Neovim and its own shell state.
4. Push, merge, close the tab. `wt clean` sweeps it up once the branch is
   merged, the worktree is clean, and no tab has it open - or `wt rm` to
   remove one by hand, which takes the branch with it if you pass
   `--delete-branch`.

## Install

`wt` lives at `home/.local/bin/wt` and is linked into `~/.local/bin` by
`scripts/install-home-links.sh`, which is already on `PATH` via `home/.zshenv`.

```bash
scripts/install-home-links.sh
```

`home/.zshrc` defines a `wt` shell function that shadows the binary. It exists
only so that switching can change the current shell's directory; every other
subcommand passes straight through.

## Commands

```text
wt                    pick a worktree and cd into it
wt list               print the worktrees in scope
wt new BRANCH         create a worktree under $WT_ROOT and cd into it
wt rm                 pick a worktree and remove it
wt prune              drop stale worktree registrations
wt clean              remove worktrees that are merged, clean, and unopened
wt tab                open or focus a Kitty tab for a worktree
```

Useful options: `-a/--all` to scan every repo instead of just the current one,
`-s/--status` to compute dirty markers, `--repo NAME` to act on another repo,
`--dry-run` on anything that mutates. `wt --help` lists the rest.

## Reading the listing

```text
prism-ui  main   main                                       23 hours ago
prism-ui  wt     tyler/CCLOUD-10967-badge-token-experiment  7 weeks ago  ● working ×2
prism-ui  wt     tyler/CCLOUD-10932-followup                2 days ago   ⏸ needs input
dotfiles  wt     worktree-status-glyphs                     1 hour ago   ✓ done
```

The second column is the origin, which is derived from where the worktree lives:

| Origin | Meaning |
| --- | --- |
| `main` | the primary checkout of the repo |
| `wt` | created by `wt new`, under `$WT_ROOT` |
| `other` | a worktree somewhere else, such as a hand-made sibling directory |

Rows are sorted by commit recency, so whatever you touched most recently sorts
to the top. The current repo's primary checkout is pinned first.

Dirty markers are off by default because `git status` on a large repo costs a
few hundred milliseconds per worktree, which is enough to make the picker feel
slow. Pass `-s` when you want them.

## Agent status

The trailing column shows Claude Code sessions currently running in a
worktree, read from `$CLAUDE_JOBS_DIR` (each session writes its own
`cwd` and `state` there). It's cheap - local JSON reads, no git calls - so
unlike dirty markers it's always on.

| Glyph | State | Meaning |
| --- | --- | --- |
| `⏸ needs input` | `blocked` | the session is waiting on you |
| `✗ failed` | `failed` | the session errored out |
| `● working` | `working` | the session is actively running |
| `✓ done` | `done` | the session finished |

A worktree "has" a session if that session's cwd is at or under the
worktree's path - agents often work a few directories deep, not at the root.
When more than one session matches, the most attention-worthy state wins in
that order (`needs input` beats `failed` beats `working` beats `done`), and a
`×N` suffix shows how many matched.

This reads Claude Code's own internal job state, which isn't a documented or
versioned interface - a future CLI update could change its shape and quietly
stop populating the column. Nothing breaks if that happens; worktrees just
stop showing a glyph.

## Key bindings

| Binding | Where | Action |
| --- | --- | --- |
| `Ctrl-k w` | zsh | pick a worktree and cd into it |
| `cmd+enter w` | Kitty | pick a worktree (all repos), open or focus its tab |
| `cmd+enter r` | Kitty | pick a worktree (this repo), open or focus its tab |
| `cmd+enter c` | Kitty | prompt for a branch name and base branch, create a worktree, open a tab into it |
| `<leader>gw` | Neovim | worktrees in the current repo |
| `<leader>gW` | Neovim | worktrees across every repo |

In the Neovim picker, `Enter` opens a Kitty tab so each worktree keeps its own
Neovim instance, LSP clients, and session. `Ctrl-t` opens a Neovim tab page
scoped to the worktree with `:tcd` when you only need a quick look, and
`Ctrl-y` yanks the path.

Kitty tabs are titled `<repo>` for a primary checkout and `<repo>:<directory>`
for a worktree, so switching finds and focuses an existing tab instead of
opening a duplicate.

## Where new worktrees go

`wt new` creates worktrees at `$WT_ROOT/<repo>/<slug>`, defaulting to
`~/worktrees`. The branch name is slugified, so `tyler/CCLOUD-10967-badge-token`
becomes `~/worktrees/prism-ui/tyler-CCLOUD-10967-badge-token`.

The base ref is `origin`'s HEAD branch unless you pass `--from REF`. If the
branch already exists locally it is checked out as-is; if it only exists on the
remote it is checked out with tracking.

Discovery reads `git worktree list --porcelain` for whatever's in scope, then
drops anything under `<repo>/.claude/worktrees/` or
`~/.local/share/opencode/worktree/` - those are agent-managed, not `wt`-managed.

## Cleaning up

`wt clean` removes every worktree `wt` can see (`wt` or `other`) that's done
with, and deletes its branch along with it. A worktree only qualifies if all
four hold:

- No uncommitted changes (untracked files don't count, same as the dirty
  marker in the listing).
- Its branch is merged into the repo's default base ref (`origin`'s HEAD
  branch, or `--from REF`) - checked with `merge-base --is-ancestor`, so a
  squash-merged PR won't register as merged even though it's really done.
- No Kitty tab is currently open for it.
- No Claude Code session has its cwd at or under the worktree with state
  `working` or `blocked` - see [Agent status](#agent-status). A `done` or
  `failed` session doesn't block cleanup.

It refuses to touch the primary checkout and skips anything it can't
confidently classify (detached HEAD, no determinable base ref). Run
`wt clean --dry-run` first to see what it would remove without changing
anything, same as `wt new --dry-run`.

## Configuration

Read from the environment and can be set in `~/.config/zsh/local.env`:

- `WT_ROOT` — where `wt new` creates worktrees (default `~/worktrees`)
- `WT_WORKSPACE` — where repos are scanned from (default `~/workspace`)
- `CLAUDE_JOBS_DIR` — where Claude Code job state lives (default `~/.claude/jobs`)

A workspace scan only descends one level and only into directories with a real
`.git` directory, which is how a linked worktree sitting in the workspace avoids
being scanned as a repo in its own right.

## Verification

```bash
scripts/test-wt.sh
```

This drives real git inside a throwaway directory, since worktree semantics are
the thing being tested.
