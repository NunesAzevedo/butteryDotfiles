-- clangd (C/C++) tweaks.
-- Files in after/lsp/<name>.lua are merged on top of nvim-lspconfig's defaults.
-- The file name must be the server's lspconfig name.
--
-- clangd needs compile_commands.json to understand a project (include paths, flags);
-- without it, every file is analyzed alone and cross-file features break.
-- It is found automatically in the file's parent directories and their build/ folders.
-- Project-independent clangd settings live in ~/.config/clangd/config.yaml.
return {
  cmd = {
    "clangd",
    "--background-index", -- index the whole project for references / workspace symbols
    "--clang-tidy", -- extra bug-prone / modernize warnings (uses the project's .clang-tidy if any)
    "--header-insertion=iwyu", -- completing a symbol from another header adds its #include
    "--completion-style=detailed", -- one completion item per overload
    "--pch-storage=disk", -- keep precompiled headers on disk instead of RAM
    -- Background indexing threads; override per machine with `export CLANGD_JOBS=8`
    "-j=" .. (vim.env.CLANGD_JOBS or 4),
    -- Allow clangd to ask cross-compilers for their system headers (firmware projects)
    "--query-driver=/usr/bin/arm-none-eabi-*,**/xtensa-esp*-elf-*,**/riscv32-esp-elf-*",
  },
}
