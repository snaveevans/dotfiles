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
      synthetic.new)
        printf '{"name":"synthetic.new","fields":[{"name":"token","value":"synthetic-token"}]}'
        ;;
      ebac9653-5fbd-4dac-b22d-af9a0116b6bb)
        printf '{"id":"ebac9653-5fbd-4dac-b22d-af9a0116b6bb","fields":[{"name":"access_token","value":"github-token"}]}'
        ;;
      artifactory.octanner.net)
        printf '{"name":"artifactory.octanner.net","fields":[{"name":"email","value":"user@example.com"},{"name":"access_token","value":"artifactory-token"}]}'
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
grep -Fq -- '--session fake-session-token get item synthetic.new --raw' "$BW_LOG_FILE" || fail "expected synthetic item read"
grep -Fq -- '--session fake-session-token get item ebac9653-5fbd-4dac-b22d-af9a0116b6bb --raw' "$BW_LOG_FILE" || fail "expected github packages item read"
grep -Fq -- '--session fake-session-token get item artifactory.octanner.net --raw' "$BW_LOG_FILE" || fail "expected artifactory item read"

[[ ! -e "$TARGET_HOME/.config/secrets/env" ]] || fail "dry run should not write env artifact"
[[ ! -e "$TARGET_HOME/.npmrc" ]] || fail "dry run should not write npmrc artifact"

printf 'refresh-secrets fake-bw verification passed\n'
