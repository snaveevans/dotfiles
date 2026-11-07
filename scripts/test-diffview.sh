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
REVIEW="$REPO_ROOT/home/.config/nvim/lua/review.lua"

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
[[ -f "$REVIEW" ]] || fail "review module is missing: $REVIEW"

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
local review_path = os.getenv("DIFFVIEW_TEST_REVIEW")
local home = os.getenv("HOME")
vim.opt.rtp:append(home .. "/.local/share/nvim/lazy/diffview.nvim")
vim.opt.rtp:append(home .. "/.local/share/nvim/lazy/plenary.nvim")

require("diffview").setup({ use_icons = false })
vim.cmd("runtime plugin/diffview.lua")
vim.cmd("cd " .. vim.fn.fnameescape(fixture))

local lib = require("diffview.lib")
if phase == "panel" then
  local review = dofile(review_path)
  -- Porcelain edge cases: renames review under the new name, quoted
  -- paths are unquoted.
  local parsed = review.parse('R  old.txt -> renamed.txt\n?? "sp ace.txt"\n M a.txt\n')
  assert(
    parsed.modified[1] == "a.txt" and parsed.modified[2] == "renamed.txt",
    "parse should split renames and sort modified"
  )
  assert(parsed.new[1] == "sp ace.txt", "parse should unquote new files")
  vim.cmd("edit a.txt")
  review.open()
  local panel = nil
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win)):find("review://files", 1, true) then
      panel = win
    end
  end
  assert(panel ~= nil, "review panel did not open")
  local buf = vim.api.nvim_win_get_buf(panel)
  local function find_line(wanted)
    for lnum, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
      if line == wanted then
        return lnum
      end
    end
    return nil
  end
  assert(find_line("Modified (1)") ~= nil, "panel is missing the Modified section")
  assert(find_line("New (1)") ~= nil, "panel is missing the New section")
  local tabs_before = #vim.api.nvim_list_tabpages()
  vim.api.nvim_win_set_cursor(panel, { find_line("a.txt"), 0 })
  vim.api.nvim_set_current_win(panel)
  review.open_at_cursor()
  assert(vim.wait(15000, function()
    return #vim.api.nvim_list_tabpages() == tabs_before + 1 and lib.get_current_view() ~= nil
  end), "modified file did not open in a new Diffview tab")
  -- The list must survive in its own tab.
  vim.cmd("tabprevious")
  local panel_gone = true
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      panel_gone = false
    end
  end
  assert(not panel_gone, "review panel did not stay open")
  -- A brand-new file opens as a regular file beside the list, same tab.
  vim.api.nvim_set_current_win(panel)
  vim.api.nvim_win_set_cursor(panel, { find_line("new.txt"), 0 })
  local tabs_before_new = #vim.api.nvim_list_tabpages()
  review.open_at_cursor()
  local shown = false
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local name = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
    if name:sub(-7) == "new.txt" then
      shown = true
    end
  end
  assert(shown, "new file did not open beside the list")
  assert(#vim.api.nvim_list_tabpages() == tabs_before_new, "new file should not open a new tab")
  -- Toggling closes the list again.
  vim.api.nvim_set_current_win(panel)
  review.open()
  local closed = true
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      closed = false
    end
  end
  assert(closed, "second toggle did not close the review panel")
  print("PHASE_PASS:" .. phase)
  vim.cmd("qa!")
elseif phase == "plain" then
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
  DIFFVIEW_TEST_FIXTURE="$FIXTURE" DIFFVIEW_TEST_SPEC="$SPEC" DIFFVIEW_TEST_REVIEW="$REVIEW" \
    nvim --headless --noplugin -u NONE -l "$TMP_DIR/driver.lua" "$1" 2>&1 |
    grep -Fq "PHASE_PASS:$1" ||
    fail "diffview regression failed in phase $1"
}

run_phase diff

run_phase plain

run_phase panel

git -C "$FIXTURE" add a.txt
git -C "$FIXTURE" commit --quiet -m "agent change"

run_phase history

printf 'diffview review: PASS (diff + plain + panel + history phases)\n'
