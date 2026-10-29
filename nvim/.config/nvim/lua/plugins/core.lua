-- Overrides for plugins that ship with NvChad (LSP, formatting, treesitter).
-- lazy.nvim merges these tables into NvChad's own plugin specs.
return {
  -- Formatting (see lua/configs/conform.lua)
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
  },

  -- LSP (server list in lua/configs/lspconfig.lua,
  -- per-server tweaks in after/lsp/<server>.lua)
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- Treesitter parsers, installed with :TSInstallAll.
  -- NvChad starts treesitter highlighting for every filetype automatically
  -- (except LaTeX, see lua/autocmds.lua).
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        -- Neovim / NvChad
        "vim",
        "vimdoc",
        "lua",
        "luadoc",
        "printf",
        -- C / C++
        "c",
        "cpp",
        "cmake",
        "make",
        -- Python
        "python",
        -- Documents
        "latex",
        "bibtex",
        "typst",
        "markdown",
        "markdown_inline",
        -- Others
        "rust",
        "asm",
        "bash",
        "html",
        "css",
        "json",
        "toml",
        "yaml",
      },
    },
  },
}
