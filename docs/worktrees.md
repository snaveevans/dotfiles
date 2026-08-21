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
wt kill               delete the current worktree (forced) and close this Kitty tab
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

The trailing column shows agentic coding sessions currently running in a
worktree - both Claude Code and OpenCode. It's cheap enough to run on every
`list` - no git calls - so unlike dirty markers it's always on. The same
glyphs appear next to tab titles in `cmd+enter o` (see
[keybindings.md](keybindings.md)), which is implemented separately in
`kitty_selector.py` since it's Python, not `wt` - same matching rules, kept
in sync by hand.

| Glyph | Meaning |
| --- | --- |
| `⏸ needs input` | a Claude Code session is waiting on you |
| `✗ failed` | a Claude Code background job errored out |
| `● working` | a Claude Code session is actively running |
| `✓ done` | a Claude Code background job finished |
| `○ idle` | a Claude Code session is open but nothing is happening right now |
| `◆ opencode` | an OpenCode process is running - busy vs. idle can't be told apart |

Claude Code state comes from `claude agents --json` - the CLI's own
scriptable session list, covering both background jobs and live interactive
sessions (a plain `claude` session sitting in a terminal has no job
directory, so reading `~/.claude/jobs` directly, an earlier version of this,
missed those entirely). A background job's own `working`/`blocked`/`done`/
`failed` state maps straight onto the glyphs above; a live interactive
session only reports `busy` / `waiting` / `idle` / `shell`, which translates
to `working` / `needs input` / `idle` / `idle` respectively - there's no
interactive equivalent of `done`/`failed`, since the process just isn't
there anymore once it exits.

OpenCode has no equivalent session-status API - `opencode session list` only
returns historical metadata, never which sessions are live or what they're
doing. Its glyph instead comes from the process table: a running `opencode`
process is found via `ps` and its working directory resolved with
`lsof -d cwd`. This can only say a session is *present*, not what it's
doing, hence one catch-all glyph rather than the graduated states Claude
Code gets.

A worktree "has" a session if that session's cwd is at or under the
worktree's path - agents often work a few directories deep, not at the root.
When more than one session matches (from either tool, or both), the most
attention-worthy state wins in that order (`needs input` beats `failed`
beats `working` beats `done` beats `idle` beats `opencode`), and a `×N`
suffix shows how many matched in total. A path exactly at `$HOME` is never
used as a match anchor (in `cmd+enter o`, where a tab can sit at any
directory) - a shell sitting bare at home isn't "inside" a project, and
treating it as one would match nearly every job on the machine, since every
job's cwd is a descendant of home. This mattered in practice for a
split-pane tab where one pane happened to be parked at home.

`$WT_WORKSPACE` and `$WT_ROOT` themselves get a narrower version of the same
treatment: they're containers, not projects, so a job several directories
into one of their repos belongs to that repo, not to the container. A tab
sitting bare at `~/workspace` only picks up a job whose cwd is exactly
`~/workspace` (say, a session running there to clone something new) - not
every job running in every repo underneath it.

This reads Claude Code's own session list and OpenCode's process table,
neither of which is a versioned interface - a future update to either tool
could change its shape and quietly stop populating the column. Nothing
breaks if that happens; worktrees just stop showing that tool's glyph.

## Key bindings

| Binding | Where | Action |
| --- | --- | --- |
| `Ctrl-k w` | zsh | pick a worktree and cd into it |
| `cmd+enter w` | Kitty | pick a worktree (all repos), open or focus its tab |
| `cmd+enter r` | Kitty | pick a worktree (this repo), open or focus its tab |
| `cmd+enter c` | Kitty | prompt for a branch name and base branch, create a worktree, open a tab into it |
| `cmd+enter k` | Kitty | kill the current worktree (forced) and close this tab, after confirming |
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
- No Claude Code session or OpenCode process has its cwd at or under the
  worktree with state `working`, `blocked`, `idle`, or `opencode` - see
  [Agent status](#agent-status). `idle` counts here even though it's a
  low-priority state to *display*: an idle interactive session is still a
  live process sitting in the worktree, and deleting it out from under that
  process would be disruptive even though there's nothing urgent to show
  about it. Same reasoning for `opencode` - a running process is a running
  process, whether or not its activity can be told apart. Only a finished
  Claude Code background job (`done` or `failed`) doesn't block cleanup.

It refuses to touch the primary checkout and skips anything it can't
confidently classify (detached HEAD, no determinable base ref). Run
`wt clean --dry-run` first to see what it would remove without changing
anything, same as `wt new --dry-run`.

## Killing a worktree

`wt kill`, run from inside the worktree you want gone, is the deliberately
unsafe counterpart to `wt rm`/`wt clean` above: it never checks whether the
worktree is merged or clean, it just removes it - uncommitted changes and
all - then closes the Kitty tab it was run from, panes included. There's no
picker; it always acts on `$PWD`'s own worktree, resolved via
`git rev-parse --show-toplevel` so it works from any subdirectory, not just
the worktree root.

The only thing standing between the keypress and permanent deletion is a
typed confirmation (`Type 'yes' to continue`), unless `--force` is passed, in
which case it happens immediately with no prompt. `--force` here only skips
that prompt - it does not mean "bypass the dirty check" the way it does for
`wt rm`, because `wt kill` never has one to bypass. `--delete-branch` works
the same as it does for `wt rm`: opt-in, and off by default, so the branch
survives even though the worktree and directory don't.

It refuses to touch the primary checkout, same as `wt rm`. Outside Kitty (no
`$KITTY_WINDOW_ID` - over SSH, in tmux, in a plain terminal) it still removes
the worktree; there's just no tab to close, so it skips that part rather than
erroring.

`cmd+enter k` runs it in a Kitty overlay over the current window so the
confirmation prompt has somewhere to appear regardless of what's already
typed at the shell prompt underneath it; see
[keybindings.md](keybindings.md#kitty). See
[ADR-0006](decisions/ADR-0006-add-wt-kill-command.md) for why this is a
separate command rather than a flag on `wt rm`.

## Configuration

Read from the environment and can be set in `~/.config/zsh/local.env`:

- `WT_ROOT` — where `wt new` creates worktrees (default `~/worktrees`)
- `WT_WORKSPACE` — where repos are scanned from (default `~/workspace`)

A workspace scan only descends one level and only into directories with a real
`.git` directory, which is how a linked worktree sitting in the workspace avoids
being scanned as a repo in its own right.

## Verification

```bash
scripts/test-wt.sh
```

This drives real git inside a throwaway directory, since worktree semantics are
the thing being tested.
