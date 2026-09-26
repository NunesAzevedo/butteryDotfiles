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

-- Alternar entre Source (.c, .cpp, .cc) e Header (.h, .hpp, .hh) via Clangd (LSP nativo)
map("n", "<leader>sh", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = "clangd" })

  if #clients == 0 then
    vim.notify("O clangd não está ativo neste arquivo. Verifique com :LspInfo", vim.log.levels.WARN)
    return
  end

  vim.lsp.buf_request(bufnr, "textDocument/switchSourceHeader", { uri = vim.uri_from_bufnr(bufnr) }, function(err, result)
    if err then
      vim.notify("Erro ao buscar arquivo: " .. tostring(err), vim.log.levels.ERROR)
    elseif not result then
      vim.notify("Arquivo correspondente não encontrado pelo clangd.", vim.log.levels.WARN)
    else
      vim.cmd("edit " .. vim.uri_to_fname(result))
    end
  end)
end, { desc = "C/C++ Alternar Source/Header (LSP)" })
