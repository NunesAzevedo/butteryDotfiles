require "nvchad.autocmds"

local autocmd = vim.api.nvim_create_autocmd

-- Makefiles require real tabs
autocmd("FileType", {
  pattern = "make",
  command = "setlocal noexpandtab shiftwidth=8 softtabstop=0",
})

-- Highlight other occurrences of the symbol under the cursor (after a short pause)
autocmd("LspAttach", {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not (client and client:supports_method "textDocument/documentHighlight") then
      return
    end

    local group = vim.api.nvim_create_augroup("lsp_document_highlight_" .. args.buf, { clear = true })
    autocmd({ "CursorHold", "CursorHoldI" }, {
      group = group,
      buffer = args.buf,
      callback = vim.lsp.buf.document_highlight,
    })
    autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
      group = group,
      buffer = args.buf,
      callback = vim.lsp.buf.clear_references,
    })
  end,
})

-- NvChad starts treesitter for every filetype, but VimTeX uses its own syntax
-- engine (needed for math detection and conceal), so turn treesitter off for LaTeX.
autocmd("FileType", {
  pattern = { "tex", "plaintex", "bib" },
  callback = function()
    vim.treesitter.stop()
  end,
})
