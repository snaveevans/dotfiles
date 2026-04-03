---
status: "proposed"
date: 2026-04-02
decision-makers:
  - Tyler
consulted: []
informed: []
---

# Adopt a symlink-first dotfiles workflow with Bitwarden-backed secret projection

## Context and Problem Statement
This repo currently uses chezmoi templates and Bitwarden integration to manage dotfiles. The desired workflow is a faster edit/reload/test/commit loop for frequently changed configuration such as Neovim, shell, terminal, and other general user config.

The main friction in the current setup is repeated Bitwarden unlock prompting plus the extra edit-to-apply cycle before confirming whether a config change works. Machine-specific settings and secret handling still matter, but the historical pain there was only moderate and does not justify carrying a larger management system than necessary.

## Decision Drivers
- Preserve zero-friction inner loop for config iteration.
- Minimize secret-management friction and repeated unlock prompts.
- Keep Bitwarden as the single source of truth for sensitive data.
- Support machine-specific differences without templating the whole repo.
- Prefer the smallest system that solves the actual problem.

## Considered Options
- Keep full chezmoi-managed dotfiles with templating and Bitwarden integration.
- Hybrid approach: use chezmoi only for secrets/bootstrap and symlink/live-edit for active config.
- Symlink-first dotfiles with a tiny Bitwarden-backed secret projection layer.

## Decision Outcome
Chosen option: "Symlink-first dotfiles with a tiny Bitwarden-backed secret projection layer", because it best preserves a live-editable inner loop while keeping Bitwarden authoritative for sensitive data and limiting the solution to one explicit refresh step plus a few generated local artifacts.

This decision means:
- The dotfiles repo will contain plain, live-editable config for fast-changing files such as Neovim, `zshrc`, Kitty, and other general config.
- Machine-specific non-secret config will live in local override files or hostname/work/personal includes instead of templating the whole repo.
- Bitwarden will remain the source of truth for sensitive values.
- One small explicit refresh-secrets command will pull from Bitwarden and generate only the local artifacts tools actually need, including a sourced env file for shell-friendly scalar secrets and generated file-native secrets such as `.npmrc` when required.
- The system will stay intentionally minimal rather than rebuilding chezmoi or introducing a larger custom framework.

### Consequences
- Positive: Frequently changed config can be edited directly in the repo and reloaded immediately without a chezmoi apply cycle.
- Positive: Secret handling stays centralized in Bitwarden while local generated artifacts are limited to the formats specific tools actually consume.
- Positive: Machine-specific differences stay supported without forcing full-repo templating.
- Negative: Secret-backed local artifacts must be refreshed explicitly when Bitwarden values change.
- Negative: Some bootstrap and local-environment behavior becomes an intentional convention around the refresh step instead of coming from a pre-existing framework.
- Negative: Generated secret artifacts must remain untracked and clearly documented to avoid accidental commits.

## Confirmation
- Confirm `docs/decisions/adr-template.md` exists so future decisions can follow the same ADR structure.
- Confirm this ADR is numbered `ADR-0001` because no prior `ADR-####-*` files exist under `docs/decisions`.
- In follow-up implementation work, verify the active config loop remains direct edit/reload/test/commit and that one explicit secret refresh step produces only the local artifacts required by consuming tools.
