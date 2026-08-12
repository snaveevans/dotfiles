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

# A fake `claude` on PATH stands in for `claude agents --json`: it prints
# whatever JSON file FAKE_CLAUDE_AGENTS_FILE points at, or an empty array by
# default, so agent-status tests are hermetic instead of depending on
# whatever's actually running on the machine. A fake `kitty` joins it later,
# right before the test that needs one.
FAKE_BIN="$TMP_DIR/fakebin"
mkdir -p "$FAKE_BIN"
cat >"$FAKE_BIN/claude" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "agents" ]]; then
  if [[ -n "${FAKE_CLAUDE_AGENTS_FILE:-}" && -f "$FAKE_CLAUDE_AGENTS_FILE" ]]; then
    cat "$FAKE_CLAUDE_AGENTS_FILE"
  else
    printf '[]\n'
  fi
  exit 0
fi
exit 1
EOF
chmod +x "$FAKE_BIN/claude"
CLAUDE_AGENTS_FILE="$TMP_DIR/claude-agents.json"

# Worktree semantics are the thing under test, so this drives real git inside a
# throwaway directory rather than faking git on PATH.
run_wt() {
  HOME="$FAKE_HOME" WT_WORKSPACE="$WORKSPACE" WT_ROOT="$TEST_WT_ROOT" PATH="$FAKE_BIN:$PATH" "$WT_BIN" "$@"
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
git -C "$REPO" worktree add --quiet -b agent-y "$FAKE_HOME/.local/share/opencode/worktree/repo-a-hash/agent-y"
git -C "$REPO" worktree add --quiet -b sibling "$WORKSPACE/repo-a-sibling"
git -C "$REPO" worktree add --quiet -b spaced "$SPACED_WORKTREE"

LIST_FILE="$TMP_DIR/list.tsv"
run_wt list --all --format=tsv >"$LIST_FILE"

grep -Fq "repo-a${TAB}main${TAB}main${TAB}" "$LIST_FILE" ||
  fail "the primary checkout should be classified as main"
grep -Fq "repo-a${TAB}wt${TAB}feature${TAB}" "$LIST_FILE" ||
  fail "a worktree under WT_ROOT should be classified as wt"
grep -Fq "repo-a${TAB}other${TAB}sibling${TAB}" "$LIST_FILE" ||
  fail "a worktree outside every known root should be classified as other"
grep -Fq "$SPACED_WORKTREE" "$LIST_FILE" ||
  fail "a worktree path containing spaces should survive porcelain parsing"

if grep -Fq "agent-x" "$LIST_FILE"; then
  fail "a worktree under .claude/worktrees should be excluded from discovery"
fi
if grep -Fq "agent-y" "$LIST_FILE"; then
  fail "a worktree under .local/share/opencode/worktree should be excluded from discovery"
fi

[[ "$(grep -c "^repo-a${TAB}" "$LIST_FILE")" -eq 4 ]] ||
  fail "expected four visible worktrees for repo-a (agent-owned ones are excluded)"

# repo-a-sibling is itself a linked worktree, so scanning the workspace must not
# report it as a separate repo.
if grep -q "^repo-a-sibling${TAB}" "$LIST_FILE"; then
  fail "a linked worktree in the workspace should not be scanned as its own repo"
fi

FZF_FILE="$TMP_DIR/list.fzf"
run_wt list --all --format=fzf >"$FZF_FILE"

awk -F '\t' 'NF != 3 { exit 1 }' "$FZF_FILE" ||
  fail "fzf format should emit display, title, and path fields"
grep -Fq "${TAB}repo-a:feature${TAB}" "$FZF_FILE" ||
  fail "linked worktrees should get a repo-qualified tab title"
grep -Fq "${TAB}repo-a${TAB}" "$FZF_FILE" ||
  fail "the primary checkout should get a bare repo tab title"

# Agent status comes from `claude agents --json` (faked above), keyed by
# cwd, so a worktree with a matching session (or several) should carry a
# status glyph. wt's own field for this is field 8 once `cut -f3-` (tsv
# format) has dropped rank/commit_time.
cat >"$CLAUDE_AGENTS_FILE" <<JSON
[{"cwd": "$TEST_WT_ROOT/repo-a/feature", "kind": "background", "state": "working"}]
JSON
export FAKE_CLAUDE_AGENTS_FILE="$CLAUDE_AGENTS_FILE"

AGENT_FILE="$TMP_DIR/agent.tsv"
run_wt list --all --format=tsv >"$AGENT_FILE"

[[ "$(awk -F'\t' '$3 == "feature" { print $8 }' "$AGENT_FILE")" == "● working" ]] ||
  fail "a worktree with a matching Claude Code session should show its agent status"

# A second job on the same worktree should raise the count without changing
# which state wins: working outranks done.
cat >"$CLAUDE_AGENTS_FILE" <<JSON
[
  {"cwd": "$TEST_WT_ROOT/repo-a/feature", "kind": "background", "state": "working"},
  {"cwd": "$TEST_WT_ROOT/repo-a/feature", "kind": "background", "state": "done"}
]
JSON

run_wt list --all --format=tsv >"$AGENT_FILE"

[[ "$(awk -F'\t' '$3 == "feature" { print $8 }' "$AGENT_FILE")" == "● working ×2" ]] ||
  fail "a worktree with two jobs should show the higher-priority state and a count"

# An interactive session only reports `status`, not `state`, and uses a
# different vocabulary (busy/waiting/idle/shell) - this has to translate to
# the same working/blocked/idle labels a background job's `state` produces.
cat >"$CLAUDE_AGENTS_FILE" <<JSON
[{"cwd": "$TEST_WT_ROOT/repo-a/feature", "kind": "interactive", "status": "waiting"}]
JSON

run_wt list --all --format=tsv >"$AGENT_FILE"

[[ "$(awk -F'\t' '$3 == "feature" { print $8 }' "$AGENT_FILE")" == "⏸ needs input" ]] ||
  fail "an interactive session's 'waiting' status should translate to needs input"

unset FAKE_CLAUDE_AGENTS_FILE

LOCAL_FILE="$TMP_DIR/local.tsv"
(cd "$REPO/.claude/worktrees/agent-x" && run_wt list --format=tsv) >"$LOCAL_FILE"

[[ "$(wc -l <"$LOCAL_FILE" | tr -d ' ')" -eq 4 ]] ||
  fail "repo scope from inside an excluded worktree should still resolve the whole repo"

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

MERGED_PATH="$(cd "$REPO" && run_wt new tyler/CCLOUD-2-merged)"
printf 'merged work\n' >>"$MERGED_PATH/README.md"
git -C "$MERGED_PATH" add README.md
git -C "$MERGED_PATH" commit --quiet -m "merged work"
git -C "$REPO" merge --quiet --no-edit tyler/CCLOUD-2-merged

UNMERGED_PATH="$(cd "$REPO" && run_wt new tyler/CCLOUD-3-unmerged)"
printf 'unmerged work\n' >>"$UNMERGED_PATH/README.md"
git -C "$UNMERGED_PATH" add README.md
git -C "$UNMERGED_PATH" commit --quiet -m "unmerged work"

DIRTY_PATH="$(cd "$REPO" && run_wt new tyler/CCLOUD-4-dirty)"
printf 'dirty\n' >>"$DIRTY_PATH/README.md"

CLEAN_DRY_ERR="$TMP_DIR/clean-dry.err"
(cd "$REPO" && run_wt clean --dry-run) 2>"$CLEAN_DRY_ERR"

[[ -d "$MERGED_PATH" ]] || fail "dry-run clean should not remove a merged worktree"
grep -Fq "DRY-RUN" "$CLEAN_DRY_ERR" || fail "dry-run clean should log planned actions"

CLEAN_ERR="$TMP_DIR/clean.err"
(cd "$REPO" && run_wt clean) 2>"$CLEAN_ERR"

[[ ! -d "$MERGED_PATH" ]] || fail "clean should remove a merged, clean worktree"
if git -C "$REPO" show-ref --verify --quiet "refs/heads/tyler/CCLOUD-2-merged"; then
  fail "clean should delete the branch of a removed worktree"
fi

[[ -d "$UNMERGED_PATH" ]] || fail "clean should not remove an unmerged worktree"
grep -Fq "not merged" "$CLEAN_ERR" || fail "clean should explain why it skipped an unmerged worktree"

[[ -d "$DIRTY_PATH" ]] || fail "clean should not remove a worktree with uncommitted changes"
grep -Fq "uncommitted changes" "$CLEAN_ERR" || fail "clean should explain why it skipped a dirty worktree"

[[ -d "$REPO" ]] || fail "clean should never remove the main worktree"

# agent-x and agent-y are both trivially clean and merged (never diverged
# from main), so if the exclusion in cmd_clean's own scan didn't hold, this
# run would have swept them.
[[ -d "$REPO/.claude/worktrees/agent-x" ]] ||
  fail "clean should never touch a worktree under .claude/worktrees"
[[ -d "$FAKE_HOME/.local/share/opencode/worktree/repo-a-hash/agent-y" ]] ||
  fail "clean should never touch a worktree under .local/share/opencode/worktree"

# The "no open Kitty tab" gate is the difference between `wt clean` and just
# deleting every merged worktree unconditionally, so it gets its own check
# with a fake `kitty` joining the fake `claude` already on PATH.
TAB_PATH="$(cd "$REPO" && run_wt new tyler/CCLOUD-5-tabbed)"
printf 'tabbed work\n' >>"$TAB_PATH/README.md"
git -C "$TAB_PATH" add README.md
git -C "$TAB_PATH" commit --quiet -m "tabbed work"
git -C "$REPO" merge --quiet --no-edit tyler/CCLOUD-5-tabbed

# Stateful the same way the fake `claude` is: reads whatever `kitty @ ls`
# JSON FAKE_KITTY_LS_FILE points at, or reports no tabs at all by default -
# needed now that run_wt always puts $FAKE_BIN on PATH, so the two clean
# calls below can't tell "tab open" from "tab closed" by which kitty (fake
# vs. real) happens to answer.
cat >"$FAKE_BIN/kitty" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "@" && "$2" == "ls" ]]; then
  if [[ -n "${FAKE_KITTY_LS_FILE:-}" && -f "$FAKE_KITTY_LS_FILE" ]]; then
    cat "$FAKE_KITTY_LS_FILE"
  else
    printf '[]\n'
  fi
  exit 0
fi
exit 1
EOF
chmod +x "$FAKE_BIN/kitty"

KITTY_LS_FILE="$TMP_DIR/kitty-ls.json"
cat >"$KITTY_LS_FILE" <<JSON
[{"tabs": [{"id": 1, "title": "repo-a:tyler-CCLOUD-5-tabbed"}]}]
JSON
export FAKE_KITTY_LS_FILE="$KITTY_LS_FILE"

TAB_ERR="$TMP_DIR/clean-tab.err"
(cd "$REPO" && run_wt clean) 2>"$TAB_ERR"

[[ -d "$TAB_PATH" ]] || fail "clean should not remove a worktree with an open Kitty tab"
grep -Fq "still open" "$TAB_ERR" || fail "clean should explain why it skipped an open worktree"

unset FAKE_KITTY_LS_FILE

(cd "$REPO" && run_wt clean) 2>/dev/null

[[ ! -d "$TAB_PATH" ]] || fail "clean should remove the worktree once its tab is no longer open"

# The "no live agent job" gate mirrors the open-tab gate: a worktree can be
# merged and clean but still have a Claude Code session working in it.
AGENT_PATH="$(cd "$REPO" && run_wt new tyler/CCLOUD-6-agent-busy)"
printf 'agent work\n' >>"$AGENT_PATH/README.md"
git -C "$AGENT_PATH" add README.md
git -C "$AGENT_PATH" commit --quiet -m "agent work"
git -C "$REPO" merge --quiet --no-edit tyler/CCLOUD-6-agent-busy

cat >"$CLAUDE_AGENTS_FILE" <<JSON
[{"cwd": "$AGENT_PATH", "kind": "background", "state": "working"}]
JSON
export FAKE_CLAUDE_AGENTS_FILE="$CLAUDE_AGENTS_FILE"

AGENT_CLEAN_ERR="$TMP_DIR/clean-agent.err"
(cd "$REPO" && run_wt clean) 2>"$AGENT_CLEAN_ERR"

[[ -d "$AGENT_PATH" ]] || fail "clean should not remove a worktree with a live agent job"
grep -Fq "agent job is working" "$AGENT_CLEAN_ERR" ||
  fail "clean should explain why it skipped a worktree with a live agent job"

cat >"$CLAUDE_AGENTS_FILE" <<JSON
[{"cwd": "$AGENT_PATH", "kind": "background", "state": "done"}]
JSON

(cd "$REPO" && run_wt clean) 2>/dev/null

[[ ! -d "$AGENT_PATH" ]] || fail "clean should remove the worktree once its agent job is done"

unset FAKE_CLAUDE_AGENTS_FILE

# An idle interactive session is still a live process sitting in the
# worktree, even though nothing's "happening" - clean should treat that the
# same as working/blocked, not just skip the done/failed background case.
IDLE_PATH="$(cd "$REPO" && run_wt new tyler/CCLOUD-7-agent-idle)"
printf 'agent idle work\n' >>"$IDLE_PATH/README.md"
git -C "$IDLE_PATH" add README.md
git -C "$IDLE_PATH" commit --quiet -m "agent idle work"
git -C "$REPO" merge --quiet --no-edit tyler/CCLOUD-7-agent-idle

cat >"$CLAUDE_AGENTS_FILE" <<JSON
[{"cwd": "$IDLE_PATH", "kind": "interactive", "status": "idle"}]
JSON
export FAKE_CLAUDE_AGENTS_FILE="$CLAUDE_AGENTS_FILE"

IDLE_CLEAN_ERR="$TMP_DIR/clean-idle.err"
(cd "$REPO" && run_wt clean) 2>"$IDLE_CLEAN_ERR"

[[ -d "$IDLE_PATH" ]] || fail "clean should not remove a worktree with a live idle interactive session"
grep -Fq "agent job is idle" "$IDLE_CLEAN_ERR" ||
  fail "clean should explain why it skipped a worktree with a live idle session"

unset FAKE_CLAUDE_AGENTS_FILE

(cd "$REPO" && run_wt clean) 2>/dev/null

[[ ! -d "$IDLE_PATH" ]] || fail "clean should remove the worktree once the interactive session is gone"

printf 'wt verification passed\n'
