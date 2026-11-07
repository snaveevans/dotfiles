-- Review agent-made changes with diffview.nvim.
-- `<leader>gdf` shows everything that changed in the current file since `main`
-- (committed iterations plus uncommitted work). `<leader>gdh` walks the same
-- file commit by commit instead.
local function current_file()
  local path = vim.fn.expand("%:p")
  if path == "" then
    vim.notify("No file in the current buffer", vim.log.levels.WARN)
    return nil
  end
  return path
end

local function ask_target()
  local target = vim.fn.input("Diff against [main]: ")
  if target == nil then
    return nil
  end
  if target == "" then
    return "main"
  end
  return target
end

local function diff_current_file_against(target)
  local path = current_file()
  if path == nil then
    return
  end
  if target == nil or target == "" then
    target = ask_target()
  end
  if target == nil then
    return
  end
  vim.cmd("DiffviewOpen " .. target .. " -- " .. vim.fn.fnameescape(path))
end

-- Diffview rev types, matching diffview's RevType enum (LOCAL=1, COMMIT=2,
-- STAGE=3). Used to translate the current entry into `git diff` arguments.
local REV_LOCAL = 1
local REV_COMMIT = 2
local REV_STAGE = 3

-- Build the `git diff` arguments that reproduce the current entry as a
-- unified diff. Returns the arg list, or nil plus a message when the entry
-- has nothing diffable. Diffview's single-pane `diff1_plain` layout cannot
-- render a 2-way diff (it drops a side and shows a plain file), so the
-- toggle below shells out to git instead.
local function with_paths(base, paths)
  for _, path in ipairs(paths) do
    table.insert(base, path)
  end
  return base
end

local function unified_args(toplevel, entry)
  if entry.path == nil or entry.path == "" or entry.revs == nil then
    return nil, "No diff entry under cursor"
  end
  local paths = { entry.path }
  if entry.oldpath ~= nil and entry.oldpath ~= "" and entry.oldpath ~= entry.path then
    paths = { entry.oldpath, entry.path }
  end
  if entry.status == "?" then
    return { "--no-index", "--", "/dev/null", entry.path }, nil
  end
  local a, b = entry.revs.a, entry.revs.b
  if a == nil or b == nil then
    return nil, "No diff entry under cursor"
  end
  if b.type == REV_LOCAL then
    if a.type ~= REV_COMMIT or a.commit == nil then
      return nil, "Cannot render a unified diff for this entry"
    end
    return with_paths({ "-M", a.commit, "--" }, paths), nil
  end
  if b.type == REV_STAGE then
    if a.type ~= REV_COMMIT or a.commit == nil then
      return nil, "Cannot render a unified diff for this entry"
    end
    return with_paths({ "--cached", "-M", a.commit, "--" }, paths), nil
  end
  if a.type == REV_COMMIT and b.type == REV_COMMIT and a.commit ~= nil and b.commit ~= nil then
    return with_paths({ "-M", a.commit, b.commit, "--" }, paths), nil
  end
  return nil, "Cannot render a unified diff for this entry"
end

-- Run `git diff` with the given args and show the output as a single-pane
-- unified diff in a new tab.
local function open_unified(title, toplevel, args)
  local git_argv = { "git", "-C", toplevel, "diff" }
  for _, arg in ipairs(args) do
    table.insert(git_argv, arg)
  end
  local result = vim.system(git_argv, { text = true }):wait()
  -- `--no-index` follows classic diff exit codes (1 when different), while
  -- in-repo `git diff` exits 0 either way, so only other codes are errors.
  if result.code ~= 0 and result.code ~= 1 then
    vim.notify("git diff failed: " .. (result.stderr or ""), vim.log.levels.ERROR)
    return
  end
  if result.stdout == nil or result.stdout == "" then
    vim.notify("No differences for this file", vim.log.levels.INFO)
    return
  end

  vim.cmd("tabnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(result.stdout:gsub("\n$", ""), "\n", { plain = true }))
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = false
  vim.bo[buf].readonly = true
  vim.b[buf].diffview_unified = true
  pcall(vim.api.nvim_buf_set_name, buf, title)
  vim.keymap.set("n", "q", "<cmd>bdelete<cr>", { buffer = buf, silent = true, desc = "Close unified diff" })
end

-- Unified diff for a plain file buffer outside any Diffview, compared
-- against main. This is the path for brand-new (untracked) files, which
-- Diffview never lists when comparing against a rev.
local function unified_for_file()
  local path = current_file()
  if path == nil then
    return
  end
  local dir = vim.fn.fnamemodify(path, ":h")
  local toplevel_out = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if toplevel_out.code ~= 0 then
    vim.notify("Not in a git repository", vim.log.levels.WARN)
    return
  end
  local toplevel = vim.trim(toplevel_out.stdout)
  local rel = path:sub(#toplevel + 2)
  local tracked = vim.system({ "git", "-C", toplevel, "ls-files", "--error-unmatch", rel }, { text = true }):wait()
  if tracked.code == 0 then
    open_unified("unified-diff: " .. rel, toplevel, { "main", "--", rel })
  else
    open_unified("unified-diff: " .. rel, toplevel, { "--no-index", "--", "/dev/null", rel })
  end
end

-- Show the current entry as a single-pane unified diff in a new tab, or
-- close that tab again when invoked from inside it. Covers small screens
-- and large fonts, where the split view is too narrow to read. Outside a
-- Diffview, falls back to the current file against main, so brand-new
-- files (which Diffview never lists) stay reviewable.
local function toggle_unified()
  if vim.b.diffview_unified then
    vim.cmd("bdelete")
    return
  end

  local lib_ok, lib = pcall(require, "diffview.lib")
  local view = lib_ok and lib.get_current_view() or nil
  if view == nil then
    unified_for_file()
    return
  end
  local entry = view.cur_entry
  if entry == nil and type(view.cur_file) == "function" then
    local ok, file_entry = pcall(function()
      return view:cur_file()
    end)
    if ok then
      entry = file_entry
    end
  end
  if entry == nil then
    vim.notify("No diff entry under cursor", vim.log.levels.WARN)
    return
  end

  local adapter = view.adapter
  local toplevel = adapter ~= nil and adapter.ctx ~= nil and adapter.ctx.toplevel or nil
  if toplevel == nil or toplevel == "" then
    vim.notify("Cannot determine the git top-level", vim.log.levels.WARN)
    return
  end

  local args, err = unified_args(toplevel, entry)
  if args == nil then
    vim.notify(err, vim.log.levels.WARN)
    return
  end
  open_unified("unified-diff: " .. entry.path, toplevel, args)
end

return {
  {
    "sindrets/diffview.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewToggleFiles",
      "DiffviewFocusFiles",
      "DiffviewRefresh",
      "DiffviewFileHistory",
    },
    keys = {
      {
        "<leader>gdf",
        function()
          diff_current_file_against("main")
        end,
        desc = "Diff this file vs main",
      },
      {
        "<leader>gdF",
        function()
          diff_current_file_against()
        end,
        desc = "Diff this file vs branch...",
      },
      {
        "<leader>gdm",
        "<cmd>DiffviewOpen main<cr>",
        desc = "Diff branch vs main",
      },
      {
        "<leader>gdh",
        function()
          local path = current_file()
          if path == nil then
            return
          end
          vim.cmd("DiffviewFileHistory " .. vim.fn.fnameescape(path))
        end,
        desc = "File history for this file",
      },
      {
        "<leader>gdu",
        function()
          toggle_unified()
        end,
        desc = "Toggle unified diff",
      },
      {
        "<leader>gr",
        function()
          require("review").open()
        end,
        desc = "Review changed files",
      },
      {
        "<leader>gdx",
        "<cmd>DiffviewClose<cr>",
        desc = "Close diff view",
      },
    },
    opts = {
      enhanced_diff_hl = true,
    },
  },
}
