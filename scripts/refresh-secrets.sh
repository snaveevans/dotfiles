#!/usr/bin/env bash

set -euo pipefail
umask 077

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_HOME="${HOME}"
DRY_RUN=false
SYNC_BEFORE_READ=true
ALLOW_UNSAFE_HOME_IN_REPO=false
BW_SESSION_VALUE="${BW_SESSION:-}"

SYNTHETIC_ITEM="${BW_ITEM_SYNTHETIC:-synthetic.new}"
SYNTHETIC_FIELD="${BW_FIELD_SYNTHETIC_API_KEY:-token}"

GITHUB_PACKAGES_ITEM="${BW_ITEM_GITHUB_PACKAGES:-ebac9653-5fbd-4dac-b22d-af9a0116b6bb}"
GITHUB_PACKAGES_FIELD="${BW_FIELD_GITHUB_PACKAGES_TOKEN:-access_token}"

ARTIFACTORY_ITEM="${BW_ITEM_ARTIFACTORY:-artifactory.octanner.net}"
ARTIFACTORY_EMAIL_FIELD="${BW_FIELD_ARTIFACTORY_EMAIL:-email}"
ARTIFACTORY_TOKEN_FIELD="${BW_FIELD_ARTIFACTORY_TOKEN:-access_token}"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '%s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: scripts/refresh-secrets.sh [options]

Refresh local secret artifacts from Bitwarden.

Generated artifacts:
  ~/.config/secrets/env
  ~/.npmrc

Options:
  --dry-run   Resolve secrets but do not write files
  --home DIR  Generate artifacts under DIR instead of $HOME
  --no-sync   Skip 'bw sync' before reads
  --allow-unsafe-home-in-repo
              Allow writing under a home path located inside the repo root
  --help      Show this help message

Bitwarden item/field references can be overridden with environment variables.
See docs/migrations/secret-projection.md for the expected defaults.
EOF
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

resolve_path() {
  local path="$1"
  local parent
  local name

  if [[ -d "$path" ]]; then
    (
      cd "$path"
      pwd -P
    )
    return 0
  fi

  if [[ -e "$path" ]]; then
    parent="$(dirname "$path")"
    name="$(basename "$path")"
    printf '%s/%s\n' "$(resolve_path "$parent")" "$name"
    return 0
  fi

  parent="$(dirname "$path")"
  name="$(basename "$path")"

  [[ "$parent" != "$path" ]] || die "Unable to resolve path: $path"
  printf '%s/%s\n' "$(resolve_path "$parent")" "$name"
}

assert_safe_target_home() {
  local resolved_target_home
  local resolved_repo_root

  resolved_target_home="$(resolve_path "$TARGET_HOME")"
  resolved_repo_root="$(resolve_path "$REPO_ROOT")"

  case "$resolved_target_home/" in
    "$resolved_repo_root/"*)
      if "$ALLOW_UNSAFE_HOME_IN_REPO"; then
        log "WARNING: allowing secret outputs under repo path: $resolved_target_home"
      else
        die "Refusing to generate secret artifacts under repo path '$resolved_target_home'. Re-run with --allow-unsafe-home-in-repo only if you intentionally want secrets written inside the repo."
      fi
      ;;
  esac
}

bw_cmd() {
  if [[ -n "$BW_SESSION_VALUE" ]]; then
    bw --session "$BW_SESSION_VALUE" "$@"
  else
    bw "$@"
  fi
}

ensure_bw_session() {
  require_cmd bw
  require_cmd jq

  if [[ -n "$BW_SESSION_VALUE" ]]; then
    log "Using existing BW_SESSION"
    return 0
  fi

  local status_json
  local status

  status_json="$(bw status --raw 2>/dev/null)" || die "Unable to read Bitwarden status. Run 'bw login' first."
  status="$(jq -r '.status // empty' <<<"$status_json")"

  case "$status" in
    unauthenticated)
      die "Bitwarden CLI is not logged in. Run 'bw login' first."
      ;;
    locked|unlocked)
      log "Unlocking Bitwarden vault..."
      BW_SESSION_VALUE="$(bw unlock --raw)" || die "Failed to unlock Bitwarden vault."
      [[ -n "$BW_SESSION_VALUE" ]] || die "Bitwarden unlock did not return a session token."
      ;;
    *)
      die "Unexpected Bitwarden status: ${status:-unknown}"
      ;;
  esac
}

sync_vault() {
  if "$SYNC_BEFORE_READ"; then
    log "Syncing Bitwarden vault..."
    bw_cmd sync >/dev/null
  fi
}

bw_get_item_json() {
  local item_ref="$1"
  local search_json
  local exact_matches

  if bw_cmd get item "$item_ref" --raw 2>/dev/null; then
    return 0
  fi

  search_json="$(bw_cmd list items --search "$item_ref")"
  exact_matches="$(jq -c --arg name "$item_ref" '[.[] | select(.name == $name)]' <<<"$search_json")"

  case "$(jq 'length' <<<"$exact_matches")" in
    0)
      die "Bitwarden item '$item_ref' was not found."
      ;;
    1)
      jq -c '.[0]' <<<"$exact_matches"
      ;;
    *)
      die "Multiple Bitwarden items named '$item_ref' were found. Use an item ID override instead."
      ;;
  esac
}

bw_field_value() {
  local item_json="$1"
  local field_name="$2"
  local item_ref="$3"
  local value

  value="$({
    jq -r --arg field "$field_name" '
      [
        (.fields[]? | select(.name == $field) | .value),
        (if $field == "username" then .login.username else empty end),
        (if $field == "password" then .login.password else empty end),
        (if $field == "notes" then .notes else empty end)
      ]
      | map(select(. != null and . != ""))
      | first // empty
    ' <<<"$item_json"
  })"

  [[ -n "$value" ]] || die "Field '$field_name' was not found or was empty on Bitwarden item '$item_ref'."
  printf '%s' "$value"
}

write_secret_file() {
  local target_path="$1"
  local content="$2"
  local parent_dir
  local tmp_file

  parent_dir="$(dirname "$target_path")"

  if "$DRY_RUN"; then
    log "DRY-RUN: mkdir -p $parent_dir"
    log "DRY-RUN: write $target_path (mode 600)"
    return 0
  fi

  mkdir -p "$parent_dir"
  tmp_file="$(mktemp "$parent_dir/.tmp.$(basename "$target_path").XXXXXX")"
  chmod 600 "$tmp_file"
  printf '%s' "$content" > "$tmp_file"
  mv "$tmp_file" "$target_path"
  chmod 600 "$target_path"
  log "Wrote $target_path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --home)
      [[ $# -ge 2 ]] || die "Missing value for --home"
      TARGET_HOME="$2"
      shift
      ;;
    --no-sync)
      SYNC_BEFORE_READ=false
      ;;
    --allow-unsafe-home-in-repo)
      ALLOW_UNSAFE_HOME_IN_REPO=true
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      die "Unknown option: $1"
      ;;
  esac
  shift
done

assert_safe_target_home

ENV_OUTPUT_PATH="$TARGET_HOME/.config/secrets/env"
NPMRC_OUTPUT_PATH="$TARGET_HOME/.npmrc"

ensure_bw_session
sync_vault

log "Reading Bitwarden items..."

synthetic_item_json="$(bw_get_item_json "$SYNTHETIC_ITEM")"
github_packages_item_json="$(bw_get_item_json "$GITHUB_PACKAGES_ITEM")"
artifactory_item_json="$(bw_get_item_json "$ARTIFACTORY_ITEM")"

synthetic_api_key="$(bw_field_value "$synthetic_item_json" "$SYNTHETIC_FIELD" "$SYNTHETIC_ITEM")"
github_packages_token="$(bw_field_value "$github_packages_item_json" "$GITHUB_PACKAGES_FIELD" "$GITHUB_PACKAGES_ITEM")"
artifactory_email="$(bw_field_value "$artifactory_item_json" "$ARTIFACTORY_EMAIL_FIELD" "$ARTIFACTORY_ITEM")"
artifactory_token="$(bw_field_value "$artifactory_item_json" "$ARTIFACTORY_TOKEN_FIELD" "$ARTIFACTORY_ITEM")"

env_content="$(printf '# Generated by scripts/refresh-secrets.sh\nexport SYNTHETIC_API_KEY=%q\n' "$synthetic_api_key")"

npmrc_content="$(cat <<EOF
@snaveevans:registry=https://npm.pkg.github.com
@octanner:registry=https://npm.pkg.github.com/
//npm.pkg.github.com/:_authToken=$github_packages_token

@octanner-ui:registry=https://artifactory.octanner.net/api/npm/oct-npmjs/
//artifactory.octanner.net/api/npm/oct-npmjs/:email=$artifactory_email
//artifactory.octanner.net/api/npm/oct-npmjs/:_auth=$artifactory_token
EOF
)"

write_secret_file "$ENV_OUTPUT_PATH" "$env_content"
write_secret_file "$NPMRC_OUTPUT_PATH" "$npmrc_content"

if "$DRY_RUN"; then
  log "Dry run complete."
else
  log "Secrets refreshed."
  log "Generated: $ENV_OUTPUT_PATH"
  log "Generated: $NPMRC_OUTPUT_PATH"
  log "Open a new shell or source $ENV_OUTPUT_PATH to pick up updated shell secrets."
fi
