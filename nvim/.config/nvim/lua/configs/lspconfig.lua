require("nvchad.configs.lspconfig").defaults()

-- Servidores ativos. Ajustes específicos de cada um ficam em after/lsp/<servidor>.lua
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

vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers
