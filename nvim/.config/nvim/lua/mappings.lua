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

-- Git: who changed this line and in which commit (popup with the full commit message)
map("n", "<leader>gb", "<cmd>Gitsigns blame_line full=true<CR>", { desc = "Git Blame current line" })

-- C/C++: switch between source (.c/.cpp) and header (.h/.hpp).
-- Buffer-local, only where clangd is attached (the command comes from nvim-lspconfig)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.name == "clangd" then
      map("n", "<leader>sh", "<cmd>LspClangdSwitchSourceHeader<CR>", {
        buffer = args.buf,
        desc = "C/C++ Switch source/header",
      })
    end
  end,
})
