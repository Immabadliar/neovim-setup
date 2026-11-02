
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.updatetime = 250
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.completeopt = "menu,menuone,noselect"

vim.cmd("syntax on")
vim.cmd("filetype plugin indent on")

local undo_dir = vim.fn.stdpath("data") .. "/undo"
vim.fn.mkdir(undo_dir, "p")
vim.opt.undodir = undo_dir

local gcc = "C:/msys64/ucrt64/bin/gcc.exe"
local gcc_bin = "C:/msys64/ucrt64/bin"
local clangd = "C:/Program Files/LLVM/bin/clangd.exe"

if vim.fn.has("win32") == 1 then
    if vim.fn.isdirectory(gcc_bin) == 1 then
        vim.env.PATH = gcc_bin .. ";" .. vim.env.PATH
    end
end

local lazy_path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazy_path) then
    local result = vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "--branch=stable",
        "https://github.com/folke/lazy.nvim.git",
        lazy_path,
    })

    if vim.v.shell_error ~= 0 then
        error("Failed to install lazy.nvim: " .. result)
    end
end

vim.opt.rtp:prepend(lazy_path)

require("lazy").setup({
    {
        "rose-pine/neovim",
        name = "rose-pine",
        priority = 1000,
        config = function()
            require("rose-pine").setup({
                variant = "moon",
                dark_variant = "moon",
                styles = {
                    transparency = true,
                },
            })

            vim.cmd.colorscheme("rose-pine")
        end,
    },

    {
        "nvim-lua/plenary.nvim",
    },

    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            local builtin = require("telescope.builtin")

            vim.keymap.set("n", "<leader>pf", builtin.find_files)
            vim.keymap.set("n", "<C-p>", builtin.git_files)
            vim.keymap.set("n", "<leader>ps", builtin.live_grep)
            vim.keymap.set("n", "<leader>pb", builtin.buffers)
        end,
    },

    {
        "ThePrimeagen/harpoon",
        branch = "harpoon2",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            local harpoon = require("harpoon")
            harpoon:setup()

            vim.keymap.set("n", "<leader>a", function()
                harpoon:list():add()
            end)

            vim.keymap.set("n", "<C-e>", function()
                harpoon.ui:toggle_quick_menu(harpoon:list())
            end)

            for i = 1, 4 do
                vim.keymap.set("n", "<M-" .. i .. ">", function()
                    harpoon:list():select(i)
                end)
            end
        end,
    },

    {
        "neovim/nvim-lspconfig",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            local clangd_cmd = clangd

            if vim.fn.executable(clangd_cmd) ~= 1 then
                clangd_cmd = "clangd"
            end

            local clangd_command = {
                clangd_cmd,
                "--background-index",
                "--clang-tidy",
                "--completion-style=detailed",
            }

            if vim.fn.executable(gcc) == 1 then
                table.insert(
                    clangd_command,
                    "--query-driver=" .. gcc
                )
            end

            vim.lsp.config("clangd", {
                cmd = clangd_command,
                filetypes = { "c" },
                capabilities = capabilities,
                root_markers = {
                    "compile_commands.json",
                    "compile_flags.txt",
                    ".git",
                },
            })

            vim.lsp.enable("clangd")

            vim.lsp.config("ts_ls", {
                cmd = {
                    "typescript-language-server",
                    "--stdio",
                },
                filetypes = {
                    "javascript",
                    "javascriptreact",
                    "typescript",
                    "typescriptreact",
                },
                root_markers = {
                    "tsconfig.json",
                    "jsconfig.json",
                    "package.json",
                    "package-lock.json",
                    "pnpm-lock.yaml",
                    "yarn.lock",
                    ".git",
                },
                capabilities = capabilities,
                single_file_support = true,
            })

            vim.lsp.enable("ts_ls")

            vim.diagnostic.config({
                virtual_text = true,
                underline = true,
                signs = true,
                severity_sort = true,
                update_in_insert = false,
            })

            vim.keymap.set("n", "gd", vim.lsp.buf.definition)
            vim.keymap.set("n", "K", vim.lsp.buf.hover)
            vim.keymap.set("n", "gr", vim.lsp.buf.references)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action)
            vim.keymap.set("n", "[d", vim.diagnostic.goto_prev)
            vim.keymap.set("n", "]d", vim.diagnostic.goto_next)
        end,
    },

    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp",
            "hrsh7th/cmp-buffer",
            "hrsh7th/cmp-path",
        },
        config = function()
            local cmp = require("cmp")

            cmp.setup({
                snippet = {
                    expand = function(args)
                        vim.snippet.expand(args.body)
                    end,
                },

                mapping = cmp.mapping.preset.insert({
                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping.confirm({
                        select = true,
                    }),
                    ["<Tab>"] = cmp.mapping.select_next_item(),
                    ["<S-Tab>"] = cmp.mapping.select_prev_item(),
                }),

                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "path" },
                    { name = "buffer" },
                }),
            })
        end,
    },

    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            local autopairs = require("nvim-autopairs")

            autopairs.setup({
                check_ts = false,
            })

            local cmp = require("cmp")
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")

            cmp.event:on(
                "confirm_done",
                cmp_autopairs.on_confirm_done()
            )
        end,
    },

    {
        "nvim-lualine/lualine.nvim",
        config = function()
            require("lualine").setup({
                options = {
                    theme = "rose-pine",
                    globalstatus = true,
                },
            })
        end,
    },

    {
        "lewis6991/gitsigns.nvim",
        opts = {},
    },

    {
        "tpope/vim-fugitive",
    },

    {
        "ThePrimeagen/vim-be-good",
        cmd = "VimBeGood",
    },
}, {
    rocks = {
        enabled = false,
    },
    change_detection = {
        notify = false,
    },
})

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
vim.keymap.set("n", "<leader>w", "<cmd>w<CR>")
vim.keymap.set("n", "<leader>q", "<cmd>q<CR>")
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")
vim.keymap.set("n", "<leader>y", '"+y')
vim.keymap.set("v", "<leader>y", '"+y')

vim.keymap.set("n", "<leader>tt", function()
    vim.cmd("botright vsplit | terminal")
end)

local transparent_groups = {
    "Normal",
    "NormalNC",
    "NormalFloat",
    "SignColumn",
    "EndOfBuffer",
}

local function apply_transparency()
    for _, group in ipairs(transparent_groups) do
        vim.api.nvim_set_hl(0, group, {
            bg = "NONE",
        })
    end
end

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = apply_transparency,
})

apply_transparency()
