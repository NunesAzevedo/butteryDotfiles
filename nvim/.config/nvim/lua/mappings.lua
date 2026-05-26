require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- Abre o glow na lateral para visualizar markdown
map("n", "<leader>ms", function()
  -- Abre um terminal à direita com tamanho fixo
  vim.cmd("rightbelow vnew | vertical resize 60 | terminal glow " .. vim.fn.expand "%")
  -- Volta para a janela principal para você continuar navegando
  vim.cmd "wincmd h"
end, { desc = "Markdown Reading Pane" })
