# Bootstrap flow

This repo now uses an explicit bootstrap + link + refresh flow instead of relying on `chezmoi apply` for normal setup.

## Recommended setup flow

1. Clone the repo.
2. Run platform bootstrap:
   ```bash
   scripts/bootstrap.sh
   ```
3. Link tracked config into your home directory:
   ```bash
   scripts/install-home-links.sh
   ```
4. Log into Bitwarden if needed:
   ```bash
   bw login
   ```
5. Generate local secret artifacts:
   ```bash
   scripts/refresh-secrets.sh
   ```

## What each script does

- `scripts/bootstrap.sh`
  - dispatches to the current OS
  - installs packages and bootstrap dependencies only
- `scripts/install-home-links.sh`
  - creates parent directories as needed
  - symlinks tracked config from `home/` into `$HOME`
- `scripts/refresh-secrets.sh`
  - reads Bitwarden once
  - writes only local secret artifacts such as `~/.config/secrets/env` and `~/.npmrc`

## OS-specific scripts

- `scripts/bootstrap-darwin.sh`
  - Homebrew packages/casks
  - Oh My Zsh and zsh plugin/theme setup
  - macOS defaults and Dock tweaks
- `scripts/bootstrap-linux.sh`
  - apt packages and Linux tooling installs
  - Bitwarden CLI provisioning for the explicit `bw login` + `scripts/refresh-secrets.sh` flow
  - i3/rofi/polybar/font setup knowledge from the old chezmoi flow
  - Oh My Zsh and zsh plugin setup for the tracked zsh config

## Notes

- Bootstrap is intentionally separate from day-to-day config linking.
- Re-run `scripts/install-home-links.sh` after tracked config changes only when you need to refresh links on a machine.
- Re-run `scripts/refresh-secrets.sh` when Bitwarden-backed values change.
