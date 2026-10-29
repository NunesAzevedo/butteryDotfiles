-- Language-agnostic code navigation helpers
return {
  -- Sticky scroll: pins the enclosing function/class/loop header at the top of the window
  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
      max_lines = 3, -- never take more than 3 lines of the screen
      multiline_threshold = 1, -- show only the first line of multi-line signatures
      trim_scope = "outer", -- when over max_lines, drop the outermost scopes
    },
  },

  -- Outline: side panel with the file's structure (classes, methods, functions)
  {
    "stevearc/aerial.nvim",
    cmd = { "AerialToggle", "AerialNavToggle" },
    keys = {
      { "<leader>o", "<cmd>AerialToggle!<CR>", desc = "Outline toggle" },
    },
    opts = {
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = {
        default_direction = "prefer_right",
        min_width = 30,
      },
      show_guides = true,
    },
  },
}
