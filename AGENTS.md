# AGENTS Guide

This repo is a personal dotfiles repo with a symlink-first workflow.

The source of truth is the repo itself:
- tracked home-directory files live under `home/`
- setup and secret workflows live under `scripts/`
- supporting docs and decisions live under `docs/`

Do not edit files in `$HOME` directly.
Edit the matching file under `home/`, then validate with repo-local commands.

## Rule Files

As of the current repo state, none of these files exist:
- `.cursor/rules/`
- `.cursorrules`
- `.github/copilot-instructions.md`

If any are added later, follow them in addition to this file.

## Build / Lint / Test Commands

There is no monolithic `build` target in this repo.
Validation is file-type-specific.

Common commands:

```bash
# Show repo state
git status --short --branch

# Format Lua config
stylua home/.config/nvim home/.hammerspoon

# Format one Lua file
stylua home/.config/nvim/lua/config/keymaps.lua

# Syntax-check one shell script
bash -n scripts/refresh-secrets.sh

# Syntax-check all main shell scripts
bash -n scripts/{bootstrap,bootstrap-darwin,bootstrap-linux,install-home-links,refresh-secrets,test-refresh-secrets}.sh

# Shell lint/format when available locally
shellcheck scripts/*.sh home/.config/polybar/launch.sh
shfmt -w scripts/*.sh home/.config/polybar/launch.sh

# Python syntax-check the Kitty kitten
python3 -m py_compile home/.config/kitty/kitty_selector.py

# Safe link-install validation
scripts/install-home-links.sh --dry-run
scripts/install-home-links.sh --dry-run --home "$(mktemp -d)"

# Secret refresh validation
scripts/refresh-secrets.sh --dry-run
scripts/test-refresh-secrets.sh
```

## Single-Test Guidance

There is currently one explicit automated test script: `scripts/test-refresh-secrets.sh`

Use the narrowest check for the file type you changed:
- secret refresh logic: `scripts/test-refresh-secrets.sh`
- link-install behavior: `scripts/install-home-links.sh --dry-run --home "$(mktemp -d)"`
- one shell file: `bash -n path/to/file.sh`
- one Lua file: `stylua path/to/file.lua`
- one Python file: `python3 -m py_compile path/to/file.py`

Do not run `scripts/bootstrap.sh`, `scripts/bootstrap-darwin.sh`, or `scripts/bootstrap-linux.sh` as routine validation unless the user asks. They install packages and mutate the machine.

## Source-Of-Truth Rules

- Edit `home/...`, not the linked destination in `$HOME`.
- Edit tracked Kitty config in `home/.config/kitty/` and let `install-home-links.sh` manage runtime links.
- Edit docs in `docs/` when changing setup or migration behavior.
- Do not commit `.npmrc`, `.config/secrets/`, or real credentials.
- If you change setup or secret generation, review `docs/bootstrap.md` and `docs/migrations/secret-projection.md`.

## Shell Style

Shell scripts are Bash.

Follow these patterns:
- use `#!/usr/bin/env bash`
- use `set -euo pipefail`
- use `umask 077` when writing secret-bearing files
- prefer `local` variables inside functions
- use `[[ ... ]]` instead of `[` for tests
- quote variable expansions unless word splitting is intentional
- prefer `case` over long `if/elif` chains for option parsing or OS branching
- use small helper functions like `log`, `die`, `usage`, `require_cmd`
- prefer early returns and explicit failures over deeply nested logic

Naming in shell:
- uppercase for exported environment variables and script constants: `TARGET_HOME`, `BW_SESSION_VALUE`
- lower_snake_case for functions: `install_oh_my_zsh`, `assert_safe_target_home`

Shell error handling:
- fail fast with clear messages via `die`
- keep scripts idempotent where practical
- use dry-run flags for risky flows when possible
- write files atomically with temp files when replacing sensitive outputs

## Lua Style

Lua config is primarily Neovim and Hammerspoon code.

Formatting:
- use 2-space indentation
- `home/.config/nvim/stylua.toml` sets `column_width = 120`
- run `stylua` after non-trivial Lua edits

Structure:
- keep `require(...)` calls near the top of the file or function that needs them
- return plugin specs as plain Lua tables
- use `local M = {}` for utility modules
- preserve the existing LazyVim plugin-spec shape in `home/.config/nvim/lua/plugins/`

Naming in Lua:
- prefer `snake_case` for locals and helper functions in Neovim config
- preserve framework-driven names where they already exist in Hammerspoon code

Lua error handling:
- guard environment-specific behavior, especially `vim.g.vscode`
- when shelling out from Neovim, check `vim.v.shell_error` if the result matters
- prefer graceful no-op behavior for optional integrations

## Python Style

There is currently one Python file: `home/.config/kitty/kitty_selector.py`.

Follow the existing local style:
- 4-space indentation
- keep imports at the top
- use type hints when touching function signatures
- pass argument lists to `subprocess.run` instead of shell strings when possible
- keep functions small and task-specific
- return simple dictionaries for Kitty kitten result payloads

Python error handling:
- catch exceptions only around fallback behavior or API boundaries
- prefer explicit error results over broad hidden failures

## Formatting, Comments, And Secrets

- match the formatting already used in the file you are editing
- do not reformat unrelated sections just because a formatter would
- keep comments short and rationale-focused
- never add real tokens, API keys, or credentials to tracked files
- keep test values obviously fake, like `fake-session-token` or `user@example.com`
- preserve safety checks that prevent writing secrets inside the repo tree

## Before Finishing A Change

Pick the narrowest relevant checks:
- run `stylua` for Lua edits
- run `bash -n` for changed shell scripts
- run `python3 -m py_compile` for Python edits
- run `scripts/test-refresh-secrets.sh` for secret refresh changes
- run `scripts/install-home-links.sh --dry-run` for link-install changes

If you changed user-visible setup behavior, update the README or docs in the same change.
