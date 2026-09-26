require("nvchad.configs.lspconfig").defaults()

local servers = {
  "jedi-language-server",
  "html",
  "cssls",
  "clangd",
  "neocmakelsp",
  "rust-analyzer",
  "eslint-lsp",
  "ruff",
  "ast-grep",
  "asm-lsp",
  "lua",
}

vim.lsp.config.clangd = vim.tbl_deep_extend("force", vim.lsp.config.clangd or {}, {
  cmd = {
    "clangd",
    "--background-index",
    "--compile-commands-dir=.", 
    "--header-insertion=iwyu",
  }
})


vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
