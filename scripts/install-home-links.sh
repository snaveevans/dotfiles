#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_ROOT="$REPO_ROOT/home"
TARGET_HOME="${HOME}"
BACKUP_DIR=""
DRY_RUN=false

LINK_PATHS=(
  ".zshenv"
  ".zshrc"
  ".gitconfig"
  ".rgignore"
  ".hammerspoon"
  ".config/nvim"
  ".config/starship.toml"
  ".config/i3"
  ".config/rofi"
  ".config/polybar"
)

usage() {
  cat <<'EOF'
Usage: scripts/install-home-links.sh [options]

Safely symlink the migrated home/ layout into a target home directory.

Options:
  --dry-run            Print planned actions without changing anything
  --home PATH          Install into PATH instead of $HOME
  --backup-dir PATH    Move replaced targets into PATH
  --help               Show this help message
EOF
}

log() {
  printf '%s\n' "$*"
}

run() {
  if "$DRY_RUN"; then
    log "DRY-RUN: $*"
    return 0
  fi

  "$@"
}

ensure_backup_dir() {
  if [[ -n "$BACKUP_DIR" ]]; then
    return 0
  fi

  BACKUP_DIR="$TARGET_HOME/.local/state/dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
  run mkdir -p "$BACKUP_DIR"
}

backup_target() {
  local target="$1"
  local relative_target="${target#"$TARGET_HOME"/}"
  local destination

  ensure_backup_dir
  destination="$BACKUP_DIR/$relative_target"

  run mkdir -p "$(dirname "$destination")"
  log "Backing up $target -> $destination"
  run mv "$target" "$destination"
}

link_path() {
  local relative_path="$1"
  local source="$SOURCE_ROOT/$relative_path"
  local target="$TARGET_HOME/$relative_path"
  local parent

  if [[ ! -e "$source" && ! -L "$source" ]]; then
    log "Missing source: $source"
    return 1
  fi

  if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
    log "Skipping existing link: $target"
    return 0
  fi

  parent="$(dirname "$target")"
  run mkdir -p "$parent"

  if [[ -e "$target" || -L "$target" ]]; then
    backup_target "$target"
  fi

  log "Linking $target -> $source"
  run ln -s "$source" "$target"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      ;;
    --home)
      [[ $# -ge 2 ]] || {
        log "Missing value for --home"
        exit 1
      }
      TARGET_HOME="$2"
      shift
      ;;
    --backup-dir)
      [[ $# -ge 2 ]] || {
        log "Missing value for --backup-dir"
        exit 1
      }
      BACKUP_DIR="$2"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      log "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
  shift
done

for relative_path in "${LINK_PATHS[@]}"; do
  link_path "$relative_path"
done

if [[ -n "$BACKUP_DIR" ]]; then
  log "Backup directory: $BACKUP_DIR"
fi

log "Done."
