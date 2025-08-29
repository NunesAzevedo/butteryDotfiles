require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  "clangd",
  "rust-analyzer",
  "eslint-lsp",
  "ruff",
  "ast-grep",
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
