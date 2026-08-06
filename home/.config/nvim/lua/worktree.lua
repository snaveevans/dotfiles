-- Picker over `wt`, which lists git worktrees regardless of whether you or an
-- agent created them. Switching opens a Kitty tab so each worktree keeps its
-- own Neovim instance, LSP clients, and session.
local M = {}

local function wt_bin()
  local found = vim.fn.exepath("wt")
  if found ~= "" then
    return found
  end

  -- Neovim launched outside a login shell does not inherit ~/.local/bin.
  local fallback = vim.fn.expand("~/.local/bin/wt")
  if vim.fn.executable(fallback) == 1 then
    return fallback
  end

  return nil
end

-- Rows are "display<TAB>tab title<TAB>path"; fzf returns the whole line.
local function parse_entry(entry)
  local fields = vim.split(entry, "\t", { plain = true })
  return fields[3], fields[2]
end

local function tcd_to(path)
  vim.cmd.tabnew()
  vim.cmd.tcd({ args = { path } })
  vim.notify("Worktree: " .. path)
end

local function open_worktree(bin, path, title)
  if not vim.env.KITTY_WINDOW_ID then
    tcd_to(path)
    return
  end

  vim.fn.system({ bin, "tab", "--path", path, "--title", title })

  if vim.v.shell_error ~= 0 then
    vim.notify("Could not open a Kitty tab for " .. path, vim.log.levels.WARN)
    tcd_to(path)
  end
end

---@param opts? { all?: boolean }
function M.pick(opts)
  opts = opts or {}

  local bin = wt_bin()
  if not bin then
    vim.notify("wt not found; run scripts/install-home-links.sh", vim.log.levels.ERROR)
    return
  end

  local ok, fzf = pcall(require, "fzf-lua")
  if not ok then
    vim.notify("fzf-lua is not available", vim.log.levels.ERROR)
    return
  end

  local command = vim.fn.shellescape(bin) .. " list --format=fzf"
  if opts.all then
    command = command .. " --all"
  end

  fzf.fzf_exec(command, {
    prompt = opts.all and "All worktrees> " or "Worktrees> ",
    fzf_opts = {
      ["--delimiter"] = "'\\t'",
      ["--with-nth"] = "1",
      ["--no-multi"] = "",
    },
    actions = {
      ["default"] = function(selected)
        if not selected or not selected[1] then
          return
        end

        local path, title = parse_entry(selected[1])
        open_worktree(bin, path, title)
      end,
      ["ctrl-t"] = function(selected)
        if not selected or not selected[1] then
          return
        end

        tcd_to((parse_entry(selected[1])))
      end,
      ["ctrl-y"] = function(selected)
        if not selected or not selected[1] then
          return
        end

        local path = parse_entry(selected[1])
        vim.fn.setreg("+", path)
        vim.notify("Yanked " .. path)
      end,
    },
  })
end

return M
