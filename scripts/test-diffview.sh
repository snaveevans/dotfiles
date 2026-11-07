#!/usr/bin/env bash
#
# Regression test for the diffview.nvim `<leader>gdu` unified-diff toggle
# (see home/.config/nvim/lua/plugins/diffview.lua). It opens a real
# Diffview in headless Neovim, invokes the toggle callback from the plugin
# spec, and asserts the result is a genuine unified diff buffer carrying
# ---/+++/@@ markers and the changed lines - not just a collapsed pane.
#
# Phase one covers a working-tree diff (`DiffviewOpen main -- file`, the
# `gdf` workflow); phase two covers a brand-new untracked file opened
# directly (Diffview never lists those); phase three commits the change and
# covers file history (`DiffviewFileHistory`, the `gdh` workflow). Skips
# gracefully when Neovim or the lazy-installed diffview/plenary plugins are
# unavailable.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SPEC="$REPO_ROOT/home/.config/nvim/lua/plugins/diffview.lua"

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

skip() {
  printf 'Skipping diffview test: %s\n' "$*" >&2
  exit 0
}

command -v git >/dev/null 2>&1 || fail "git is required for this verification script"
command -v nvim >/dev/null 2>&1 || skip "nvim is not installed"
[[ -f "$SPEC" ]] || fail "diffview plugin spec is missing: $SPEC"

LAZY_DIR="$HOME/.local/share/nvim/lazy"
[[ -d "$LAZY_DIR/diffview.nvim" ]] || skip "diffview.nvim is not installed under $LAZY_DIR"
[[ -d "$LAZY_DIR/plenary.nvim" ]] || skip "plenary.nvim is not installed under $LAZY_DIR"

FIXTURE="$TMP_DIR/repo"
mkdir -p "$FIXTURE"
git -c init.defaultBranch=main init --quiet "$FIXTURE"
git -C "$FIXTURE" config user.email "user@example.com"
git -C "$FIXTURE" config user.name "Test User"
printf 'line1\nline2\nline3\n' >"$FIXTURE/a.txt"
git -C "$FIXTURE" add a.txt
git -C "$FIXTURE" commit --quiet -m "initial commit"
printf 'line1\nline2 changed\nline3\nline4 added\n' >"$FIXTURE/a.txt"
printf 'fresh\nfile\n' >"$FIXTURE/new.txt"

# Headless driver: opens the view for the given phase, runs the gdu toggle
# straight from the repo's plugin spec, and asserts on buffer content.
cat >"$TMP_DIR/driver.lua" <<EOF
local phase = _G.arg[1]
local fixture = os.getenv("DIFFVIEW_TEST_FIXTURE")
local spec_path = os.getenv("DIFFVIEW_TEST_SPEC")
local home = os.getenv("HOME")
vim.opt.rtp:append(home .. "/.local/share/nvim/lazy/diffview.nvim")
vim.opt.rtp:append(home .. "/.local/share/nvim/lazy/plenary.nvim")

require("diffview").setup({ use_icons = false })
vim.cmd("runtime plugin/diffview.lua")
vim.cmd("cd " .. vim.fn.fnameescape(fixture))

local lib = require("diffview.lib")
if phase == "plain" then
  -- Brand-new untracked file, no Diffview involved: the reported gap.
  vim.cmd("edit new.txt")
else
  vim.cmd("edit a.txt")
  if phase == "history" then
    vim.cmd("DiffviewFileHistory a.txt")
  else
    vim.cmd("DiffviewOpen main -- a.txt")
  end
end

local function cur_entry()
  local view = lib.get_current_view()
  if view == nil then
    return nil
  end
  if view.cur_entry ~= nil then
    return view.cur_entry
  end
  if type(view.cur_file) == "function" then
    local ok, entry = pcall(function()
      return view:cur_file()
    end)
    if ok then
      return entry
    end
  end
  return nil
end
if phase ~= "plain" then
  assert(vim.wait(15000, function()
    return cur_entry() ~= nil
  end), "diffview never opened (" .. phase .. ")")
end

local spec = dofile(spec_path)
local toggle = nil
for _, key in ipairs(spec[1].keys) do
  if key[1] == "<leader>gdu" then
    toggle = key[2]
  end
end
assert(toggle ~= nil, "gdu key missing from plugin spec")

local function unified_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[buf].diffview_unified then
      return buf
    end
  end
  return nil
end

toggle()
assert(vim.wait(15000, function()
  return unified_buf() ~= nil
end), "gdu opened no unified diff buffer (" .. phase .. ")")
local text = table.concat(vim.api.nvim_buf_get_lines(unified_buf(), 0, -1, false), "\n")
local markers = { "--- a/a.txt", "+++ b/a.txt", "@@", "-line2", "+line2 changed" }
if phase == "plain" then
  markers = { "+++ b/new.txt", "@@", "+fresh", "+file" }
end
for _, marker in ipairs(markers) do
  assert(text:find(marker, 1, true) ~= nil, "unified diff is missing " .. marker .. " (" .. phase .. ")")
end

toggle()
assert(vim.wait(5000, function()
  return unified_buf() == nil
end), "unified buffer did not close on second toggle (" .. phase .. ")")
if phase ~= "plain" then
  assert(lib.get_current_view() ~= nil, "diffview is gone after closing the unified buffer (" .. phase .. ")")
end
print("PHASE_PASS:" .. phase)
vim.cmd("qa!")
EOF

run_phase() {
  DIFFVIEW_TEST_FIXTURE="$FIXTURE" DIFFVIEW_TEST_SPEC="$SPEC" \
    nvim --headless --noplugin -u NONE -l "$TMP_DIR/driver.lua" "$1" 2>&1 |
    grep -Fq "PHASE_PASS:$1" ||
    fail "diffview regression failed in phase $1"
}

run_phase diff

run_phase plain

git -C "$FIXTURE" add a.txt
git -C "$FIXTURE" commit --quiet -m "agent change"

run_phase history

printf 'diffview unified toggle: PASS (diff + plain + history phases)\n'
