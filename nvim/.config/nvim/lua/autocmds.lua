require "nvchad.autocmds"

local autocmd = vim.api.nvim_create_autocmd

-- Makefiles require real tabs
autocmd("FileType", {
  pattern = "make",
  command = "setlocal noexpandtab shiftwidth=8 softtabstop=0",
})

-- NvChad starts treesitter for every filetype, but VimTeX uses its own syntax
-- engine (needed for math detection and conceal), so turn treesitter off for LaTeX.
autocmd("FileType", {
  pattern = { "tex", "plaintex", "bib" },
  callback = function()
    vim.treesitter.stop()
  end,
})
