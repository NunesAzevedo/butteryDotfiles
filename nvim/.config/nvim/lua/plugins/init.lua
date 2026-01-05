return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre", -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- VimTeX
  {
    "lervag/vimtex",
    lazy = false,
    init = function()
      -- Definições do VimTeX (Vimscript dentro de Lua)
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_compiler_method = "latexmk"

      vim.g.vimtex_syntax_conceal = {
        ["math_bounds"] = 0,
        ["greek"] = 1,
        ["math_symbols"] = 1,
      }
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

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
        "python",
        "markdown",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        disable = { "latex" },
      },
    },
  },
}
