-- LaTeX
return {
  {
    "lervag/vimtex",
    lazy = false, -- VimTeX should not be lazy-loaded
    init = function()
      vim.g.vimtex_view_method = "zathura"
      vim.g.vimtex_compiler_method = "latexmk"

      vim.g.vimtex_syntax_conceal = {
        ["math_bounds"] = 0,
        ["greek"] = 1,
        ["math_symbols"] = 1,
      }
    end,
  },
}
