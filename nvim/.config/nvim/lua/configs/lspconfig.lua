require("nvchad.configs.lspconfig").defaults()
dofile(vim.g.base46_cache .. "semantic_tokens") -- theme colors for semantic highlighting

-- Enabled servers. Names must match nvim-lspconfig's names (see :help lspconfig-all),
-- NOT Mason's package names. Per-server tweaks live in after/lsp/<server>.lua
local servers = {
  -- C / C++
  "clangd",
  "neocmake",

  -- Python
  "basedpyright", -- completion, navigation, auto-imports, type checking
  "ruff", -- linting

  -- Others
  "lua_ls",
  "rust_analyzer",
  "asm_lsp",
  "html",
  "cssls",
}

vim.lsp.enable(servers)
