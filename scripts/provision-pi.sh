#!/usr/bin/env bash

# provision-pi.sh - point ~/.pi/agent/settings.json and models.json at the
# tag-appropriate tracked files (settings.<tag>.json / models.<tag>.json).
#
# Pi reads exactly those two filenames, pi's global settings have no layering
# of their own, and pi writes user-toggled settings back into the file - so a
# symlink swap, not content generation, is the mechanism (the file pi writes
# stays the tracked one per tag).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_HOME="${HOME}"
DRY_RUN=false
KNOWN_TAGS="work personal"
REQUESTED_TAGS=()

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '%s\n' "$*"
}

usage() {
  cat <<'EOF'
Usage: scripts/provision-pi.sh [options]

Link ~/.pi/agent/settings.json and ~/.pi/agent/models.json to the tracked
settings.<tag>.json / models.<tag>.json for this machine's tag.

Tag resolution order:
  1. explicit --tag flags (repeatable)
  2. ~/.config/secrets/tags (written by 'refresh-secrets.sh --tag')
  3. fallback: personal (the historical single-machine setup)

If both work and personal end up selected, work wins.

Options:
  --tag TAG   work or personal (repeatable; NOT persisted here - the
              refresh-secrets.sh tags file is the canonical selection)
  --home DIR  Provision under DIR instead of $HOME
  --dry-run   Show what would change without touching the filesystem
  --help      Show this help message
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      [[ $# -ge 2 ]] || die "Missing value for --tag"
      REQUESTED_TAGS+=("$2")
      shift
      ;;
    --home)
      [[ $# -ge 2 ]] || die "Missing value for --home"
      TARGET_HOME="$2"
      shift
      ;;
    --dry-run)
      DRY_RUN=true
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

TAGS_PATH="$TARGET_HOME/.config/secrets/tags"

if [[ ${#REQUESTED_TAGS[@]} -eq 0 && -r "$TAGS_PATH" ]]; then
  while IFS= read -r persisted_tag || [[ -n "$persisted_tag" ]]; do
    [[ -n "$persisted_tag" ]] && REQUESTED_TAGS+=("$persisted_tag")
  done < "$TAGS_PATH"
fi

if [[ ${#REQUESTED_TAGS[@]} -gt 0 ]]; then
  for tag in "${REQUESTED_TAGS[@]}"; do
    case " $KNOWN_TAGS " in
      *" $tag "*) ;;
      *) die "Unknown tag: $tag (known tags: $KNOWN_TAGS)" ;;
    esac
  done
fi

tag_selected() {
  local want="$1"
  local tag

  # bash 3.2 errors on "${arr[@]}" when the array is empty under set -u.
  [[ ${#REQUESTED_TAGS[@]} -gt 0 ]] || return 1

  for tag in "${REQUESTED_TAGS[@]}"; do
    [[ "$tag" == "$want" ]] && return 0
  done

  return 1
}

WORK_SELECTED=false
PERSONAL_SELECTED=false
tag_selected work && WORK_SELECTED=true
tag_selected personal && PERSONAL_SELECTED=true

# Work wins when both are selected - a work credential/config on a machine
# that briefly overlaps is the safer side to land on.
PI_TAG=personal
if "$WORK_SELECTED"; then
  PI_TAG=work
  if "$PERSONAL_SELECTED"; then
    log "Both work and personal selected; using work"
  fi
fi

log "Provisioning pi config for tag: $PI_TAG"

link_tagged_file() {
  local repo_name="$1"
  local dest_name="$2"
  local src="$REPO_ROOT/home/.pi/agent/$repo_name"
  local dest="$TARGET_HOME/.pi/agent/$dest_name"
  local current

  [[ -f "$src" ]] || die "Tracked file not found: $src"

  if [[ -L "$dest" ]]; then
    current="$(readlink "$dest")"
    if [[ "$current" == "$src" ]]; then
      log "Already linked: $dest"
      return 0
    fi

    if "$DRY_RUN"; then
      log "DRY-RUN: re-link $dest -> $src (was $current)"
    else
      ln -sfn "$src" "$dest"
      log "Re-linked $dest -> $src (was $current)"
    fi
    return 0
  fi

  if [[ -e "$dest" ]]; then
    # A real file here is pi-written state (settings toggles, changelog
    # markers). Never clobber it silently.
    die "$dest exists and is not a symlink; refusing to overwrite pi-managed state. Move it aside first."
  fi

  if "$DRY_RUN"; then
    log "DRY-RUN: mkdir -p $(dirname "$dest")"
    log "DRY-RUN: link $dest -> $src"
  else
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    log "Linked $dest -> $src"
  fi
}

link_tagged_file "settings.$PI_TAG.json" "settings.json"
link_tagged_file "models.$PI_TAG.json" "models.json"

if "$DRY_RUN"; then
  log "Dry run complete."
fi
