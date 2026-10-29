require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

-- Re-enable the Python provider (NvChad disables it), needed by molten-nvim.
-- It runs from a dedicated venv with pynvim and jupyter_client installed.
vim.g.loaded_python3_provider = nil
vim.g.python3_host_prog = vim.fn.expand "~/.config/nvim-venv/bin/python"
