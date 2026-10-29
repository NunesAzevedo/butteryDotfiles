-- Ajustes do clangd (C/C++).
-- Arquivos em after/lsp/<nome>.lua são mesclados por cima da config padrão
-- do nvim-lspconfig. O nome do arquivo deve ser o nome do servidor no lspconfig.
return {
  cmd = {
    "clangd",
    "--background-index",
    "--compile-commands-dir=.",
    "--header-insertion=iwyu",
  },
}
