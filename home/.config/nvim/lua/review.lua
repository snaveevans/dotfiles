-- Review drawer: a left-side list of changed files for holistic review.
-- `<leader>gr` opens it. `Enter` on a modified file opens that file in
-- Diffview (its own tab, so this list stays put); `Enter` on a brand-new
-- file opens it as a regular file beside the list. `r` refreshes, `q`
-- closes.
local M = {}

local PANEL_NAME = "review://files"
local PANEL_WIDTH = 40

local ns = vim.api.nvim_create_namespace("review")

-- Buffer state, keyed by panel buffer number.
local panels = {}

-- Parse `git status --porcelain=v1` output into repo-relative paths.
-- Returns `{ modified = {...}, new = {...} }`, both sorted.
function M.parse(output)
  local modified = {}
  local new = {}
  for _, line in ipairs(vim.split(output, "\n", { plain = true })) do
    if #line > 3 then
      local x = line:sub(1, 1)
      local y = line:sub(2, 2)
      local path = line:sub(4)
      -- Renames show as `old -> new`; review the new name.
      local arrow = path:find(" -> ", 1, true)
      if arrow ~= nil then
        path = path:sub(arrow + 4)
      end
      if path:sub(1, 1) == '"' then
        path = path:sub(2, -2)
      end
      if x == "?" and y == "?" then
        table.insert(new, path)
      else
        table.insert(modified, path)
      end
    end
  end
  table.sort(modified)
  table.sort(new)
  return { modified = modified, new = new }
end

local function toplevel_for(buf)
  local name = vim.api.nvim_buf_get_name(buf)
  local dir = vim.fn.fnamemodify(name ~= "" and name or vim.fn.getcwd(), ":h")
  local out = vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait()
  if out.code ~= 0 then
    return nil
  end
  return vim.trim(out.stdout)
end

local function visible_panel()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if panels[vim.api.nvim_win_get_buf(win)] ~= nil then
      return win
    end
  end
  return nil
end

local function render(buf, entries)
  local lines = {}
  local paths = {}
  local new_set = {}
  local headers = {}
  local new_lines = {}
  local function section(title, list, is_new)
    if #list == 0 then
      return
    end
    if #lines > 0 then
      table.insert(lines, "")
    end
    table.insert(headers, #lines + 1)
    table.insert(lines, title .. " (" .. #list .. ")")
    for _, path in ipairs(list) do
      table.insert(lines, path)
      paths[#lines] = path
      if is_new then
        new_set[path] = true
        table.insert(new_lines, #lines)
      end
    end
  end
  section("Modified", entries.modified, false)
  section("New", entries.new, true)
  table.insert(lines, "")
  table.insert(lines, "Enter open · r refresh · q close")

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, lnum in ipairs(headers) do
    vim.api.nvim_buf_add_highlight(buf, ns, "Title", lnum - 1, 0, -1)
  end
  for _, lnum in ipairs(new_lines) do
    vim.api.nvim_buf_add_highlight(buf, ns, "DiffAdd", lnum - 1, 0, -1)
  end
  return { paths = paths, new_set = new_set }
end

local function collect(toplevel)
  local out = vim.system({ "git", "-C", toplevel, "status", "--porcelain=v1", "-uall" }, { text = true }):wait()
  if out.code ~= 0 then
    return nil
  end
  return M.parse(out.stdout or "")
end

-- Rebuild the panel buffer in place.
function M.refresh()
  local buf = vim.api.nvim_get_current_buf()
  local state = panels[buf]
  if state == nil then
    return
  end
  local entries = collect(state.toplevel)
  if entries == nil then
    vim.notify("git status failed", vim.log.levels.ERROR)
    return
  end
  local rendered = render(buf, entries)
  state.paths = rendered.paths
  state.new_set = rendered.new_set
end

function M.open()
  local win = visible_panel()
  if win ~= nil then
    vim.api.nvim_win_close(win, false)
    return
  end

  local toplevel = toplevel_for(vim.api.nvim_get_current_buf())
  if toplevel == nil then
    vim.notify("Not in a git repository", vim.log.levels.WARN)
    return
  end

  local entries = collect(toplevel)
  if entries == nil then
    vim.notify("git status failed", vim.log.levels.ERROR)
    return
  end
  if #entries.modified == 0 and #entries.new == 0 then
    vim.notify("No changed files", vim.log.levels.INFO)
    return
  end

  vim.cmd("topleft " .. PANEL_WIDTH .. "vnew")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  pcall(vim.api.nvim_buf_set_name, buf, PANEL_NAME)
  panels[buf] = { toplevel = toplevel, paths = {}, new_set = {} }
  vim.api.nvim_buf_attach(buf, false, {
    on_detach = function()
      panels[buf] = nil
    end,
  })
  local rendered = render(buf, entries)
  panels[buf].paths = rendered.paths
  panels[buf].new_set = rendered.new_set
  vim.keymap.set("n", "<CR>", function()
    M.open_at_cursor()
  end, { buffer = buf, silent = true, desc = "Open file review" })
  vim.keymap.set("n", "r", function()
    M.refresh()
  end, { buffer = buf, silent = true, desc = "Refresh review list" })
  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf, silent = true, desc = "Close review list" })
end

-- Open the file under the cursor: brand-new files as regular files beside
-- the list, everything else in Diffview (which takes its own tab, leaving
-- this list in place).
function M.open_at_cursor()
  local buf = vim.api.nvim_get_current_buf()
  local state = panels[buf]
  if state == nil then
    return
  end
  local path = state.paths[vim.api.nvim_win_get_cursor(0)[1]]
  if path == nil then
    return
  end
  local abspath = state.toplevel .. "/" .. path
  if state.new_set[path] then
    -- Stay in this tab: `wincmd p` could jump into a Diffview tab that was
    -- focused more recently.
    local panel_winid = vim.api.nvim_get_current_win()
    local target = nil
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if win ~= panel_winid then
        target = win
        break
      end
    end
    if target == nil then
      vim.cmd("rightbelow vsplit")
    else
      vim.api.nvim_set_current_win(target)
    end
    vim.cmd("edit " .. vim.fn.fnameescape(abspath))
  else
    vim.cmd("DiffviewOpen main -- " .. vim.fn.fnameescape(abspath))
  end
end

return M
