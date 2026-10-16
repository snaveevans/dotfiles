#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TMP_DIR="$(mktemp -d)"
FAKE_BIN="$TMP_DIR/bin"
TARGET_HOME="$TMP_DIR/target-home"
BW_LOG_FILE="$TMP_DIR/bw.log"
OUTPUT_FILE="$TMP_DIR/output.log"

cleanup() {
  rm -rf "$TMP_DIR"
}

fail() {
  printf 'Test failed: %s\n' "$*" >&2
  exit 1
}

trap cleanup EXIT

command -v jq >/dev/null 2>&1 || fail "jq is required for this verification script"

mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/bw" <<'EOF'
#!/usr/bin/env bash

set -euo pipefail

printf '%s\n' "$*" >> "$BW_LOG_FILE"

session=""
if [[ "${1:-}" == "--session" ]]; then
  session="$2"
  shift 2
fi

case "${1:-}" in
  status)
    printf '{"status":"locked"}\n'
    ;;
  unlock)
    printf 'fake-session-token\n'
    ;;
  sync)
    [[ "$session" == "fake-session-token" ]] || exit 1
    ;;
  get)
    [[ "${2:-}" == "item" ]] || exit 1
    [[ "$session" == "fake-session-token" ]] || exit 1

    case "${3:-}" in
      api-dashboard.search.brave.com)
        printf '{"name":"api-dashboard.search.brave.com","fields":[{"name":"api_key","value":"brave-token"}]}'
        ;;
      context7)
        printf '{"name":"context7","fields":[{"name":"api_key","value":"context7-token"}]}'
        ;;
      synthetic.new)
        printf '{"name":"synthetic.new","fields":[{"name":"api_key","value":"synthetic-token"}]}'
        ;;
      ebac9653-5fbd-4dac-b22d-af9a0116b6bb)
        printf '{"id":"ebac9653-5fbd-4dac-b22d-af9a0116b6bb","fields":[{"name":"access_token","value":"github-legacy-token"},{"name":"work_access_token","value":"github-work-token"},{"name":"personal_access_token","value":"github-personal-token"}]}'
        ;;
      artifactory.octanner.net)
        printf '{"name":"artifactory.octanner.net","fields":[{"name":"email","value":"user@example.com"},{"name":"access_token","value":"artifactory-token"},{"name":"encrypted_password","value":"artifactory-encrypted-password"}]}'
        ;;
      cloudflare.com)
        printf '{"name":"cloudflare.com","fields":[{"name":"account_id","value":"cloudflare-account-id"},{"name":"github_actions_token","value":"cloudflare-api-token"}]}'
        ;;
      *)
        exit 1
        ;;
    esac
    ;;
  *)
    exit 1
    ;;
esac
EOF

chmod +x "$FAKE_BIN/bw"

PATH="$FAKE_BIN:$PATH" BW_LOG_FILE="$BW_LOG_FILE" \
  bash "$REPO_ROOT/scripts/refresh-secrets.sh" --dry-run --home "$TARGET_HOME" > "$OUTPUT_FILE"

grep -Fq 'Unlocking Bitwarden vault...' "$OUTPUT_FILE" || fail "expected unlock message"
grep -Fq 'Syncing Bitwarden vault...' "$OUTPUT_FILE" || fail "expected sync message"
grep -Fq 'Reading Bitwarden items...' "$OUTPUT_FILE" || fail "expected item read message"
grep -Fq 'Dry run complete.' "$OUTPUT_FILE" || fail "expected dry-run completion message"

grep -Fq 'status --raw' "$BW_LOG_FILE" || fail "expected bw status call"
grep -Fq 'unlock --raw' "$BW_LOG_FILE" || fail "expected bw unlock call"
grep -Fq -- '--session fake-session-token sync' "$BW_LOG_FILE" || fail "expected session-backed bw sync call"
grep -Fq -- '--session fake-session-token get item api-dashboard.search.brave.com --raw' "$BW_LOG_FILE" || fail "expected Brave item read"
grep -Fq -- '--session fake-session-token get item context7 --raw' "$BW_LOG_FILE" || fail "expected Context7 item read"
grep -Fq -- '--session fake-session-token get item synthetic.new --raw' "$BW_LOG_FILE" || fail "expected Synthetic item read"
grep -Fq -- '--session fake-session-token get item ebac9653-5fbd-4dac-b22d-af9a0116b6bb --raw' "$BW_LOG_FILE" || fail "expected github packages item read"
grep -Fq -- '--session fake-session-token get item artifactory.octanner.net --raw' "$BW_LOG_FILE" || fail "expected artifactory item read"
grep -Fq -- '--session fake-session-token get item cloudflare.com --raw' "$BW_LOG_FILE" || fail "expected cloudflare item read"

[[ ! -e "$TARGET_HOME/.config/secrets/env" ]] || fail "dry run should not write env artifact"
[[ ! -e "$TARGET_HOME/.npmrc" ]] || fail "dry run should not write npmrc artifact"
[[ ! -e "$TARGET_HOME/.gradle/gradle.properties" ]] || fail "dry run should not write gradle artifact"
[[ ! -e "$TARGET_HOME/.m2/settings.xml" ]] || fail "dry run should not write maven settings artifact"

# A tag-less refresh projects every item, including the GitHub Packages work
# and personal tokens from their dedicated fields.
ALL_HOME="$TMP_DIR/all-home"
PATH="$FAKE_BIN:$PATH" BW_LOG_FILE="$BW_LOG_FILE" \
  bash "$REPO_ROOT/scripts/refresh-secrets.sh" --home "$ALL_HOME" > "$OUTPUT_FILE"

grep -Fq 'No tag filter; projecting all items' "$OUTPUT_FILE" || fail "a tag-less run should say it projects everything"
grep -Fq 'export BRAVE_API_KEY=brave-token' "$ALL_HOME/.config/secrets/env" || fail "tag-less run should export the Brave key"
grep -Fq 'export SYNTHETIC_API_KEY=synthetic-token' "$ALL_HOME/.config/secrets/env" || fail "tag-less run should export the Synthetic key"
grep -Fq 'export GITHUB_PACKAGES_TOKEN=github-work-token' "$ALL_HOME/.config/secrets/env" ||
  fail "tag-less run should export the GitHub Packages work token from work_access_token"
grep -Fq 'export GITHUB_PACKAGES_PERSONAL_TOKEN=github-personal-token' "$ALL_HOME/.config/secrets/env" ||
  fail "tag-less run should export the GitHub Packages personal token from personal_access_token"
grep -Fq 'export CLOUDFLARE_API_TOKEN=cloudflare-api-token' "$ALL_HOME/.config/secrets/env" ||
  fail "tag-less run should export the Cloudflare token"
grep -Fq '@octanner-ui:registry=https://artifactory.octanner.net/api/npm/oct-npmjs/' "$ALL_HOME/.npmrc" ||
  fail "tag-less run should include the Artifactory npmrc block"
grep -Fq '//npm.pkg.github.com/:_authToken=${GITHUB_PACKAGES_TOKEN}' "$ALL_HOME/.npmrc" ||
  fail "tag-less npmrc should authenticate GitHub Packages with the work token"
[[ -f "$ALL_HOME/.gradle/gradle.properties" ]] || fail "tag-less run should write the gradle artifact"
[[ -f "$ALL_HOME/.m2/settings.xml" ]] || fail "tag-less run should write the maven artifact"
[[ ! -e "$ALL_HOME/.config/secrets/tags" ]] || fail "a run without --tag should not write a persisted tag selection"

# --tag work drops every personal-only secret and keeps the work artifacts.
WORK_HOME="$TMP_DIR/work-home"
PATH="$FAKE_BIN:$PATH" BW_LOG_FILE="$BW_LOG_FILE" \
  bash "$REPO_ROOT/scripts/refresh-secrets.sh" --tag work --home "$WORK_HOME" > "$OUTPUT_FILE"

grep -Fq 'Projecting tags: work' "$OUTPUT_FILE" || fail "a tagged run should say what it projects"
grep -Fq 'export BRAVE_API_KEY=brave-token' "$WORK_HOME/.config/secrets/env" || fail "work run should keep shared secrets"
grep -Fq 'export CONTEXT7_API_KEY=context7-token' "$WORK_HOME/.config/secrets/env" || fail "work run should keep shared secrets"
grep -Fq 'export GITHUB_PACKAGES_TOKEN=github-work-token' "$WORK_HOME/.config/secrets/env" ||
  fail "work run should export the GitHub Packages work token"
if grep -Fq 'SYNTHETIC_API_KEY' "$WORK_HOME/.config/secrets/env"; then
  fail "work run should not export personal-only secrets"
fi
if grep -Fq 'CLOUDFLARE' "$WORK_HOME/.config/secrets/env"; then
  fail "work run should not export personal-only secrets"
fi
if grep -Fq 'GITHUB_PACKAGES_PERSONAL_TOKEN' "$WORK_HOME/.config/secrets/env"; then
  fail "work run should not export the GitHub Packages personal token"
fi
grep -Fq '@octanner:registry=https://npm.pkg.github.com/' "$WORK_HOME/.npmrc" ||
  fail "work npmrc should keep the octanner GitHub Packages scope"
grep -Fq '@octanner-ui:registry=https://artifactory.octanner.net/api/npm/oct-npmjs/' "$WORK_HOME/.npmrc" ||
  fail "work npmrc should keep the Artifactory scope"
[[ -f "$WORK_HOME/.gradle/gradle.properties" ]] || fail "work run should write the gradle artifact"
[[ -f "$WORK_HOME/.m2/settings.xml" ]] || fail "work run should write the maven artifact"
grep -Fqx 'work' "$WORK_HOME/.config/secrets/tags" || fail "an explicit --tag run should persist its selection"

# --tag personal keeps shared + personal secrets, uses the personal GitHub
# Packages token for @snaveevans, and skips work-only artifacts.
PERSONAL_HOME="$TMP_DIR/personal-home"
PATH="$FAKE_BIN:$PATH" BW_LOG_FILE="$BW_LOG_FILE" \
  bash "$REPO_ROOT/scripts/refresh-secrets.sh" --tag personal --home "$PERSONAL_HOME" > "$OUTPUT_FILE"

grep -Fq 'export BRAVE_API_KEY=brave-token' "$PERSONAL_HOME/.config/secrets/env" || fail "personal run should keep shared secrets"
grep -Fq 'export SYNTHETIC_API_KEY=synthetic-token' "$PERSONAL_HOME/.config/secrets/env" || fail "personal run should export the Synthetic key"
grep -Fq 'export CLOUDFLARE_ACCOUNT_ID=cloudflare-account-id' "$PERSONAL_HOME/.config/secrets/env" ||
  fail "personal run should export the Cloudflare account id"
grep -Fq 'export GITHUB_PACKAGES_PERSONAL_TOKEN=github-personal-token' "$PERSONAL_HOME/.config/secrets/env" ||
  fail "personal run should export the GitHub Packages personal token"
if grep -Fq 'export GITHUB_PACKAGES_TOKEN' "$PERSONAL_HOME/.config/secrets/env"; then
  fail "personal run should not export the work GitHub Packages token"
fi
grep -Fq '@snaveevans:registry=https://npm.pkg.github.com' "$PERSONAL_HOME/.npmrc" ||
  fail "personal npmrc should keep the personal GitHub Packages scope"
grep -Fq '//npm.pkg.github.com/:_authToken=${GITHUB_PACKAGES_PERSONAL_TOKEN}' "$PERSONAL_HOME/.npmrc" ||
  fail "personal npmrc should authenticate GitHub Packages with the personal token"
if grep -Fq 'octanner' "$PERSONAL_HOME/.npmrc"; then
  fail "personal npmrc should not contain work registries"
fi
[[ ! -e "$PERSONAL_HOME/.gradle/gradle.properties" ]] || fail "personal run should not write the gradle artifact"
[[ ! -e "$PERSONAL_HOME/.m2/settings.xml" ]] || fail "personal run should not write the maven artifact"
grep -Fqx 'personal' "$PERSONAL_HOME/.config/secrets/tags" || fail "an explicit --tag run should persist its selection"

# A later tag-less run on that machine reuses the persisted selection.
PATH="$FAKE_BIN:$PATH" BW_LOG_FILE="$BW_LOG_FILE" \
  bash "$REPO_ROOT/scripts/refresh-secrets.sh" --home "$PERSONAL_HOME" > "$OUTPUT_FILE"

grep -Fq 'Projecting tags: personal' "$OUTPUT_FILE" || fail "a tag-less run should reuse the persisted tag selection"
if grep -Fq 'export GITHUB_PACKAGES_TOKEN' "$PERSONAL_HOME/.config/secrets/env"; then
  fail "a tag-less rerun should stay within the persisted tags"
fi

# Unknown tags are rejected rather than silently projecting nothing.
if PATH="$FAKE_BIN:$PATH" BW_LOG_FILE="$BW_LOG_FILE" \
  bash "$REPO_ROOT/scripts/refresh-secrets.sh" --tag bogus --home "$TMP_DIR/bogus-home" > "$OUTPUT_FILE" 2>&1; then
  fail "an unknown tag should fail"
fi
grep -Fq 'Unknown tag: bogus' "$OUTPUT_FILE" || fail "an unknown tag should be explained"

printf 'refresh-secrets fake-bw verification passed\n'
