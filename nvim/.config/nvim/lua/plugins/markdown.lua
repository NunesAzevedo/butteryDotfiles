-- Markdown
return {
  {
    "ellisonleao/glow.nvim",
    config = true,
    cmd = "Glow",
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    ft = { "markdown" },
    opts = {},
  },
}
