require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!


-- 1. Remove o bloqueio padrão do NvChad que desativa o Python
vim.g.loaded_python3_provider = nil
vim.g.loaded_rplugin = nil

-- 2. Aponta para o ambiente virtual dedicado do Neovim
vim.g.python3_host_prog = vim.fn.expand("~/.config/nvim-venv/bin/python")
