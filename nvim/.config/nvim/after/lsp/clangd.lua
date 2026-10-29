-- clangd (C/C++) tweaks.
-- Files in after/lsp/<name>.lua are merged on top of nvim-lspconfig's defaults.
-- The file name must be the server's lspconfig name.
--
-- clangd finds compile_commands.json on its own by searching the file's parent
-- directories and their build/ subfolders, so no --compile-commands-dir is needed.
return {
  cmd = {
    "clangd",
    "--background-index",
    "--header-insertion=iwyu",
  },
}
