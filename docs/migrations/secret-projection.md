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

## Generated artifacts

- `~/.config/secrets/env`
  - sourced by `home/.zshenv`
  - currently exports:
    - `BRAVE_API_KEY`
    - `CONTEXT7_API_KEY`
- `~/.npmrc`
  - generated replacement for the old `private_dot_npmrc.tmpl`

Generated files are written with restrictive permissions and are not tracked in the repo.

## Expected Bitwarden entries

Defaults come from the current repo's existing template usage:

- Brave Search API key
  - item: `api-dashboard.search.brave.com`
  - field: `api_key`
- Context7 API key
  - item: `context7`
  - field: `notes`
- GitHub Packages npm token
  - item: `ebac9653-5fbd-4dac-b22d-af9a0116b6bb`
  - field: `access_token`
- Artifactory npm auth
  - item: `artifactory.octanner.net`
  - fields:
    - `email`
    - `access_token`

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
- `BW_ITEM_GITHUB_PACKAGES`
- `BW_FIELD_GITHUB_PACKAGES_TOKEN`
- `BW_ITEM_ARTIFACTORY`
- `BW_FIELD_ARTIFACTORY_EMAIL`
- `BW_FIELD_ARTIFACTORY_TOKEN`

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

It uses a temporary fake `bw` binary, runs `scripts/refresh-secrets.sh --dry-run`, verifies the expected unlock/session calls, and confirms that no secret files are written during the test.
