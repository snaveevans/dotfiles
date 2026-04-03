#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'EOF'
Usage: scripts/bootstrap.sh

Run the platform-specific bootstrap flow for this machine.

This installs packages and setup dependencies needed by the tracked dotfiles,
but does not link config files into $HOME.

Follow-up steps after bootstrap:
  1. scripts/install-home-links.sh
  2. bw login
  3. scripts/refresh-secrets.sh
EOF
}

if [[ $# -gt 0 ]]; then
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
fi

case "$(uname -s)" in
  Darwin)
    exec "$SCRIPT_DIR/bootstrap-darwin.sh"
    ;;
  Linux)
    exec "$SCRIPT_DIR/bootstrap-linux.sh"
    ;;
  *)
    printf 'Unsupported OS: %s\n' "$(uname -s)" >&2
    exit 1
    ;;
esac
