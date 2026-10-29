require "nvchad.options"

-- add yours here!

-- local o = vim.o
-- o.cursorlineopt ='both' -- to enable cursorline!

-- Folding by syntax (treesitter): za toggle, zc close, zo open, zM close all, zR open all
vim.o.foldmethod = "expr"
vim.o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.o.foldlevel = 99 -- start with everything unfolded
vim.o.foldtext = "" -- show a folded block as its first line, keeping syntax colors

-- Re-enable the Python provider (NvChad disables it), needed by molten-nvim.
-- It runs from a dedicated venv with pynvim and jupyter_client installed.
local nvim_venv_python = vim.fn.expand "~/.config/nvim-venv/bin/python"
if vim.uv.fs_stat(nvim_venv_python) then
  vim.g.loaded_python3_provider = nil
  vim.g.python3_host_prog = nvim_venv_python
end

-- WSL: share the clipboard with Windows.
-- Neovim uses win32yank.exe automatically when it's on PATH (faster);
-- otherwise fall back to clip.exe / powershell, which ship with Windows.
if vim.fn.has "wsl" == 1 and vim.fn.executable "win32yank.exe" == 0 then
  local paste = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
  vim.g.clipboard = {
    name = "WslClipboard",
    copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
    paste = { ["+"] = paste, ["*"] = paste },
    cache_enabled = 0,
  }
end
