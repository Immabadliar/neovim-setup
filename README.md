# Neovim setup

My Neovim configuration for Windows, using [lazy.nvim](https://github.com/folke/lazy.nvim).

It includes:

- Rose Pine with a transparent background
- Telescope file and text search
- Harpoon navigation
- C and TypeScript/JavaScript language servers
- `nvim-cmp` completion and automatic pairs
- Git signs and Fugitive
- A reproducible `lazy-lock.json`

## Quick installation (Windows)

You need Windows 10/11 and `winget` (Microsoft App Installer). Open PowerShell and
install Python and Git first if `py --version` or `git --version` does not work:

```powershell
winget install --id Python.Python.3.13 --exact
winget install --id Git.Git --exact
```

Open a new PowerShell window, then run:

```powershell
git clone https://github.com/Immabadliar/neovim-setup.git
cd neovim-setup
py install.py
```

The installer:

1. Installs Git, Neovim, ripgrep, LLVM/clangd, Node.js, and MSYS2/GCC when missing.
2. Installs the TypeScript language server.
3. Backs up an existing `%LOCALAPPDATA%\nvim` directory with a timestamp.
4. Copies this configuration into `%LOCALAPPDATA%\nvim`.
5. Downloads and synchronizes all plugins in headless Neovim.

If the tools are already installed and you only want the config:

```powershell
py install.py --skip-packages
```

To defer plugin downloads until Neovim first starts:

```powershell
py install.py --skip-plugins
```

## Manual installation

Back up your current config, then clone this repository directly into Neovim's config directory:

```powershell
Rename-Item "$env:LOCALAPPDATA\nvim" "nvim.backup" -ErrorAction SilentlyContinue
git clone https://github.com/Immabadliar/neovim-setup.git "$env:LOCALAPPDATA\nvim"
nvim --headless "+Lazy! sync" +qa
```

The active configuration is [`init.lua`](init.lua). The `lua/theprimeagen` directory is retained from the current setup for future modularization, but the top-level config does not load it today.

## Useful keymaps

The leader key is `Space`.

| Key | Action |
| --- | --- |
| `<leader>pf` | Find files |
| `<leader>ps` | Search project text |
| `<leader>pb` | Open buffers |
| `<leader>a` | Add file to Harpoon |
| `<C-e>` | Open Harpoon menu |
| `<M-1>` … `<M-4>` | Jump to Harpoon entry |
| `gd` | Go to definition |
| `K` | Hover documentation |
| `gr` | Find references |
| `<leader>rn` | Rename symbol |
| `<leader>ca` | Code action |
| `<leader>tt` | Open a terminal split |

After installation, use `:checkhealth` to diagnose any environment-specific issues.
