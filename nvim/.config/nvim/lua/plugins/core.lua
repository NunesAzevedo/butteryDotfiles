-- Ajustes nos plugins que já vêm com o NvChad (LSP, formatação, treesitter).
-- O lazy.nvim mescla estas tabelas com as specs originais do NvChad.
return {
  -- Formatação (configurada em lua/configs/conform.lua)
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- LSP (lista de servidores em lua/configs/lspconfig.lua,
  -- ajustes por servidor em after/lsp/<servidor>.lua)
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Treesitter: parsers para destaque de sintaxe
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "latex",
        "bibtex",
        "c",
        "cpp",
        "cmakelang",
        "python",
        "markdown",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        disable = { "latex" }, -- o VimTeX cuida do destaque de LaTeX
      },
    },
  },
}
