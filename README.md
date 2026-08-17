# dotfiles

Personal dotfiles for a symlink-first workflow on macOS and Linux.

This repo keeps tracked config in `home/`, machine bootstrap scripts in `scripts/`, and secrets out of git. Instead of templating dotfiles directly, setup is split into three explicit steps:

1. bootstrap the machine
2. symlink tracked config into `$HOME`
3. refresh local secret artifacts from Bitwarden

## What This Repo Manages

- shell config: `home/.zshenv`, `home/.zshrc`
- personal commands: `home/.local/bin`
- editor config: `home/.config/nvim`
- terminal config: `home/.config/kitty`
- Linux desktop config: `home/.config/i3`, `home/.config/polybar`, `home/.config/rofi`
- macOS automation: `home/.hammerspoon`
- Pi agent config: `home/.pi/agent/models.json` (wires the [Synthetic](https://dev.synthetic.new) provider) and `home/.pi/agent/settings.json` (default model and thinking level)
- bootstrap and install scripts in `scripts/`

## Repo Layout

```text
home/      tracked files that should live under $HOME
scripts/   bootstrap, linking, and secret refresh scripts
docs/      setup docs, migration notes, and ADRs
```

## Quick Start

Clone into the expected path:

```bash
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles
```

Bootstrap the machine:

```bash
scripts/bootstrap.sh
```

Link tracked config into your home directory:

```bash
scripts/install-home-links.sh
```

Log into Bitwarden if needed, then generate local secret artifacts:

```bash
bw login
scripts/refresh-secrets.sh --tag work --tag personal  # pick tags matching this machine
```

## Script Overview

- `scripts/bootstrap.sh`: dispatches to the current OS bootstrap flow
- `scripts/bootstrap-darwin.sh`: installs macOS packages, shell dependencies, and defaults
- `scripts/bootstrap-linux.sh`: installs Linux packages, desktop tooling, fonts, and Bitwarden CLI
- `scripts/install-home-links.sh`: symlinks tracked files from `home/` into `$HOME`
- `scripts/refresh-secrets.sh`: writes local secret files such as `~/.config/secrets/env` and `~/.npmrc`, scoped by `--tag work` / `--tag personal`
- `scripts/test-refresh-secrets.sh`: fake-Bitwarden verification for the secret refresh flow
- `scripts/test-wt.sh`: real-git verification for the `wt` worktree command

## Git Worktrees

`wt` lists and switches between git worktrees, including the ones Claude Code and
opencode create in their own locations. It is linked into `~/.local/bin` by
`scripts/install-home-links.sh`.

```bash
wt          # pick a worktree and cd into it
wt list     # print the worktrees in scope
wt new BRANCH
```

Key bindings: `Ctrl-k w` in zsh, `cmd+enter w` in Kitty, `<leader>gw` in Neovim.
`wt --help` repeats them. See `docs/worktrees.md` for the full flow and
`docs/keybindings.md` for every custom binding in this repo.

## Secrets

Secrets are not committed to this repo.

- Bitwarden is the source of truth for sensitive values.
- `scripts/refresh-secrets.sh` writes only local generated artifacts.
- generated secret outputs like `.npmrc` and `.config/secrets/` are gitignored.

See `docs/migrations/secret-projection.md` for the current secret flow.

## Day-To-Day Workflow

Edit tracked files directly in `home/` and rerun `scripts/install-home-links.sh` when you need to refresh links on a machine.

Re-run `scripts/refresh-secrets.sh` when Bitwarden-backed values change (your tag selection from the first tagged run is remembered in `~/.config/secrets/tags`).

## Platform Notes

- macOS uses the Darwin bootstrap script and Hammerspoon config in `home/.hammerspoon/`.
- Linux uses the Linux bootstrap script plus i3, Polybar, and Rofi config under `home/.config/`.

For Linux-specific setup details, see `UBUNTU_SETUP.md`.

## Additional Docs

- `docs/bootstrap.md`: bootstrap, linking, and refresh flow
- `docs/keybindings.md`: every custom zsh, Kitty, Neovim, and Hammerspoon binding
- `docs/troubleshooting.md`: common recovery steps, including Neovim parser crash fixes
- `docs/worktrees.md`: the `wt` worktree command and its Kitty and Neovim pickers
- `docs/migrations/secret-projection.md`: Bitwarden-backed secret generation
- `docs/migrations/symlink-first-tracker.md`: migration summary and active surfaces
- `docs/decisions/ADR-0001-adopt-symlink-first-dotfiles-workflow-with-bitwarden-secret-projection.md`: architecture decision for the current workflow
- `docs/decisions/ADR-0002-centralize-hand-made-git-worktrees-with-location-agnostic-discovery.md`: architecture decision for the worktree layout
- `docs/decisions/ADR-0007-tag-scoped-secret-projection.md`: architecture decision for scoping secrets by work/personal tags
