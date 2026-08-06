-- Globs that stay visible in the file picker even when .gitignore hides them.
-- `.env*` covers the naming variants in the wild: `.env`, `.env.local`, `.env-local`.
local unignore_globs = {
  ".env*",
}

-- fzf-lua's stock exclusions, kept so the normal pass behaves as it always has.
local exclude_globs = {
  ".git",
  ".jj",
}

-- The allow-list pass walks past .gitignore, so it needs its own guard against
-- descending into dependency directories.
local unignore_exclude_globs = {
  ".git",
  ".jj",
  "node_modules",
}

local function glob_args(globs, negate)
  local args = {}
  for _, glob in ipairs(globs) do
    table.insert(args, string.format([[-g "%s%s"]], negate and "!" or "", glob))
  end
  return table.concat(args, " ")
end

-- rg hides everything .gitignore lists, so `.env` files never show up in the picker.
-- Search twice instead: once normally with the allow-listed globs held back, then
-- again for only those globs with .gitignore turned off. The passes are disjoint, so
-- no file is listed twice. Keeping `rg` as the first word lets fzf-lua's hidden and
-- ignore toggles keep injecting their flags into the first pass.
local function files_cmd()
  local respect_gitignore = table.concat({
    "rg --color=never --files --hidden",
    glob_args(exclude_globs, true),
    glob_args(unignore_globs, true),
  }, " ")
  -- `-u` is rg's short `--no-ignore`; spelling it out would collide with the substring
  -- fzf-lua looks for when its ignore toggle decides whether to add the flag itself.
  local allow_listed = table.concat({
    "rg --color=never --files --hidden -u",
    glob_args(unignore_exclude_globs, true),
    glob_args(unignore_globs, false),
  }, " ")
  return respect_gitignore .. " ; " .. allow_listed
end

return {
  {
    "mason-org/mason.nvim",
    enabled = not vim.g.vscode, -- Disable in VSCode
    opts = {
      ensure_installed = {
        "stylua",
        "shellcheck",
        "shfmt",
        "lua-language-server",
        "eslint-lsp",
        "prettier",
        "vtsls",
      },
    },
  },
  {
    "ibhagwan/fzf-lua",
    enabled = not vim.g.vscode, -- Disable in VSCode
    opts = {
      fzf_opts = {
        ["--layout"] = "default",
      },
      files = {
        cmd = files_cmd(),
      },
    },
    keys = {
      {
        "<leader><leader>",
        function()
          require("fzf-lua").files()
        end,
        desc = "FzF Files",
      },
      {
        "<leader>p",
        function()
          require("fzf-lua").files()
        end,
        desc = "FzF Files",
      },
      {
        "<leader>o",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "FzF Buffers",
      },
    },
  },
}
