# Secret projection flow

The symlink-first setup keeps tracked config plain and live-editable. Secrets are now refreshed explicitly with one command instead of being injected into tracked config files.

## Command

```bash
scripts/refresh-secrets.sh
```

This command:

- requires `bw` and `jq`
- reuses `BW_SESSION` if already set
- otherwise unlocks Bitwarden once for the run
- syncs the vault before reading by default
- writes only the local artifacts current consumers need
- refuses to target a `--home` path inside the repo root unless you explicitly pass `--allow-unsafe-home-in-repo`

## Tags

Every item carries a tag list declaring which environments it belongs to,
and `--tag` (repeatable) projects only matching items - see
[ADR-0007](../decisions/ADR-0007-tag-scoped-secret-projection.md). Known
tags are `work` and `personal`.

| Item | Exports | Tags |
| --- | --- | --- |
| Brave Search | `BRAVE_API_KEY` | `work`, `personal` |
| Context7 | `CONTEXT7_API_KEY` | `work`, `personal` |
| Synthetic | `SYNTHETIC_API_KEY` | `personal` |
| GitHub Packages | `GITHUB_PACKAGES_TOKEN` (`work_access_token`), `GITHUB_PACKAGES_PERSONAL_TOKEN` (`personal_access_token`) | `work`, `personal` |
| Artifactory | feeds `~/.npmrc`, `gradle.properties`, `settings.xml` only - no env exports | `work` |
| Cloudflare | `CLOUDFLARE_ACCOUNT_ID`, `CLOUDFLARE_API_TOKEN` | `personal` |

```bash
scripts/refresh-secrets.sh --tag work                # work-only machine
scripts/refresh-secrets.sh --tag work --tag personal # machine that is both
```

With no `--tag` and no persisted selection, every item is projected (the
historical behavior). The first run with explicit `--tag` flags writes them
to the untracked, non-secret `~/.config/secrets/tags`, and later tag-less
runs on that machine reuse them - so refreshing stays one command and the
selection can't be silently widened by forgetting a flag. Change a
machine's role by running again with the new explicit tags.

Tag filtering applies to artifacts as well as env vars: a `personal`-only
run skips the Artifactory blocks of `~/.npmrc` and the Gradle/Maven files
entirely.

## Generated artifacts

- `~/.config/secrets/env`
  - sourced by `home/.zshenv`
  - currently exports:
    - `BRAVE_API_KEY`
    - `CONTEXT7_API_KEY`
    - `SYNTHETIC_API_KEY` (referenced by `home/.pi/agent/models.json` as `$SYNTHETIC_API_KEY` for Pi's Synthetic provider)
    - `GITHUB_PACKAGES_TOKEN` (not `GITHUB_TOKEN` — that name is reserved by `gh`/GitHub Actions and would override CLI auth)
    - `CLOUDFLARE_ACCOUNT_ID`
    - `CLOUDFLARE_API_TOKEN`
- `~/.config/secrets/tags`
  - untracked, non-secret record of the explicit `--tag` selection from the most recent tagged run
  - read back by later tag-less runs on the same machine
- `~/.npmrc`
  - generated replacement for the old `private_dot_npmrc.tmpl`
  - GitHub Packages `_authToken` references `${GITHUB_PACKAGES_TOKEN}` from the env file (work tag) or `${GITHUB_PACKAGES_PERSONAL_TOKEN}` (personal tag only); npm expands it at runtime
  - the `@octanner` GitHub Packages scope and the Artifactory block appear only when the `work` tag is selected
- `~/.gradle/gradle.properties`
  - provides `centralUsername` and `centralPassword` for Gradle Artifactory authentication
  - uses the same Bitwarden item as the npmrc Artifactory block (`artifactory.octanner.net`)
  - `centralUsername` is derived from the `email` field (everything before `@`)
  - `centralPassword` comes from the `encrypted_password` field
  - `gradle.properties` is a Java Properties file and does not support env var interpolation, so values are written literally
- `~/.m2/settings.xml`
  - provides Maven server credentials for the `central` server id
  - uses the same derived username and `encrypted_password` as the Gradle properties file
  - overwrites the entire file; if you have other Maven server entries, they must be managed separately

Generated files are written with restrictive permissions and are not tracked in the repo.

## Expected Bitwarden entries

Defaults come from the current repo's existing template usage:

- Brave Search API key
  - item: `api-dashboard.search.brave.com`
  - field: `api_key`
- Context7 API key
  - item: `context7`
  - field: `api_key`
- Synthetic API key
  - item: `synthetic.new`
  - field: `api_key`
- GitHub Packages npm tokens
  - item: `ebac9653-5fbd-4dac-b22d-af9a0116b6bb`
  - fields:
    - `work_access_token` -> `GITHUB_PACKAGES_TOKEN` (work tag)
    - `personal_access_token` -> `GITHUB_PACKAGES_PERSONAL_TOKEN` (personal tag)
- Artifactory npm auth
  - item: `artifactory.octanner.net`
  - fields:
    - `email`
    - `access_token`
    - `encrypted_password`
- Cloudflare
  - item: `cloudflare.com`
  - fields:
    - `account_id`
    - `github_actions_token`

If your Bitwarden items differ, override the defaults for a run with environment variables before invoking the script:

```bash
BW_ITEM_BRAVE="my-brave-item" \
BW_FIELD_BRAVE_API_KEY="api_key" \
scripts/refresh-secrets.sh
```

Supported overrides:

- `BW_ITEM_BRAVE`
- `BW_FIELD_BRAVE_API_KEY`
- `BW_ITEM_CONTEXT7`
- `BW_FIELD_CONTEXT7_API_KEY`
- `BW_ITEM_SYNTHETIC`
- `BW_FIELD_SYNTHETIC_API_KEY`
- `BW_ITEM_GITHUB_PACKAGES`
- `BW_FIELD_GITHUB_PACKAGES_WORK_TOKEN` (the old `BW_FIELD_GITHUB_PACKAGES_TOKEN` override still maps here, but the default field is now `work_access_token`, not `access_token`)
- `BW_FIELD_GITHUB_PACKAGES_PERSONAL_TOKEN`
- `BW_ITEM_ARTIFACTORY`
- `BW_FIELD_ARTIFACTORY_EMAIL`
- `BW_FIELD_ARTIFACTORY_TOKEN`
- `BW_FIELD_ARTIFACTORY_ENCRYPTED_PASSWORD`
- `BW_ITEM_CLOUDFLARE`
- `BW_FIELD_CLOUDFLARE_ACCOUNT_ID`
- `BW_FIELD_CLOUDFLARE_API_TOKEN`

## Notes

- Run `bw login` first if the CLI is not authenticated yet.
- Use `scripts/refresh-secrets.sh --help` for options.
- Use `scripts/refresh-secrets.sh --dry-run` to validate reads without writing files.

## Safety notes

- By default, `scripts/refresh-secrets.sh --home ...` refuses to target a home directory inside the repo tree.
- If you really intend to write generated secret artifacts under a repo-contained path, you must opt in explicitly with `--allow-unsafe-home-in-repo`.

## Lightweight verification

Run this minimal fake-Bitwarden verification to exercise the no-`BW_SESSION` unlock path without real vault access:

```bash
scripts/test-refresh-secrets.sh
```

It uses a temporary fake `bw` binary and exercises the full matrix: a
dry-run verifying unlock/session calls, a tag-less run projecting
everything, `--tag work` and `--tag personal` runs asserting exactly which
exports and artifacts each produces, tag-selection persistence, and
rejection of unknown tags.
