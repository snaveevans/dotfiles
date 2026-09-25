---
status: "accepted"
date: 2026-08-17
decision-makers:
  - "Tyler"
consulted: []
informed: []
---

# Tag-scoped pi agent config via symlink swap

## Context and Problem Statement

The same work/personal split applied to secrets in ADR-0007 applies to pi
agent config: personally, pi runs against Synthetic models; at work it runs
against GitHub Copilot, while extensions, themes, and behavior settings are
meant to stay identical. The tracked `home/.pi/agent/settings.json` and
`models.json` were symlinked straight into `~/.pi/agent/`, so both machines
had to run the same providers or one of them maintained uncommitted
divergence forever.

Unlike secrets, this cannot reuse the projection approach from
`refresh-secrets.sh`: pi *writes back* into `~/.pi/agent/settings.json`
(user `/settings` toggles, `lastChangelogVersion` bumps), so generating the
file would either clobber pi's own state on re-run or require fragile
deep-merge preservation. Pi also offers no global-settings layering of its
own - project `.pi/settings.json` is the only override level - and reads
exactly one filename each: `settings.json` and `models.json`.

GitHub Copilot needs no vault plumbing at all: it is a built-in pi provider,
authenticated via OAuth `/login`, with credentials kept in the untracked
`~/.pi/agent/auth.json`.

## Decision Drivers

- Pi-managed writes must land somewhere safe - the file pi writes cannot be
  regenerated from templates on every provision run.
- The mechanism should stay in the repo's symlink-first spirit: read the
  answer directly off the filesystem, no generated artifacts.
- Shared-vs-different concern ordering: plugins/extensions identical
  everywhere; providers/models differ.
- Simplicity today beats scalability the owner does not (yet) need.

## Considered Options

- Per-tag full files (`settings.<tag>.json`, `models.<tag>.json`) symlinked
  into place (`~/.pi/agent/settings.json` -> `settings.work.json`), with
  work winning when both tags are selected.
- A shared base plus per-tag overlays merged by a provisioning script into
  a generated `settings.json`, preserving pi-written keys.
- Tag-filtered `models.json` only, leaving settings global.

## Decision Outcome

Chosen option: "Per-tag full files symlinked into place", because a
symlink means pi's writes flow straight back into the tracked per-tag file
- there is no merge to preserve across re-runs, no generated artifact to
drift, and `git status` immediately shows any change pi itself made.

This decision means:

- `home/.pi/agent/settings.personal.json` (Synthetic), `settings.work.json`
  (GitHub Copilot: `defaultProvider: github-copilot`, model pinned later),
  plus matching `models.personal.json` / `models.work.json`. The work
  models file starts as an empty `{"providers": {}}` placeholder; an empty
  `providers` map makes pi fall back to built-ins.
- `scripts/provision-pi.sh` resolves the machine tag (explicit `--tag`,
  else the `~/.config/secrets/tags` selection persisted by
  `refresh-secrets.sh`, else `personal` as the historical default; `work`
  wins on overlap) and points the two symlinks accordingly. It refuses to
  overwrite a real non-symlink file, since that would be pi-managed state.
- `scripts/install-home-links.sh` no longer links `settings.json` or
  `models.json`; it continues linking the tracked extension.
- Shared content duplicated between the two settings files (theme,
  packages, `hideThinkingBlock`) is an accepted tradeoff: two files is not
  a scale problem, and both stay reviewable in one diff.

### Consequences

- Positive: provisioning is idempotent, trivially testable, and switching
  tags is one command with no state to rebuild.
- Positive: pi's own writes (changelog markers, toggles) become visible
  working-tree changes per tag instead of being silently regenerated away.
- Negative: any new shared key must be mirrored in each settings.<tag>.json
  by hand; nothing enforces the duplication beyond review.
- Negative: if a third context ever appears (or a per-project provider),
  this one-tag-wins model needs revisiting - explicitly deferred.

## Confirmation

- `scripts/test-provision-pi.sh` covers tag selection order, both-tags-wins
  for work, idempotent re-runs, re-pointing, refusal on real files, unknown
  tags, and dry-run.
- `scripts/install-home-links.sh --dry-run` confirms only the extension is
  still linked by the linker.
