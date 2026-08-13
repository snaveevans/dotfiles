---
status: "accepted"
date: 2026-08-05
decision-makers:
  - "Tyler Evans"
consulted: []
informed: []
---

# Track opencode global config in dotfiles

## Context and Problem Statement

opencode's global config lived unmanaged in `~/.config/opencode/`, split across
both `opencode.json` and `opencode.jsonc`, alongside runtime artifacts
(`node_modules/`, lockfiles, `.bak` files) and a duplicate legacy `agent/`
directory. Model choice, MCP servers, custom agents, commands, and skills had
no version history and did not sync across machines. opencode also hard-fails
on invalid config, so an untracked bad edit had no rollback path.

## Decision Drivers

- opencode separates credentials already: API keys live in
  `~/.local/share/opencode/auth.json`, keeping the config secret-free
- opencode refuses to start on invalid config, so git history is the rollback story
- the config mixes portable settings (model, MCP, agents) with machine-local
  ones (local inference providers)
- the existing symlink-first workflow already handles per-file linking with backups

## Considered Options

- Track selected files (`opencode.jsonc`, `agents/`, `command/`, `skills/`) as individual links
- Symlink the whole `~/.config/opencode/` directory
- Leave opencode config unmanaged

## Decision Outcome

Chosen option: "Track selected files", because the directory mixes managed
config with runtime artifacts and machine-specific state that must stay out of
git.

This decision means:
- `home/.config/opencode/` tracks `opencode.jsonc`, `agents/`, `command/`, and
  `skills/`; `install-home-links.sh` links each into `$HOME`
- `opencode.jsonc` is the single canonical config file; the old `opencode.json`
  and legacy `agent/` dir were consolidated into it/`agents/` and backed up
- local inference providers (omlx, Ollama) were dropped from config; they are
  machine-local and were already disabled in practice
- `plugins/`, `node_modules/`, lockfiles, and other runtime artifacts in
  `~/.config/opencode/` stay untracked
- API keys stay in `~/.local/share/opencode/auth.json` or env interpolation
  (`{env:...}`); secrets never enter the tracked config

### Consequences

- Positive: config is versioned, synced across machines, and recoverable when a bad edit breaks startup
- Negative: a broken committed config breaks opencode on every synced machine; opencode version skew across machines can reject newer config fields

## Confirmation

- `scripts/install-home-links.sh --dry-run` shows the four opencode links
- the merged `opencode.jsonc` parses with a JSONC parser before commit
- revisit if a second machine needs machine-specific providers (add an overlay like kitty's `os/`)
