-- basedpyright (Python): completion, navigation, auto-imports and type checking.
-- Linting and formatting are left to ruff (after/lsp/ruff.lua).

-- Use the project's .venv (if any) so third-party packages are resolved
-- even when Neovim was started without activating the venv.
local function find_venv_python(root)
  for _, dir in ipairs { ".venv", "venv" } do
    local python = vim.fs.joinpath(root, dir, "bin", "python")
    if vim.uv.fs_stat(python) then
      return python
    end
  end
end

return {
  before_init = function(_, config)
    local python = config.root_dir and find_venv_python(config.root_dir)
    if python then
      config.settings.python = vim.tbl_extend("force", config.settings.python or {}, { pythonPath = python })
    end
  end,

  settings = {
    basedpyright = {
      disableOrganizeImports = true, -- ruff does it
      analysis = {
        typeCheckingMode = "standard", -- "recommended"/"all" are very noisy
        diagnosticMode = "openFilesOnly", -- lighter than "workspace"
        autoImportCompletions = true,
      },
    },
  },
}
