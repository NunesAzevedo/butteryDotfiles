require "nvchad.autocmds"

-- Proteção para Makefiles: Força o uso de Tabs e desativa a conversão para espaços
vim.api.nvim_create_autocmd("FileType", {
  pattern = "make",
  command = "setlocal noexpandtab shiftwidth=8 softtabstop=0",
})
