---
status: "accepted"
date: 2026-08-17
decision-makers:
  - "Tyler"
consulted: []
informed: []
---

# Tag-scoped secret projection

## Context and Problem Statement

`scripts/refresh-secrets.sh` projected every Bitwarden-backed secret onto
every machine: API keys that are only ever used personally (Synthetic,
Cloudflare) sat in the shell environment of a work machine, and work
credentials (Artifactory, the GitHub Packages work token) sat on personal
machines. The byte count is trivial, but secrets materialize into
`~/.config/secrets/env`, so anything not needed on a machine is pure
exposure with no justification.

The split is not per-item binary either: Brave Search and Context7 apply to
both work and personal use, and GitHub Packages now carries two tokens on
one vault item - `work_access_token` and `personal_access_token` - because
both contexts push and pull packages.

## Decision Drivers

- Secrets that are not needed on a machine should not exist on that machine.
- The classification must live with the item, not with a machine profile
  that has to be kept in sync with the item list.
- Running the refresh command must stay a one-command operation; a machine
  should not have to restate its identity every time.
- Behavior for a fresh machine that has never chosen tags must be exactly
  the historical behavior.

## Considered Options

- Tag each item with a list (`work`, `personal`, or both) and let
  `--tag` select which items to project.
- A per-machine profile file (`personal` / `work` / `both`) with each item
  carrying a single scope, resolved through the profile.
- Separate env files per scope (`env.work`, `env.personal`) with the shell
  sourcing the right ones.

## Decision Outcome

Chosen option: "Tag each item with a list and let `--tag` select", because
the tag list is the only model that expresses the real relationship - an
item can belong to several contexts at once - without inventing a `both`
scope that drifts from the tags it stands for.

This decision means:

- Each item in `refresh-secrets.sh` declares its tags inline
  (`BRAVE_TAGS="work personal"`, `SYNTHETIC_TAGS="personal"`, ...). An item
  is projected when any of its tags is requested. With no tag filter,
  everything is projected - the historical behavior, kept as the default.
- `refresh-secrets.sh --tag work` (repeatable) limits the run to matching
  items: only those secrets are read from the vault and written into
  `~/.config/secrets/env`, and work-only artifacts (`~/.gradle/
  gradle.properties`, `~/.m2/settings.xml`, the Artifactory and `@octanner`
  blocks of `~/.npmrc`) are skipped entirely when `work` is not selected.
- The first explicitly tagged run persists the selection to the untracked,
  non-secret `~/.config/secrets/tags`; a later tag-less run on that machine
  reuses it, so refreshing is still one command and the selection can no
  longer be accidentally widened by forgetting a flag.
- GitHub Packages reads `work_access_token` into `GITHUB_PACKAGES_TOKEN`
  (work tag) and `personal_access_token` into
  `GITHUB_PACKAGES_PERSONAL_TOKEN` (personal tag) from the same vault item.
  `~/.npmrc` authenticates `npm.pkg.github.com` with the work token when
  the work tag is present (it must reach the `@octanner` scope) and with
  the personal token otherwise.
- The old `access_token` field on the GitHub Packages item is retired as a
  default; it remains override-able during the transition via
  `BW_FIELD_GITHUB_PACKAGES_TOKEN` if some machine still needs it.

### Consequences

- Positive: a personal machine provably holds no Artifactory or work GitHub
  Packages material, and the classification is auditable by reading one
  short block of tag declarations in the script.
- Positive: adding a new secret is a one-line tag decision, visible in code
  review.
- Negative: the persisted `~/.config/secrets/tags` file is state the
  machine remembers; changing a machine's role means passing `--tag`
  explicitly to overwrite it, which the usage text and docs must make
  clear.
- Negative: another unversioned local contract (the tags file, like the
  env file itself) that a future shape change has to keep in mind.

## Confirmation

- `scripts/test-refresh-secrets.sh` exercises tag-less, `--tag work`,
  `--tag personal`, persisted-selection, and unknown-tag scenarios against
  a fake `bw`.
