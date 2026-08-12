#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SELECTOR="$REPO_ROOT/home/.config/kitty/kitty_selector.py"

[[ -f "$SELECTOR" ]] || {
  printf 'kitty_selector.py is missing: %s\n' "$SELECTOR" >&2
  exit 1
}
command -v python3 >/dev/null 2>&1 || {
  printf 'python3 is required for this verification script\n' >&2
  exit 1
}

python3 "$SCRIPT_DIR/test-kitty-selector.py" "$SELECTOR"
