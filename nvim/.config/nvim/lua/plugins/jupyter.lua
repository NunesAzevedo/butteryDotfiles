-- Python / Jupyter
return {
  -- Molten: runs a Jupyter kernel from inside the buffer
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    build = ":UpdateRemotePlugins",
    ft = { "python", "markdown", "quarto", "ipynb" },
    -- lazy.nvim creates these keymaps and loads the plugin on first use
    keys = {
      { "<leader>mi", ":MoltenInit<CR>", mode = "n", desc = "Jupyter: Inicializar" },
      { "<leader>me", ":MoltenEvaluateOperator<CR>", mode = "n", desc = "Jupyter: Avaliar operador" },
      { "<leader>ml", ":MoltenEvaluateLine<CR>", mode = "n", desc = "Jupyter: Avaliar linha" },
      { "<leader>me", ":<C-u>MoltenEvaluateVisual<CR>gv", mode = "v", desc = "Jupyter: Avaliar visual" },
      { "<leader>mo", ":MoltenShowOutput<CR>", mode = "n", desc = "Jupyter: Mostrar output" },
    },
    init = function()
      -- vim.g.molten_image_provider = "image.nvim" -- temporarily disabled
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_auto_open_output = false
    end,
  },

  -- image.nvim: draws generated images (plots) inside the buffer
  {
    "3rd/image.nvim",
    opts = {
      -- Use "ueberzug" if the terminal doesn't support the Kitty graphics protocol
      backend = "kitty",
      processor = "magick_cli",
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },
    },
  },
}
