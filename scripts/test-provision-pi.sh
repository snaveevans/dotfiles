#!/usr/bin/env bash

# Verifies scripts/provision-pi.sh tag resolution and symlink behavior
# against throwaway home directories - no real ~/.pi is touched.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TMP_DIR"
}

fail() {
  printf 'Test failed: %s\n' "$*" >&2
  exit 1
}

trap cleanup EXIT

expect_link() {
  local dest="$1"
  local src="$2"

  [[ -L "$dest" ]] || fail "$dest should be a symlink"
  [[ "$(readlink "$dest")" == "$src" ]] || fail "$dest should point at $src, points at $(readlink "$dest")"
}

# 1. No tags file, no flags: the historical single-machine setup is personal.
HOME_A="$TMP_DIR/home-no-tags"
bash "$REPO_ROOT/scripts/provision-pi.sh" --home "$HOME_A" >"$TMP_DIR/out-a"
grep -Fq 'Provisioning pi config for tag: personal' "$TMP_DIR/out-a" || fail "tag-less run should fall back to personal"
expect_link "$HOME_A/.pi/agent/settings.json" "$REPO_ROOT/home/.pi/agent/settings.personal.json"
expect_link "$HOME_A/.pi/agent/models.json" "$REPO_ROOT/home/.pi/agent/models.personal.json"

# Re-running is idempotent.
bash "$REPO_ROOT/scripts/provision-pi.sh" --home "$HOME_A" >"$TMP_DIR/out-a2" || fail "a rerun should succeed"
grep -Fq 'Already linked:' "$TMP_DIR/out-a2" || fail "a rerun should say everything is already linked"

# 2. A persisted work selection (written by refresh-secrets.sh --tag work).
HOME_B="$TMP_DIR/home-work"
mkdir -p "$HOME_B/.config/secrets"
printf 'work\n' >"$HOME_B/.config/secrets/tags"
bash "$REPO_ROOT/scripts/provision-pi.sh" --home "$HOME_B" >"$TMP_DIR/out-b"
grep -Fq 'Provisioning pi config for tag: work' "$TMP_DIR/out-b" || fail "a persisted work tag should provision work files"
expect_link "$HOME_B/.pi/agent/settings.json" "$REPO_ROOT/home/.pi/agent/settings.work.json"
expect_link "$HOME_B/.pi/agent/models.json" "$REPO_ROOT/home/.pi/agent/models.work.json"

# 3. Both tags persisted: work wins, and says so.
HOME_C="$TMP_DIR/home-both"
mkdir -p "$HOME_C/.config/secrets"
printf 'personal\nwork\n' >"$HOME_C/.config/secrets/tags"
bash "$REPO_ROOT/scripts/provision-pi.sh" --home "$HOME_C" >"$TMP_DIR/out-c"
grep -Fq 'using work' "$TMP_DIR/out-c" || fail "work should win when both tags are selected"
expect_link "$HOME_C/.pi/agent/settings.json" "$REPO_ROOT/home/.pi/agent/settings.work.json"

# 4. An explicit --tag overrides the persisted selection...
bash "$REPO_ROOT/scripts/provision-pi.sh" --home "$HOME_B" --tag personal >"$TMP_DIR/out-b2"
expect_link "$HOME_B/.pi/agent/settings.json" "$REPO_ROOT/home/.pi/agent/settings.personal.json"

# ...and re-pointing an existing symlink requires no cleanup.
grep -Fq 'Re-linked' "$TMP_DIR/out-b2" || fail "switching tags should re-link, not error"
bash "$REPO_ROOT/scripts/provision-pi.sh" --home "$HOME_B" >"$TMP_DIR/out-b3"
expect_link "$HOME_B/.pi/agent/settings.json" "$REPO_ROOT/home/.pi/agent/settings.work.json"

# 5. A real (non-symlink) settings.json is pi-managed state - refuse to
# clobber it.
HOME_E="$TMP_DIR/home-real-file"
mkdir -p "$HOME_E/.pi/agent"
printf '{"theme":"dark"}\n' >"$HOME_E/.pi/agent/settings.json"
if bash "$REPO_ROOT/scripts/provision-pi.sh" --home "$HOME_E" >"$TMP_DIR/out-e" 2>&1; then
  fail "provisioning over a real settings.json should fail"
fi
grep -Fq 'refusing to overwrite' "$TMP_DIR/out-e" || fail "the refusal should be explained"
[[ "$(cat "$HOME_E/.pi/agent/settings.json")" == '{"theme":"dark"}' ]] || fail "the real settings.json must be untouched"

# 6. Unknown tags are rejected.
if bash "$REPO_ROOT/scripts/provision-pi.sh" --home "$TMP_DIR/any" --tag bogus >"$TMP_DIR/out-f" 2>&1; then
  fail "an unknown tag should fail"
fi
grep -Fq 'Unknown tag: bogus' "$TMP_DIR/out-f" || fail "an unknown tag should be explained"

# 7. A dry run touches nothing.
HOME_G="$TMP_DIR/home-dry"
bash "$REPO_ROOT/scripts/provision-pi.sh" --home "$HOME_G" --dry-run >"$TMP_DIR/out-g"
grep -Fq 'DRY-RUN:' "$TMP_DIR/out-g" || fail "a dry run should narrate its actions"
[[ ! -e "$HOME_G/.pi/agent/settings.json" ]] || fail "a dry run should not link settings.json"
[[ ! -e "$HOME_G/.pi/agent/models.json" ]] || fail "a dry run should not link models.json"

printf 'provision-pi verification passed\n'
