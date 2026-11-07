# Bootstrap flow

This repo now uses an explicit bootstrap + link + refresh flow for setup and day-to-day config changes.

## Recommended setup flow

1. Clone the repo to the preferred symlink-first path:
   ```bash
   git clone <repo-url> ~/.dotfiles
   cd ~/.dotfiles
   ```
2. Run platform bootstrap:
   ```bash
   scripts/bootstrap.sh
   ```
3. Link tracked config into your home directory:
   ```bash
   scripts/install-home-links.sh
   ```
   This also links the shared Pi keybindings. The `draft-stash`, `minimal-mode`,
   and `/openai-context` extensions are supplied by the `pi-plugins` package
   in the personal Pi settings; they are not installed as local copies.
4. Install Pi under the Node.js version pinned in `.tool-versions`:
   ```bash
   PI_NODE_VERSION="$(awk '$1 == "nodejs" { print $2; exit }' .tool-versions)"
   asdf install nodejs "$PI_NODE_VERSION"
   ASDF_NODEJS_VERSION="$PI_NODE_VERSION" asdf exec npm install --global @earendil-works/pi-coding-agent
   ```
   The linked `~/.local/bin/pi` launcher invokes this exact asdf installation,
   so project-specific Node.js versions do not hide the `pi` command.
5. Log into Bitwarden if needed:
   ```bash
   bw login
   ```
6. Generate local secret artifacts:
   ```bash
   scripts/refresh-secrets.sh
   ```
7. Provision the pi agent config for this machine's tags (reads the same
   `~/.config/secrets/tags` selection; falls back to `personal` when it
   doesn't exist yet):
   ```bash
   scripts/provision-pi.sh
   ```
8. Sync skills with skillshare (config and sources are already linked
   from `home/.config/skillshare/`):
   ```bash
   brew install skillshare
   skillshare sync
   ```
   On the first sync, adopt conflicts with `import` (keep the agent's
   entry) or `replace` (take the tracked declaration). Former MCP servers
   are gone: browser automation, docs lookup, and search now run through
   CLI skills (`chrome-devtools-cli`, `playwright-cli`, `find-docs`,
   `bx`), with API keys coming from `~/.config/secrets/env`.

## What each script does

- `scripts/bootstrap.sh`
  - dispatches to the current OS
  - installs packages and bootstrap dependencies only
- `scripts/install-home-links.sh`
  - creates parent directories as needed
  - symlinks tracked config from `home/` into `$HOME`, including OpenCode's `~/.config/opencode/opencode.jsonc`, Pi's `~/.pi/agent/keybindings.json`, and the skillshare source at `~/.config/skillshare`
  - configures OpenCode's permissions to allow tools and resources without prompts, including shell commands,
    sensitive files, and directories outside the home directory; project or agent rules and policies can override this
  - disables the `pitfalls-maintainer`, `pitfalls-reader`, `web-ui-crafter`, `bug-fixer`,
    and `conventional-commits` skills without deleting their files (`ios-rebuild-validate`
    was retired with the ios-simulator MCP removal)
  - links tracked Copilot CLI defaults to `~/.copilot/settings.json`
  - backs up an existing target before replacing it; settings are not merged
- `scripts/refresh-secrets.sh`
  - reads Bitwarden once
  - writes only local secret artifacts such as `~/.config/secrets/env` and `~/.npmrc`
  - deletes the retired MCP servers from `~/.config/muse/settings.json` when present, preserving everything else
- `scripts/provision-pi.sh`
  - links `~/.pi/agent/settings.json` and `~/.pi/agent/models.json` to the tracked per-tag files (`settings.work.json`, `models.personal.json`, ...)
  - consumes the tag selection persisted by `refresh-secrets.sh --tag`; re-run it after changing that selection

## OS-specific scripts

- `scripts/bootstrap-darwin.sh`
  - Homebrew packages/casks
  - Oh My Zsh and zsh plugin/theme setup
  - macOS defaults: input, Finder, Dock, and app tweaks, plus screenshots saved to `~/screenshots`
- `scripts/bootstrap-linux.sh`
  - apt packages and Linux tooling installs
  - Bitwarden CLI provisioning for the explicit `bw login` + `scripts/refresh-secrets.sh` flow
  - i3/rofi/polybar/font setup knowledge from the legacy bootstrap flow
  - Oh My Zsh and zsh plugin setup for the tracked zsh config

## Notes

- Bootstrap is intentionally separate from day-to-day config linking.
- Re-run `scripts/install-home-links.sh` after tracked config changes only when you need to refresh links on a machine.
- Re-run `scripts/refresh-secrets.sh` when Bitwarden-backed values change.
