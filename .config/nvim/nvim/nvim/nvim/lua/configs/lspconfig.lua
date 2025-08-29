require("nvchad.configs.lspconfig").defaults()

local servers = {
  "html",
  "cssls",
  "clangd",
  "rust-analyzer",
  "eslint-lsp",
  "ruff",
}
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
