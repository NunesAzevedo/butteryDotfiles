-- Formatters per filetype. Format manually with <leader>fm (NvChad default).
-- Filetypes not listed here fall back to the LSP's formatter (e.g. css -> cssls).
local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    html = { "superhtml" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    -- cmake = { "cmake_format" },
    python = { "ruff_organize_imports", "ruff_format" },
    rust = { "rustfmt" },
    asm = { "asmfmt" },
  },

  default_format_opts = {
    lsp_format = "fallback",
  },

  -- format_on_save = {
  --   timeout_ms = 500,
  -- },
}

return options
