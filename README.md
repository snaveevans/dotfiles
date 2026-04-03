# dotfiles

Personal dotfiles for a symlink-first workflow on macOS and Linux.

This repo keeps tracked config in `home/`, machine bootstrap scripts in `scripts/`, and secrets out of git. Instead of templating dotfiles directly, setup is split into three explicit steps:

1. bootstrap the machine
2. symlink tracked config into `$HOME`
3. refresh local secret artifacts from Bitwarden

## What This Repo Manages

- shell config: `home/.zshenv`, `home/.zshrc`
- editor config: `home/.config/nvim`
- terminal config: `home/.config/kitty`
- Linux desktop config: `home/.config/i3`, `home/.config/polybar`, `home/.config/rofi`
- macOS automation: `home/.hammerspoon`
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
scripts/refresh-secrets.sh
```

## Script Overview

- `scripts/bootstrap.sh`: dispatches to the current OS bootstrap flow
- `scripts/bootstrap-darwin.sh`: installs macOS packages, shell dependencies, and defaults
- `scripts/bootstrap-linux.sh`: installs Linux packages, desktop tooling, fonts, and Bitwarden CLI
- `scripts/install-home-links.sh`: symlinks tracked files from `home/` into `$HOME`
- `scripts/refresh-secrets.sh`: writes local secret files such as `~/.config/secrets/env` and `~/.npmrc`
- `scripts/test-refresh-secrets.sh`: fake-Bitwarden verification for the secret refresh flow

## Secrets

Secrets are not committed to this repo.

- Bitwarden is the source of truth for sensitive values.
- `scripts/refresh-secrets.sh` writes only local generated artifacts.
- generated secret outputs like `.npmrc` and `.config/secrets/` are gitignored.

See `docs/migrations/secret-projection.md` for the current secret flow.

## Day-To-Day Workflow

Edit tracked files directly in `home/` and rerun `scripts/install-home-links.sh` when you need to refresh links on a machine.

Re-run `scripts/refresh-secrets.sh` when Bitwarden-backed values change.

## Platform Notes

- macOS uses the Darwin bootstrap script and Hammerspoon config in `home/.hammerspoon/`.
- Linux uses the Linux bootstrap script plus i3, Polybar, and Rofi config under `home/.config/`.

For Linux-specific setup details, see `UBUNTU_SETUP.md`.

## Additional Docs

- `docs/bootstrap.md`: bootstrap, linking, and refresh flow
- `docs/troubleshooting.md`: common recovery steps, including Neovim parser crash fixes
- `docs/migrations/secret-projection.md`: Bitwarden-backed secret generation
- `docs/migrations/symlink-first-tracker.md`: migration summary and active surfaces
- `docs/decisions/ADR-0001-adopt-symlink-first-dotfiles-workflow-with-bitwarden-secret-projection.md`: architecture decision for the current workflow
