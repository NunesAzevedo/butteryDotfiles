require "nvchad.mappings"

-- add yours here

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

-- Show/hide inlay hints (parameter names and inferred types shown inline by the LSP)
map("n", "<leader>ih", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "LSP Toggle inlay hints" })

-- LSP pickers (Telescope): fuzzy search with preview
map("n", "<leader>fs", "<cmd>Telescope lsp_dynamic_workspace_symbols<CR>", { desc = "LSP Find symbol in project" })
map("n", "<leader>fS", "<cmd>Telescope lsp_document_symbols<CR>", { desc = "LSP Find symbol in file" })
map("n", "<leader>fr", "<cmd>Telescope lsp_references<CR>", { desc = "LSP Find references" })
map("n", "<leader>fd", "<cmd>Telescope diagnostics<CR>", { desc = "LSP Find diagnostics (errors/warnings)" })

-- Call hierarchy: who calls the function under the cursor / what it calls
map("n", "<leader>ci", "<cmd>Telescope lsp_incoming_calls<CR>", { desc = "LSP Incoming calls (callers)" })
map("n", "<leader>co", "<cmd>Telescope lsp_outgoing_calls<CR>", { desc = "LSP Outgoing calls (callees)" })

-- Open glow in a side pane to preview markdown
map("n", "<leader>ms", function()
  -- Open a fixed-width terminal on the right
  vim.cmd("rightbelow vnew | vertical resize 60 | terminal glow " .. vim.fn.expand "%")
  -- Jump back to the main window
  vim.cmd "wincmd h"
end, { desc = "Markdown Reading Pane" })

-- Switch between source (.c, .cpp, .cc) and header (.h, .hpp, .hh) using clangd
map("n", "<leader>sh", function()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients { bufnr = bufnr, name = "clangd" }

  if #clients == 0 then
    vim.notify("O clangd não está ativo neste arquivo. Verifique com :LspInfo", vim.log.levels.WARN)
    return
  end

  vim.lsp.buf_request(
    bufnr,
    "textDocument/switchSourceHeader",
    { uri = vim.uri_from_bufnr(bufnr) },
    function(err, result)
      if err then
        vim.notify("Erro ao buscar arquivo: " .. tostring(err), vim.log.levels.ERROR)
      elseif not result then
        vim.notify("Arquivo correspondente não encontrado pelo clangd.", vim.log.levels.WARN)
      else
        vim.cmd("edit " .. vim.uri_to_fname(result))
      end
    end
  )
end, { desc = "C/C++ Alternar Source/Header (LSP)" })

