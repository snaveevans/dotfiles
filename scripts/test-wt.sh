#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
WT_BIN="$REPO_ROOT/home/.local/bin/wt"

# Resolved so path comparisons match what git reports (macOS /var symlink).
TMP_DIR="$(cd "$(mktemp -d)" && pwd -P)"

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT

fail() {
  printf 'Test failed: %s\n' "$*" >&2
  exit 1
}

command -v git >/dev/null 2>&1 || fail "git is required for this verification script"
[[ -x "$WT_BIN" ]] || fail "wt is missing or not executable: $WT_BIN"

TAB=$'\t'
FAKE_HOME="$TMP_DIR/home"
WORKSPACE="$TMP_DIR/workspace"
TEST_WT_ROOT="$TMP_DIR/worktrees"
REPO="$WORKSPACE/repo-a"
SPACED_WORKTREE="$TMP_DIR/space dir/with space"

# Worktree semantics are the thing under test, so this drives real git inside a
# throwaway directory rather than faking git on PATH.
run_wt() {
  HOME="$FAKE_HOME" WT_WORKSPACE="$WORKSPACE" WT_ROOT="$TEST_WT_ROOT" "$WT_BIN" "$@"
}

mkdir -p "$FAKE_HOME" "$WORKSPACE" "$TEST_WT_ROOT" "$TMP_DIR/space dir"

git -c init.defaultBranch=main init --quiet "$REPO"
git -C "$REPO" config user.email "user@example.com"
git -C "$REPO" config user.name "Test User"
printf 'hello\n' >"$REPO/README.md"
git -C "$REPO" add README.md
git -C "$REPO" commit --quiet -m "initial commit"

git -C "$REPO" worktree add --quiet -b feature "$TEST_WT_ROOT/repo-a/feature"
git -C "$REPO" worktree add --quiet -b agent-x "$REPO/.claude/worktrees/agent-x"
git -C "$REPO" worktree add --quiet -b sibling "$WORKSPACE/repo-a-sibling"
git -C "$REPO" worktree add --quiet -b spaced "$SPACED_WORKTREE"

LIST_FILE="$TMP_DIR/list.tsv"
run_wt list --all --format=tsv >"$LIST_FILE"

grep -Fq "repo-a${TAB}main${TAB}main${TAB}" "$LIST_FILE" ||
  fail "the primary checkout should be classified as main"
grep -Fq "repo-a${TAB}wt${TAB}feature${TAB}" "$LIST_FILE" ||
  fail "a worktree under WT_ROOT should be classified as wt"
grep -Fq "repo-a${TAB}claude${TAB}agent-x${TAB}" "$LIST_FILE" ||
  fail "a worktree under .claude/worktrees should be classified as claude"
grep -Fq "repo-a${TAB}other${TAB}sibling${TAB}" "$LIST_FILE" ||
  fail "a worktree outside every known root should be classified as other"
grep -Fq "$SPACED_WORKTREE" "$LIST_FILE" ||
  fail "a worktree path containing spaces should survive porcelain parsing"

[[ "$(grep -c "^repo-a${TAB}" "$LIST_FILE")" -eq 5 ]] ||
  fail "expected five worktrees for repo-a"

# repo-a-sibling is itself a linked worktree, so scanning the workspace must not
# report it as a separate repo.
if grep -q "^repo-a-sibling${TAB}" "$LIST_FILE"; then
  fail "a linked worktree in the workspace should not be scanned as its own repo"
fi

FZF_FILE="$TMP_DIR/list.fzf"
run_wt list --all --format=fzf >"$FZF_FILE"

awk -F '\t' 'NF != 3 { exit 1 }' "$FZF_FILE" ||
  fail "fzf format should emit display, title, and path fields"
grep -Fq "${TAB}repo-a:agent-x${TAB}" "$FZF_FILE" ||
  fail "linked worktrees should get a repo-qualified tab title"
grep -Fq "${TAB}repo-a${TAB}" "$FZF_FILE" ||
  fail "the primary checkout should get a bare repo tab title"

LOCAL_FILE="$TMP_DIR/local.tsv"
(cd "$REPO/.claude/worktrees/agent-x" && run_wt list --format=tsv) >"$LOCAL_FILE"

[[ "$(wc -l <"$LOCAL_FILE" | tr -d ' ')" -eq 5 ]] ||
  fail "repo scope from inside a linked worktree should resolve the whole repo"

DRY_OUT="$TMP_DIR/new-dry.out"
DRY_ERR="$TMP_DIR/new-dry.err"
(cd "$REPO" && run_wt new tyler/CCLOUD-1-demo --dry-run) >"$DRY_OUT" 2>"$DRY_ERR"

[[ ! -s "$DRY_OUT" ]] || fail "dry run should not print a path to switch into"
[[ ! -e "$TEST_WT_ROOT/repo-a/tyler-CCLOUD-1-demo" ]] || fail "dry run should not create a worktree"
grep -Fq "DRY-RUN" "$DRY_ERR" || fail "dry run should log the planned actions"

NEW_PATH="$(cd "$REPO" && run_wt new tyler/CCLOUD-1-demo)"

[[ "$NEW_PATH" == "$TEST_WT_ROOT/repo-a/tyler-CCLOUD-1-demo" ]] ||
  fail "branch names should be slugified into WT_ROOT/<repo>/<slug>, got: $NEW_PATH"
[[ -d "$NEW_PATH" ]] || fail "wt new should create the worktree directory"

printf 'dirty\n' >>"$NEW_PATH/README.md"

RM_ERR="$TMP_DIR/rm-dirty.err"
if (cd "$REPO" && run_wt rm --path "$NEW_PATH") 2>"$RM_ERR"; then
  fail "rm should refuse a worktree with uncommitted changes"
fi

grep -Fq "uncommitted changes" "$RM_ERR" || fail "rm should explain why it refused"
[[ -d "$NEW_PATH" ]] || fail "a refused rm should leave the worktree in place"

RM_MAIN_ERR="$TMP_DIR/rm-main.err"
if (cd "$REPO" && run_wt rm --path "$REPO") 2>"$RM_MAIN_ERR"; then
  fail "rm should refuse the main worktree"
fi

grep -Fq "main worktree" "$RM_MAIN_ERR" || fail "rm should explain why it refused the main worktree"
[[ -d "$REPO" ]] || fail "a refused rm should leave the main worktree in place"

(cd "$REPO" && run_wt rm --path "$NEW_PATH" --force --delete-branch)

[[ ! -d "$NEW_PATH" ]] || fail "forced rm should remove the worktree directory"

if git -C "$REPO" show-ref --verify --quiet "refs/heads/tyler/CCLOUD-1-demo"; then
  fail "--delete-branch should delete the branch"
fi

printf 'wt verification passed\n'
