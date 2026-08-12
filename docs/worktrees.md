# Git Worktrees

`wt` lists and switches between git worktrees from the terminal, Kitty, and Neovim.

It exists because coding agents create worktrees in their own locations. Claude
Code puts them in `<repo>/.claude/worktrees/`, opencode puts them in
`~/.local/share/opencode/worktree/<repo-hash>/`, and there was no way to get
into one without copying a path out of an agent UI.

## The loop

The case this was built for: an agent is working in a worktree and you want to
be in there too, with your own editor and your own terminal.

1. Kick off work in the Claude desktop app. It creates a worktree under
   `<repo>/.claude/worktrees/`.
2. `wt` in any terminal. Pick the `claude` row — it sorts near the top, because
   rows are ordered by commit recency. Your shell is now in that worktree.
3. Work normally: `nvim`, run the tests, run the app.
4. `cmd+enter w` to jump between that worktree and the primary checkout. Each
   gets its own Kitty tab, so each keeps its own Neovim and its own shell state.
5. `wt rm` once the branch is merged. It refuses if you have uncommitted
   changes, and takes the branch with it if you pass `--delete-branch`.

For work you start yourself, `wt new tyler/CCLOUD-1234-thing` does step 1 and
leaves you in the new worktree.

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
prism-ui  main      main                                       23 hours ago
prism-ui  claude    claude/prism-component-migration-a2a0b9    28 seconds ago
prism-ui  opencode  tyler/CCLOUD-10967-badge-token-experiment  7 weeks ago
```

The second column is the origin, which is derived from where the worktree lives:

| Origin | Meaning |
| --- | --- |
| `main` | the primary checkout of the repo |
| `claude` | created by Claude Code, under `<repo>/.claude/worktrees/` |
| `opencode` | created by opencode, under `~/.local/share/opencode/worktree/` |
| `wt` | created by `wt new`, under `$WT_ROOT` |
| `other` | a worktree somewhere else, such as a hand-made sibling directory |

Rows are sorted by commit recency, so worktrees an agent just touched sort to
the top. The current repo's primary checkout is pinned first.

Dirty markers are off by default because `git status` on a large repo costs a
few hundred milliseconds per worktree, which is enough to make the picker feel
slow. Pass `-s` when you want them.

## Key bindings

| Binding | Where | Action |
| --- | --- | --- |
| `Ctrl-k w` | zsh | pick a worktree and cd into it |
| `cmd+enter w` | Kitty | pick a worktree (all repos), open or focus its tab |
| `cmd+enter r` | Kitty | pick a worktree (this repo), open or focus its tab |
| `cmd+enter c` | Kitty | prompt for a branch name, create a worktree, open a tab into it |
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

Discovery does not care about any of this. It reads `git worktree list`, so
agent-created worktrees show up wherever their tools decide to put them.

## Cleaning up

`wt clean` removes every worktree in scope (any repo owner - `wt`, `claude`,
`opencode`, `other`) that's done with, and deletes its branch along with it.
A worktree only qualifies if all three hold:

- No uncommitted changes (untracked files don't count, same as the dirty
  marker in the listing).
- Its branch is merged into the repo's default base ref (`origin`'s HEAD
  branch, or `--from REF`) - checked with `merge-base --is-ancestor`, so a
  squash-merged PR won't register as merged even though it's really done.
- No Kitty tab is currently open for it.

It refuses to touch the primary checkout and skips anything it can't
confidently classify (detached HEAD, no determinable base ref). Run
`wt clean --dry-run` first to see what it would remove without changing
anything, same as `wt new --dry-run`.

## Configuration

Both are read from the environment and can be set in `~/.config/zsh/local.env`:

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
