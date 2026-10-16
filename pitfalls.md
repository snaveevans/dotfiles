# Pitfalls (errors + fixes)

This file is a running log of small-but-annoying issues we've hit, plus the fix that worked.

## 2026-10-16 — OpenCode worktree tool scope

### Symptom

`tools.opencode.worktree_remove` rejected a manually created Git worktree as not belonging to the current project.

### Cause

The OpenCode worktree tool only manages worktrees it registered; this checkout was created with `git worktree add`.

### Fix

Use `git -C <repo> worktree remove <path>` for a clean, manually created worktree.

### How to avoid next time

Use OpenCode's worktree tools only for OpenCode-managed worktrees; use Git CLI to inspect and remove manually managed ones.

## 2026-07-21 - Kitty tab title prefix collision

### Symptom

Selecting a tab named `prism` could focus `prism-header` or `prism-ui`.

### Cause

Kitty tab matching can return titles with a shared prefix; the selector focused the first returned match.

### Fix

Filter `boss.match_tabs()` results by an exact `tab.effective_title == dir_name` comparison in `home/.config/kitty/kitty_selector.py` before focusing a tab.

### How to avoid next time

When a selected label identifies a Kitty tab, compare it with `Tab.effective_title`; `Tab.title` is the active window's title instead.
