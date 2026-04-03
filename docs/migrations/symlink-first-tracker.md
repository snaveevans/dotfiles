# Symlink-first migration tracker

This repo now has a first-pass plain `home/` layout for a conservative set of non-templated configs. For this slice, `home/` is the intended source for the migrated paths below, while chezmoi remains in place for everything else.

## Migrated in this slice

- `~/.zshenv`
- `~/.zshrc`
- `~/.gitconfig`
- `~/.rgignore`
- `~/.hammerspoon/`
- `~/.config/nvim/`
- `~/.config/starship.toml`
- `~/.config/i3/`
- `~/.config/rofi/`
- `~/.config/polybar/`
- Optional local shell hooks at `~/.config/zsh/local.env` and `~/.config/zsh/local.zsh`
- Generated shell secret env hook at `~/.config/secrets/env`
- `scripts/refresh-secrets.sh` for explicit Bitwarden-backed secret projection
- `scripts/test-refresh-secrets.sh` for lightweight fake-Bitwarden verification of the dry-run unlock/session path
- Generated local secret artifacts:
  - `~/.config/secrets/env`
  - `~/.npmrc`
- `scripts/install-home-links.sh` to create parent directories, dry-run installs, and back up replaced targets before linking

## Remaining slices

1. **Kitty mixed static + templated config**
   - Move safe static Kitty files into `home/.config/kitty/`.
   - Replace `kitty.conf.tmpl` with a non-templated base plus local/secret overlays.

2. **Bootstrap/package install extraction**
   - Pull useful package/bootstrap knowledge out of `run_once_*` templates.
   - Keep install steps separate from day-to-day config linking.

3. **Chezmoi-specific cleanup**
   - Migrate any remaining safe plain files.
   - Remove chezmoi config and legacy templates only after every required path has a replacement.

## Deliberately left for later

- `private_dot_npmrc.tmpl`
- `dot_config/kitty/kitty.conf.tmpl`
- `dot_config/kitty/kitty_selector.py`
- `dot_config/kitty/startup-session.conf`
- `dot_zshrc.tmpl`
- `dot_zshenv.tmpl`
- `chezmoi.toml`
- `dot_config/chezmoi/**`
- `run_once_*`
