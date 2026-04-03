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
- Optional future generated secret env hook at `~/.config/secrets/env`
- `scripts/install-home-links.sh` to create parent directories, dry-run installs, and back up replaced targets before linking

## Remaining slices

1. **Kitty mixed static + templated config**
   - Move safe static Kitty files into `home/.config/kitty/`.
   - Replace `kitty.conf.tmpl` with a non-templated base plus local/secret overlays.

2. **Secret projection and generated local artifacts**
   - Generate `~/.config/secrets/env` for shell-consumed secrets such as `SYNTHETIC_API_KEY`.
   - Replace `private_dot_npmrc.tmpl` with an explicit refresh flow.
   - Add the Bitwarden-backed refresh script in a later slice.

3. **Bootstrap/package install extraction**
   - Pull useful package/bootstrap knowledge out of `run_once_*` templates.
   - Keep install steps separate from day-to-day config linking.

4. **Chezmoi-specific cleanup**
   - Migrate any remaining safe plain files.
   - Remove chezmoi config and templates only after every required path has a replacement.

## Deliberately left for later

- `private_dot_npmrc.tmpl`
- `dot_config/kitty/kitty.conf.tmpl`
- `dot_config/kitty/kitty_selector.py`
- `dot_config/kitty/startup-session.conf`
- `chezmoi.toml`
- `dot_config/chezmoi/**`
- `run_once_*`
