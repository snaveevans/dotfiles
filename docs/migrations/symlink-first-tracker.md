# Symlink-first migration tracker

Migration complete: the active workflow is now plain tracked config in `home/`, setup/bootstrap scripts in `scripts/`, and current setup docs under `docs/`.

## Current workflow

Preferred clone path:

```bash
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles
```

Machine setup flow:

1. `scripts/bootstrap.sh`
2. `scripts/install-home-links.sh`
3. `bw login`
4. `scripts/refresh-secrets.sh`

## Active canonical surfaces

- `home/` for tracked home-directory config
- `scripts/bootstrap*.sh` for OS-specific machine setup
- `scripts/install-home-links.sh` for symlink installation
- `scripts/refresh-secrets.sh` for local secret artifact generation
- `docs/bootstrap.md` for setup instructions
- `docs/migrations/secret-projection.md` for the secret refresh flow

## Historical references intentionally kept

- `docs/decisions/ADR-0001-adopt-symlink-first-dotfiles-workflow-with-bitwarden-secret-projection.md`
- Git history documenting the migration path
