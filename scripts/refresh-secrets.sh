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

BRAVE_ITEM="${BW_ITEM_BRAVE:-api-dashboard.search.brave.com}"
BRAVE_FIELD="${BW_FIELD_BRAVE_API_KEY:-api_key}"

CONTEXT7_ITEM="${BW_ITEM_CONTEXT7:-context7}"
CONTEXT7_FIELD="${BW_FIELD_CONTEXT7_API_KEY:-api_key}"

SYNTHETIC_ITEM="${BW_ITEM_SYNTHETIC:-synthetic.new}"
SYNTHETIC_FIELD="${BW_FIELD_SYNTHETIC_API_KEY:-api_key}"

GITHUB_PACKAGES_ITEM="${BW_ITEM_GITHUB_PACKAGES:-ebac9653-5fbd-4dac-b22d-af9a0116b6bb}"
GITHUB_PACKAGES_WORK_FIELD="${BW_FIELD_GITHUB_PACKAGES_WORK_TOKEN:-${BW_FIELD_GITHUB_PACKAGES_TOKEN:-work_access_token}}"
GITHUB_PACKAGES_PERSONAL_FIELD="${BW_FIELD_GITHUB_PACKAGES_PERSONAL_TOKEN:-personal_access_token}"

ARTIFACTORY_ITEM="${BW_ITEM_ARTIFACTORY:-artifactory.octanner.net}"
ARTIFACTORY_EMAIL_FIELD="${BW_FIELD_ARTIFACTORY_EMAIL:-email}"
ARTIFACTORY_TOKEN_FIELD="${BW_FIELD_ARTIFACTORY_TOKEN:-access_token}"
ARTIFACTORY_ENCRYPTED_PASSWORD_FIELD="${BW_FIELD_ARTIFACTORY_ENCRYPTED_PASSWORD:-encrypted_password}"

CLOUDFLARE_ITEM="${BW_ITEM_CLOUDFLARE:-cloudflare.com}"
CLOUDFLARE_ACCOUNT_ID_FIELD="${BW_FIELD_CLOUDFLARE_ACCOUNT_ID:-account_id}"
CLOUDFLARE_API_TOKEN_FIELD="${BW_FIELD_CLOUDFLARE_API_TOKEN:-github_actions_token}"

# Which environments each item belongs to. An item is projected when any of
# its tags is requested via --tag (or the persisted selection); with no tag
# filter at all, every item is projected.
KNOWN_TAGS="work personal"
REQUESTED_TAGS=()
EXPLICIT_TAGS=false

BRAVE_TAGS="work personal"
CONTEXT7_TAGS="work personal"
SYNTHETIC_TAGS="personal"
GITHUB_PACKAGES_TAGS="work personal"
ARTIFACTORY_TAGS="work"
CLOUDFLARE_TAGS="personal"

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

Generated artifacts (subset depends on the selected tags):
  ~/.config/secrets/env
  ~/.config/secrets/tags
  ~/.npmrc
  ~/.gradle/gradle.properties
  ~/.m2/settings.xml

Options:
  --tag TAG   Project only items carrying TAG (repeatable; known tags: work,
              personal). The selection is persisted to
              ~/.config/secrets/tags and reused by later tag-less runs.
  --dry-run   Resolve secrets but do not write files
  --home DIR  Generate artifacts under DIR instead of $HOME
  --no-sync   Skip 'bw sync' before reads
  --allow-unsafe-home-in-repo
              Allow writing under a home path located inside the repo root
  --help      Show this help message

Examples:
  scripts/refresh-secrets.sh --tag work                # work-only machine
  scripts/refresh-secrets.sh --tag work --tag personal # machine that is both

Bitwarden item/field references can be overridden with environment variables.
See docs/migrations/secret-projection.md for the expected defaults.

Expects a Bitwarden item named "synthetic.new" with an "api_key" field for
Pi's Synthetic provider (~/.pi/agent/models.json). Override with
BW_ITEM_SYNTHETIC / BW_FIELD_SYNTHETIC_API_KEY.
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
    --tag)
      [[ $# -ge 2 ]] || die "Missing value for --tag"
      REQUESTED_TAGS+=("$2")
      EXPLICIT_TAGS=true
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

ENV_OUTPUT_PATH="$TARGET_HOME/.config/secrets/env"
TAGS_OUTPUT_PATH="$TARGET_HOME/.config/secrets/tags"
NPMRC_OUTPUT_PATH="$TARGET_HOME/.npmrc"
GRADLE_PROPERTIES_OUTPUT_PATH="$TARGET_HOME/.gradle/gradle.properties"
MAVEN_SETTINGS_OUTPUT_PATH="$TARGET_HOME/.m2/settings.xml"

# No explicit --tag: fall back to the selection persisted by an earlier run.
if ! "$EXPLICIT_TAGS" && [[ -r "$TAGS_OUTPUT_PATH" ]]; then
  while IFS= read -r persisted_tag || [[ -n "$persisted_tag" ]]; do
    [[ -n "$persisted_tag" ]] && REQUESTED_TAGS+=("$persisted_tag")
  done < "$TAGS_OUTPUT_PATH"
fi

if [[ ${#REQUESTED_TAGS[@]} -gt 0 ]]; then
  for tag in "${REQUESTED_TAGS[@]}"; do
    case " $KNOWN_TAGS " in
      *" $tag "*) ;;
      *) die "Unknown tag: $tag (known tags: $KNOWN_TAGS)" ;;
    esac
  done
  log "Projecting tags: ${REQUESTED_TAGS[*]}"
else
  log "No tag filter; projecting all items"
fi

item_enabled() {
  local item_tags="$1"
  local tag

  [[ ${#REQUESTED_TAGS[@]} -gt 0 ]] || return 0

  for tag in "${REQUESTED_TAGS[@]}"; do
    case " $item_tags " in
      *" $tag "*) return 0 ;;
    esac
  done

  return 1
}

tag_requested() {
  local want="$1"
  local tag

  [[ ${#REQUESTED_TAGS[@]} -gt 0 ]] || return 0

  for tag in "${REQUESTED_TAGS[@]}"; do
    [[ "$tag" == "$want" ]] && return 0
  done

  return 1
}

BRAVE_ENABLED=false
item_enabled "$BRAVE_TAGS" && BRAVE_ENABLED=true
CONTEXT7_ENABLED=false
item_enabled "$CONTEXT7_TAGS" && CONTEXT7_ENABLED=true
SYNTHETIC_ENABLED=false
item_enabled "$SYNTHETIC_TAGS" && SYNTHETIC_ENABLED=true
ARTIFACTORY_ENABLED=false
item_enabled "$ARTIFACTORY_TAGS" && ARTIFACTORY_ENABLED=true
CLOUDFLARE_ENABLED=false
item_enabled "$CLOUDFLARE_TAGS" && CLOUDFLARE_ENABLED=true

GITHUB_WORK_ENABLED=false
GITHUB_PERSONAL_ENABLED=false
if item_enabled "$GITHUB_PACKAGES_TAGS"; then
  tag_requested work && GITHUB_WORK_ENABLED=true
  tag_requested personal && GITHUB_PERSONAL_ENABLED=true
fi

assert_safe_target_home

ensure_bw_session
sync_vault

log "Reading Bitwarden items..."

brave_api_key=""
if "$BRAVE_ENABLED"; then
  brave_api_key="$(bw_field_value "$(bw_get_item_json "$BRAVE_ITEM")" "$BRAVE_FIELD" "$BRAVE_ITEM")"
fi

context7_api_key=""
if "$CONTEXT7_ENABLED"; then
  context7_api_key="$(bw_field_value "$(bw_get_item_json "$CONTEXT7_ITEM")" "$CONTEXT7_FIELD" "$CONTEXT7_ITEM")"
fi

synthetic_api_key=""
if "$SYNTHETIC_ENABLED"; then
  synthetic_api_key="$(bw_field_value "$(bw_get_item_json "$SYNTHETIC_ITEM")" "$SYNTHETIC_FIELD" "$SYNTHETIC_ITEM")"
fi

github_packages_work_token=""
github_packages_personal_token=""
if "$GITHUB_WORK_ENABLED" || "$GITHUB_PERSONAL_ENABLED"; then
  github_packages_item_json="$(bw_get_item_json "$GITHUB_PACKAGES_ITEM")"

  if "$GITHUB_WORK_ENABLED"; then
    github_packages_work_token="$(bw_field_value "$github_packages_item_json" "$GITHUB_PACKAGES_WORK_FIELD" "$GITHUB_PACKAGES_ITEM")"
  fi

  if "$GITHUB_PERSONAL_ENABLED"; then
    github_packages_personal_token="$(bw_field_value "$github_packages_item_json" "$GITHUB_PACKAGES_PERSONAL_FIELD" "$GITHUB_PACKAGES_ITEM")"
  fi
fi

artifactory_email=""
artifactory_token=""
artifactory_encrypted_password=""
artifactory_username=""
if "$ARTIFACTORY_ENABLED"; then
  artifactory_item_json="$(bw_get_item_json "$ARTIFACTORY_ITEM")"
  artifactory_email="$(bw_field_value "$artifactory_item_json" "$ARTIFACTORY_EMAIL_FIELD" "$ARTIFACTORY_ITEM")"
  artifactory_token="$(bw_field_value "$artifactory_item_json" "$ARTIFACTORY_TOKEN_FIELD" "$ARTIFACTORY_ITEM")"
  artifactory_encrypted_password="$(bw_field_value "$artifactory_item_json" "$ARTIFACTORY_ENCRYPTED_PASSWORD_FIELD" "$ARTIFACTORY_ITEM")"
  artifactory_username="${artifactory_email%%@*}"
fi

cloudflare_account_id=""
cloudflare_api_token=""
if "$CLOUDFLARE_ENABLED"; then
  cloudflare_item_json="$(bw_get_item_json "$CLOUDFLARE_ITEM")"
  cloudflare_account_id="$(bw_field_value "$cloudflare_item_json" "$CLOUDFLARE_ACCOUNT_ID_FIELD" "$CLOUDFLARE_ITEM")"
  cloudflare_api_token="$(bw_field_value "$cloudflare_item_json" "$CLOUDFLARE_API_TOKEN_FIELD" "$CLOUDFLARE_ITEM")"
fi

env_content="$({
  printf '# Generated by scripts/refresh-secrets.sh\n'
  if "$BRAVE_ENABLED"; then printf 'export BRAVE_API_KEY=%q\n' "$brave_api_key"; fi
  if "$CONTEXT7_ENABLED"; then printf 'export CONTEXT7_API_KEY=%q\n' "$context7_api_key"; fi
  if "$SYNTHETIC_ENABLED"; then printf 'export SYNTHETIC_API_KEY=%q\n' "$synthetic_api_key"; fi
  if "$GITHUB_WORK_ENABLED"; then printf 'export GITHUB_PACKAGES_TOKEN=%q\n' "$github_packages_work_token"; fi
  if "$GITHUB_PERSONAL_ENABLED"; then printf 'export GITHUB_PACKAGES_PERSONAL_TOKEN=%q\n' "$github_packages_personal_token"; fi
  if "$CLOUDFLARE_ENABLED"; then printf 'export CLOUDFLARE_ACCOUNT_ID=%q\n' "$cloudflare_account_id"; fi
  if "$CLOUDFLARE_ENABLED"; then printf 'export CLOUDFLARE_API_TOKEN=%q\n' "$cloudflare_api_token"; fi
})"

npmrc_content=""
if "$GITHUB_WORK_ENABLED" || "$GITHUB_PERSONAL_ENABLED" || "$ARTIFACTORY_ENABLED"; then
  npmrc_content="$({
    if "$GITHUB_WORK_ENABLED" || "$GITHUB_PERSONAL_ENABLED"; then
      printf '@snaveevans:registry=https://npm.pkg.github.com\n'

      if "$GITHUB_WORK_ENABLED"; then
        printf '@octanner:registry=https://npm.pkg.github.com/\n'
        printf '//npm.pkg.github.com/:_authToken=${GITHUB_PACKAGES_TOKEN}\n'
      else
        printf '//npm.pkg.github.com/:_authToken=${GITHUB_PACKAGES_PERSONAL_TOKEN}\n'
      fi
    fi

    if "$ARTIFACTORY_ENABLED"; then
      printf '\n'
      printf '@octanner-ui:registry=https://artifactory.octanner.net/api/npm/oct-npmjs/\n'
      printf '//artifactory.octanner.net/api/npm/oct-npmjs/:email=%s\n' "$artifactory_email"
      printf '//artifactory.octanner.net/api/npm/oct-npmjs/:_auth=%s\n' "$artifactory_token"
    fi
  })"
fi

write_secret_file "$ENV_OUTPUT_PATH" "$env_content"

if "$EXPLICIT_TAGS"; then
  tags_content=""
  for tag in "${REQUESTED_TAGS[@]}"; do
    tags_content+="$tag"$'\n'
  done
  write_secret_file "$TAGS_OUTPUT_PATH" "$tags_content"
fi

if [[ -n "$npmrc_content" ]]; then
  write_secret_file "$NPMRC_OUTPUT_PATH" "$npmrc_content"
fi

if "$ARTIFACTORY_ENABLED"; then
  gradle_properties_content="$(printf '# Generated by scripts/refresh-secrets.sh\ncentralUsername=%s\ncentralPassword=%s\n' "$artifactory_username" "$artifactory_encrypted_password")"

  maven_settings_content="$(cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!-- Generated by scripts/refresh-secrets.sh -->
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.0.0
                              https://maven.apache.org/xsd/settings-1.0.0.xsd">
  <servers>
    <server>
      <id>central</id>
      <username>$artifactory_username</username>
      <password>$artifactory_encrypted_password</password>
    </server>
  </servers>
</settings>
EOF
  )"

  write_secret_file "$GRADLE_PROPERTIES_OUTPUT_PATH" "$gradle_properties_content"
  write_secret_file "$MAVEN_SETTINGS_OUTPUT_PATH" "$maven_settings_content"
fi

if "$DRY_RUN"; then
  log "Dry run complete."
else
  log "Secrets refreshed."
  log "Generated: $ENV_OUTPUT_PATH"

  if "$EXPLICIT_TAGS"; then
    log "Generated: $TAGS_OUTPUT_PATH"
  fi

  if [[ -n "$npmrc_content" ]]; then
    log "Generated: $NPMRC_OUTPUT_PATH"
  fi

  if "$ARTIFACTORY_ENABLED"; then
    log "Generated: $GRADLE_PROPERTIES_OUTPUT_PATH"
    log "Generated: $MAVEN_SETTINGS_OUTPUT_PATH"
  fi

  log "Open a new shell or source $ENV_OUTPUT_PATH to pick up updated shell secrets."
fi
