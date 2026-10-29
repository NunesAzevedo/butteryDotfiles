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
├── after/lsp/               per-LSP-server tweaks (one file per server)
│   ├── clangd.lua           flags: indexing, RAM usage, cross-compilers
│   ├── basedpyright.lua     .venv detection, type-checking level
│   └── ruff.lua             lint only (hover left to basedpyright)
└── lua/
    ├── chadrc.lua           NvChad UI/theme options + Mason skip list
    ├── options.lua          editor options (vim.opt / vim.g), Python provider, WSL clipboard
    ├── autocmds.lua         automatic commands (run code on events, e.g. FileType)
    ├── mappings.lua         general keymaps
    ├── configs/
    │   ├── lazy.lua         lazy.nvim settings (disabled built-in plugins, UI)
    │   ├── lspconfig.lua    list of enabled LSP servers
    │   └── conform.lua      formatters per filetype
    └── plugins/             plugin specs, one file per topic (all files are auto-imported)
        ├── core.lua         overrides of NvChad's plugins (LSP, conform, treesitter)
        ├── code.lua         code navigation: sticky scroll (treesitter-context), outline (aerial)
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
| Python | `basedpyright` + `ruff` | basedpyright: completion/navigation/auto-imports/types, ruff: linting |
| Lua | `lua_ls` | knows the Neovim API, useful for editing this config |
| Rust | `rust_analyzer` | from rustup |
| Assembly | `asm_lsp` | built with cargo by Mason |
| HTML / CSS | `html`, `cssls` | |

Useful LSP keys (Neovim built-ins + NvChad + ours):

| Keys | Action |
|---|---|
| `gd` / `gD` | go to definition / declaration |
| `grr` | list references (where this symbol is used, across files) |
| `gri` | go to implementation |
| `K` | hover docs |
| `<leader>ra` | rename symbol in the whole project |
| `gra` | code actions (quick fixes, add missing include/import) |
| `]d` / `[d` | next / previous diagnostic |
| `<C-s>` (insert) | function signature help (also pops up automatically on `(` and `,`) |
| `<leader>ih` | toggle inlay hints |
| `<leader>fs` / `<leader>fS` | search symbol (function, class...) in the project / in the file |
| `<leader>fr` | references in a searchable list with preview |
| `<leader>fd` | errors and warnings in a searchable list |
| `<leader>ci` / `<leader>co` | call hierarchy: who calls this function / what it calls |
| `<leader>o` | toggle outline side panel |

### Editor features (VS Code equivalents)

| Feature | How it works here |
|---|---|
| Parameter hints while typing | NvChad's signature popup (`lsp.signature`, on by default) |
| Semantic highlighting | LSP semantic tokens colored by the theme (`integrations` in `chadrc.lua`): members, parameters, macros, types get distinct colors |
| Highlight occurrences | after the cursor rests on a symbol, its other uses are highlighted (`lua/autocmds.lua`) |
| Sticky scroll | nvim-treesitter-context pins the current function/class header at the top |
| Code folding | treesitter folds (`lua/options.lua`): `za` toggle, `zc`/`zo` close/open, `zM`/`zR` all |
| Outline | aerial.nvim side panel, `<leader>o` |
| Problems panel | `<leader>fd` (Telescope diagnostics) |
| Integrated terminal | NvChad: `<A-i>` floating, `<A-h>` horizontal, `<A-v>` vertical (toggle) |
| Lint (C/C++) | clangd runs clang-tidy; configure checks per project with a `.clang-tidy` file |

**Inlay hints** are extra hints drawn inline by the LSP (they are not in the file):
parameter names at call sites and inferred types, e.g. `motor_speed(rpm: 10)` or
`auto x: int = ...`. Off by default, toggle with `<leader>ih`.

### C/C++ projects (clangd)

clangd only understands a project (include paths, macros, other files) through a
**`compile_commands.json`**. Without it, each file is analyzed alone: go-to-definition,
completion of functions from other files and references all break.

- **CMake:** `CMAKE_EXPORT_COMPILE_COMMANDS=ON` is exported in `~/.zshrc`, so every
  `cmake -B build` generates `build/compile_commands.json`, which clangd finds by itself.
  Existing build folders need `cmake` to be re-run once.
- **Plain Makefiles:** generate it with [`bear`](https://github.com/rizsotto/Bear): `bear -- make -B`.
  Bear records only the compilations that actually run, so `-B` forces a full rebuild
  (otherwise an up-to-date build produces an empty `[]` file). Re-run only when `.c`/`.cpp`
  files are added or build flags change, then `:LspRestart`.
- **Git:** `compile_commands.json` and `.cache/clangd/` are in the global gitignore
  (`~/.config/git/ignore`, `git` stow package), so they never get committed.
- **Firmware (ARM / ESP-IDF):** clangd is allowed to query the cross-compilers
  (`--query-driver` in `after/lsp/clangd.lua`) and GCC-only flags that clang doesn't know
  are dropped in `~/.config/clangd/config.yaml` (the `clangd` stow package).
- **Indexing threads:** 4 by default; override per machine with `export CLANGD_JOBS=8`
  (then `:LspRestart`).
- **Check what clangd sees:** `clangd --check=path/to/file.cpp` from the project root.

### Python projects (basedpyright)

If the project root has a `.venv/` (or `venv/`), basedpyright uses its interpreter
automatically, so packages installed there get completion even without activating the venv.
Type checking runs in `standard` mode, on open files only, to keep it light.

## Formatting

[conform.nvim](https://github.com/stevearc/conform.nvim), configured in `lua/configs/conform.lua`.
Format with `<leader>fm`. Filetypes without a formatter fall back to the LSP's formatter.
Format-on-save is off (commented example in the file).

## Treesitter (syntax highlighting)

Parsers are listed in `lua/plugins/core.lua` (`ensure_installed`) and installed with
`:TSInstallAll` (requires the `tree-sitter` CLI). NvChad starts treesitter highlighting
for every filetype automatically, except LaTeX, which uses VimTeX's own syntax
(see `lua/autocmds.lua`).

**Performance note:** the first C++ file opened in a session takes ~0.25 s longer because
tree-sitter compiles the C++ grammar's queries (the grammar is huge; C takes ~0.03 s).
It happens once per session and isn't caused by this config. Startup measured with
`nvim --startuptime /tmp/st.log file`: ~20 ms with no file, ~50 ms for `.c`, ~260 ms for `.cpp`.

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
| `<leader>ih` | toggle LSP inlay hints |
| `<leader>m*` | Jupyter (molten), see table above |

## WSL

The same config is used on WSL. The only difference, the clipboard, is handled in
`lua/options.lua`: on WSL, Neovim uses `win32yank.exe` if it's on PATH (faster),
otherwise falls back to `clip.exe` / `powershell.exe`. Nothing to change per machine.

## Setting up on a new computer

1. System packages (Arch): `neovim git stow ripgrep tree-sitter-cli clang bear rustup
   texlive latexmk zathura typst glow imagemagick python`.
   Also stow the `zsh`, `clangd` and `git` packages (build env vars, clangd config,
   global gitignore).
2. Rust toolchain (needed by rust_analyzer and to build asm-lsp): `rustup default stable`
3. Python provider for molten (a dedicated venv, path set in `lua/options.lua`;
   skipped automatically if it doesn't exist):
   ```sh
   python -m venv ~/.config/nvim-venv
   ~/.config/nvim-venv/bin/pip install pynvim jupyter_client
   ```
   Each project environment also needs `ipykernel` to be usable as a kernel.
4. Link the config: `stow nvim` from the dotfiles root.
5. Open nvim (plugins install automatically), then run:
   `:MasonInstallAll`, `:TSInstallAll` and `:UpdateRemotePlugins`, and restart.
