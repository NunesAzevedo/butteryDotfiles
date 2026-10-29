# Neovim config

Personal Neovim config built on top of [NvChad v2.5](https://nvchad.com), managed with GNU Stow.
Main uses: C/C++, Python/Jupyter, LaTeX, Typst and quick markdown notes.

NvChad is loaded **as a plugin**: it provides sane defaults (UI, theme, completion, telescope,
file tree, keymaps) and this repo only overrides or adds what's needed.

## Directory layout

```
nvim/
├── init.lua                 entry point: bootstraps lazy.nvim, loads NvChad + lua/plugins/
├── lazy-lock.json           exact plugin versions (commit it; restore with :Lazy restore)
├── after/lsp/
│   └── <server>.lua         per-LSP-server tweaks (one file per server)
└── lua/
    ├── chadrc.lua           NvChad UI/theme options + Mason skip list
    ├── options.lua          editor options (vim.opt / vim.g)
    ├── autocmds.lua         automatic commands (run code on events, e.g. FileType)
    ├── mappings.lua         general keymaps
    ├── configs/
    │   ├── lazy.lua         lazy.nvim settings (disabled built-in plugins, UI)
    │   ├── lspconfig.lua    list of enabled LSP servers
    │   └── conform.lua      formatters per filetype
    └── plugins/             plugin specs, one file per topic (all files are auto-imported)
        ├── core.lua         overrides of NvChad's plugins (LSP, conform, treesitter)
        ├── latex.lua        VimTeX
        ├── typst.lua        typst-preview
        ├── markdown.lua     glow + render-markdown
        └── jupyter.lua      molten + image.nvim
```

### Startup order

1. `init.lua` clones lazy.nvim if missing and calls `require("lazy").setup`, which reads
   NvChad's plugin list plus every file in `lua/plugins/`.
2. The theme cache is loaded, then `options.lua` and `autocmds.lua`.
3. `mappings.lua` is loaded last (scheduled), so it can override NvChad's keymaps.

## How plugins work (lazy.nvim)

Each file in `lua/plugins/` returns a list of **plugin specs**. A spec is a Lua table:

```lua
return {
  {
    "author/repo",           -- GitHub repo
    ft = "python",           -- load only when opening this filetype...
    cmd = "SomeCommand",     -- ...or when running this command...
    keys = { ... },          -- ...or when pressing one of these keys
    event = "BufWritePre",   -- ...or on this event
    lazy = false,            -- load at startup instead (avoid unless required)
    init = function() end,   -- runs at startup, BEFORE loading (set vim.g.* options here)
    opts = { ... },          -- passed to require("repo").setup(opts)
    config = function() end, -- custom setup, replaces the automatic setup(opts)
  },
}
```

Plugins are lazy by default (`configs/lazy.lua`), which is what keeps startup fast:
always give a new plugin a trigger (`ft`, `cmd`, `keys` or `event`).

Writing a spec for a plugin NvChad already ships (e.g. `nvim-treesitter` in `core.lua`)
**merges** your fields into NvChad's spec instead of adding a second copy.

**Adding a plugin:** create `lua/plugins/<topic>.lua` returning a spec list, restart, done.
**Removing one:** delete its spec, then run `:Lazy clean`.

## LSP (code intelligence)

Uses Neovim's native LSP (`vim.lsp.config` / `vim.lsp.enable`), with server
definitions from nvim-lspconfig.

- **Enable a server:** add its name to the list in `lua/configs/lspconfig.lua`.
  Use the **lspconfig name** (`:help lspconfig-all`), not the Mason package name:
  `lua_ls` not `lua-language-server`, `rust_analyzer` not `rust-analyzer`.
- **Tweak a server:** create `after/lsp/<name>.lua` returning a table with the fields
  to override (`cmd`, `settings`, `filetypes`, ...). It is merged over lspconfig's defaults.
  Files in `after/` win over plugins, so the tweak always takes effect.
- **Install servers:** `:MasonInstallAll` installs every enabled server and formatter.
  Tools that come from the system instead are listed in `M.mason.skip` in `chadrc.lua`.
- **Debug:** `:checkhealth vim.lsp` shows which servers are attached and why not.

| Language | Server | Notes |
|---|---|---|
| C / C++ | `clangd` | needs `compile_commands.json` (see below) |
| CMake | `neocmake` | |
| Python | `jedi_language_server` + `ruff` | jedi: completion/navigation, ruff: linting |
| Lua | `lua_ls` | knows the Neovim API, useful for editing this config |
| Rust | `rust_analyzer` | from rustup |
| Assembly | `asm_lsp` | built with cargo by Mason |
| HTML / CSS | `html`, `cssls` | |

### C/C++ projects

clangd needs to know the compile flags. For CMake projects, generate the database:

```sh
cmake -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
```

clangd finds `build/compile_commands.json` automatically. For plain Makefiles, use
[`bear`](https://github.com/rizsotto/Bear): `bear -- make`.

## Formatting

[conform.nvim](https://github.com/stevearc/conform.nvim), configured in `lua/configs/conform.lua`.
Format with `<leader>fm`. Filetypes without a formatter fall back to the LSP's formatter.
Format-on-save is off (commented example in the file).

## Treesitter (syntax highlighting)

Parsers are listed in `lua/plugins/core.lua` (`ensure_installed`) and installed with
`:TSInstallAll` (requires the `tree-sitter` CLI). NvChad starts treesitter highlighting
for every filetype automatically, except LaTeX, which uses VimTeX's own syntax
(see `lua/autocmds.lua`).

## Workflows

| Task | How |
|---|---|
| LaTeX | VimTeX: `\ll` start continuous compile, `\lv` open in zathura, `\le` errors |
| Typst | `:TypstPreview` opens a live preview in the browser |
| Markdown | rendered inline by render-markdown; `<leader>ms` opens a glow side pane |
| Jupyter | in a `.py` file: `<leader>mi` start kernel, `<leader>ml` run line, `<leader>me` run selection/motion, `<leader>mo` show output |
| C/C++ | `<leader>sh` switch between source and header |

## Custom keymaps

Defined in `lua/mappings.lua` (on top of NvChad's defaults; `<leader>` is Space).
Press `<leader>` and wait to see them all in which-key, or run `:Telescope keymaps`.

| Keys | Action |
|---|---|
| `;` | enter command mode |
| `jk` (insert) | escape |
| `<leader>ms` | markdown preview pane (glow) |
| `<leader>sh` | C/C++ switch source/header |
| `<leader>m*` | Jupyter (molten), see table above |

## Setting up on a new computer

1. System packages (Arch): `neovim git stow ripgrep tree-sitter-cli clang rustup
   texlive latexmk zathura typst glow imagemagick python`
2. Rust toolchain (needed by rust_analyzer and to build asm-lsp): `rustup default stable`
3. Python provider for molten (a dedicated venv, path set in `lua/options.lua`):
   ```sh
   python -m venv ~/.config/nvim-venv
   ~/.config/nvim-venv/bin/pip install pynvim jupyter_client
   ```
   Each project environment also needs `ipykernel` to be usable as a kernel.
4. Link the config: `stow nvim` from the dotfiles root.
5. Open nvim (plugins install automatically), then run:
   `:MasonInstallAll`, `:TSInstallAll` and `:UpdateRemotePlugins`, and restart.
