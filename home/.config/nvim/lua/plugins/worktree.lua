return {
  {
    "ibhagwan/fzf-lua",
    keys = {
      {
        "<leader>gw",
        function()
          require("worktree").pick()
        end,
        desc = "Worktrees (this repo)",
      },
      {
        "<leader>gW",
        function()
          require("worktree").pick({ all = true })
        end,
        desc = "Worktrees (all repos)",
      },
    },
  },
}
