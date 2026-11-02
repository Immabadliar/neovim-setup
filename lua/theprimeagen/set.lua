vim.opt.guicursor = ""

vim.opt.nu = true
vim.opt.relativenumber = true

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.wrap = false

vim.opt.swapfile = false
vim.opt.backup = false
local undo_dir = vim.fn.stdpath("data") .. "/undodir"
vim.fn.mkdir(undo_dir, "p")
vim.opt.undodir = undo_dir

vim.opt.hlsearch = false
vim.opt.incsearch = true

vim.opt.termguicolors = true

vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append("@-@")

vim.opt.updatetime = 50

vim.opt.colorcolumn = "80"

vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
        for _, group in ipairs({
            "Normal",
            "NormalNC",
            "NormalFloat",
            "SignColumn",
            "EndOfBuffer",
        }) do
            vim.api.nvim_set_hl(0, group, { bg = "NONE" })
        end
    end,
})

vim.cmd.colorscheme(vim.g.colors_name or "default")
