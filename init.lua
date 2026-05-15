-- ============================================================
-- PLUGINS
-- ============================================================

vim.pack.add({
    -- Navigation
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/folke/snacks.nvim" },
    { src = "https://github.com/ibhagwan/fzf-lua" },
    { src = "https://github.com/voldikss/vim-floaterm" },
    { src = "https://github.com/MagicDuck/grug-far.nvim" },
    { src = "https://github.com/dhruvasagar/vim-prosession" },
    { src = "https://github.com/tpope/vim-obsession" },
    { src = "https://github.com/folke/flash.nvim" },

    -- UI
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/rebelot/kanagawa.nvim" },
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
    { src = "https://github.com/tpope/vim-fugitive" },
    { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
    { src = "https://github.com/3rd/image.nvim" },
    { src = "https://github.com/goolord/alpha-nvim" },
    { src = "https://github.com/stevearc/dressing.nvim" },
    { src = "https://github.com/nvim-lualine/lualine.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
    { src = "https://github.com/refractalize/oil-git-status.nvim" },
    { src = "https://github.com/akinsho/bufferline.nvim" },
    { src = "https://github.com/SmiteshP/nvim-navic" },

    -- LSP
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/b0o/SchemaStore.nvim" },

    -- Completion
    { src = "https://github.com/saghen/blink.cmp" },
    { src = "https://github.com/cohama/lexima.vim" },
    { src = "https://github.com/tronikelis/ts-autotag.nvim" },

    -- Snippets
    { src = "https://github.com/L3MON4D3/LuaSnip" },
    { src = "https://github.com/rafamadriz/friendly-snippets" },

    -- Tools
    { src = "https://github.com/nvim-lua/plenary.nvim" },
    { src = "https://github.com/chomosuke/typst-preview.nvim" },
    { src = "https://github.com/lambdalisue/vim-suda" },
    { src = "https://github.com/kawre/leetcode.nvim" },
    { src = "https://github.com/MunifTanjim/nui.nvim" },
    { src = "https://github.com/G00380316/ssh-launcher.nvim" },
    { src = "https://github.com/wojciech-kulik/xcodebuild.nvim" },
})


-- ============================================================
-- BASIC VIM SETTINGS
-- ============================================================

vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.cmd([[set mouse=]])
vim.cmd([[set noswapfile]])

vim.o.hidden = true
vim.o.errorbells = false
vim.o.backspace = "indent,eol,start"
vim.o.autoread = true
vim.o.updatetime = 50
vim.o.timeoutlen = 500
vim.o.ttimeoutlen = 0

vim.o.termguicolors = true
vim.o.undofile = true
vim.o.clipboard = "unnamedplus"
vim.o.winborder = "rounded"

vim.opt.runtimepath:append("~/.local/share/nvim/site")


-- ============================================================
-- FILE FORMAT / INDENTATION
-- ============================================================

vim.opt.fileformats = { "unix", "dos" }
vim.opt.fileformat = "unix"

local indent = 4
vim.o.tabstop = indent
vim.o.shiftwidth = indent
vim.o.softtabstop = indent
vim.o.expandtab = true
vim.o.smartindent = true
vim.opt.autoindent = true
vim.opt.smarttab = true


-- ============================================================
-- SEARCH
-- ============================================================

vim.o.smartcase = true
vim.o.hlsearch = true
vim.o.incsearch = true


-- ============================================================
-- UI / EDITOR LOOK
-- ============================================================

vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.signcolumn = "yes"
vim.o.scrolloff = 10
vim.o.matchtime = 2
vim.o.paste = false

vim.o.guicursor = "n-v-c-sm:block-blinkon1,i-ci-ve:ver25,r-cr-o:hor20,a:Cursor/Cursor"

vim.o.wrap = true
-- vim.o.wrap = false
vim.o.linebreak = true
vim.o.wrapmargin = 0
vim.o.textwidth = 0

vim.opt.formatoptions:remove({ "t", "c", "r", "o" })
vim.opt.iskeyword:append("-")
vim.opt.iskeyword:append("_")

vim.cmd("set completeopt+=noselect")

vim.diagnostic.config({
    virtual_text = true,
    float = {
        border = "rounded",
    },
})


-- ============================================================
-- TRANSPARENCY / HIGHLIGHTS
-- ============================================================

vim.cmd([[hi @lsp.type.number gui=italic]])

vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })

vim.cmd(":hi statusline guibg=NONE")
vim.cmd(":hi signcolumn guibg=NONE")

vim.cmd([[
  highlight CursorLine cterm=NONE ctermbg=236 guibg=#252535
]])


-- ============================================================
-- SESSIONS / PROSESSION
-- ============================================================

vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

vim.g.prosession_on_startup = 1
vim.g.prosession_per_branch = 1

vim.g.Prosession_ignore_expr = function()
    local cwd = vim.fn.getcwd()
    return cwd ~= vim.fn.expand("~")
end


-- ============================================================
-- WINBAR
-- Shows current function/class path using nvim-navic.
-- ============================================================


vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"


-- ============================================================
-- MODULE LOAD ORDER
-- Load plugin configs before mappings/autocmds that rely on them.
-- ============================================================

require("lsp")
require("plugins")
require("autocmd")
require("mappings")


-- ============================================================
-- COLORSCHEME
-- ============================================================

vim.cmd("colorscheme kanagawa")


-- ============================================================
-- INDENT BLANKLINE
-- ============================================================

vim.api.nvim_set_hl(0, "IblIndent", {
    fg = "#3b4261", -- subtle grey-blue
})

vim.api.nvim_set_hl(0, "IblScope", {
    underline = true,
    sp = "#545c7e",
})

require("ibl").setup({
    indent = {
        highlight = "IblIndent",
        char = "▏",
    },

    scope = {
        enabled = true,
        show_start = false,
        show_end = false,
        highlight = "IblScope",
    },

    exclude = {
        filetypes = {
            "help",
            "alpha",
            "dashboard",
            "lazy",
            "mason",
            "oil",
            "terminal",
            "floaterm",
        },
    },
})


-- ============================================================
-- LUALINE HELPERS
-- ============================================================

local function floaterm_tabline()
    local tabs = {}
    local current = vim.api.nvim_get_current_buf()

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf)
            and vim.bo[buf].filetype == "floaterm"
        then
            local name = vim.fn.fnamemodify(
                vim.api.nvim_buf_get_name(buf),
                ":t"
            )

            local label = (buf == current and " " or " ")
                .. (name ~= "" and name or "Terminal")

            table.insert(tabs, label)
        end
    end

    return table.concat(tabs, " | ")
end

local mode = {
    "mode",
    fmt = function(str)
        return " " .. str
    end,
}

local diff = {
    "diff",
    symbols = {
        added = " ",
        modified = " ",
        removed = " ",
    },
}

local branch = {
    "branch",
    icon = "",
}

local lsp_status = {
    "lsp_status",
    icon = "",
    symbols = {
        spinner = {
            "⠋",
            "⠙",
            "⠹",
            "⠸",
            "⠼",
            "⠴",
            "⠦",
            "⠧",
            "⠇",
            "⠏",
        },
        done = "✓",
        separator = " ",
    },
    ignore_lsp = {},
    show_name = true,

    color = function()
        local clients = vim.lsp.get_clients({ bufnr = 0 })

        if #clients == 0 then
            return { fg = "#6c7086" }
        end

        if vim.lsp.status() ~= "" then
            return { fg = "#f9e2af" }
        end

        return { fg = "#a6e3a1" }
    end,
}

local cwd_component = {
    function()
        local cwd = vim.fn.getcwd()
        local home = vim.fn.expand("~")

        if cwd:find(home, 0, true) == 1 then
            cwd = "~" .. cwd:sub(#home + 0)
        end

        return "󰉋 " .. vim.fn.fnamemodify(cwd, ":t")
    end,
    color = {
        fg = "#88b4fa",
    },
}

local floaterm_component = {
    floaterm_tabline,
    cond = function()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.bo[buf].filetype == "floaterm" then
                return true
            end
        end

        return false
    end,
}


-- ============================================================
-- LUALINE
-- ============================================================

local lualine = require("lualine")
local kanagawa = require("lualine.themes.auto")

lualine.setup({
    options = {
        icons_enabled = true,
        theme = kanagawa,
        -- component_separators = {
        --     left = "|",
        --     right = "|",
        -- },
        -- section_separators = {
        --     left = "|",
        --     right = "",
        -- },
        component_separators = "",
        section_separators = "",
        disabled_filetypes = {
            statusline = {
                "oil",
                "toggleterm",
                "terminal",
            },
            winbar = {
                "oil",
                "toggleterm",
                "terminal",
            },
        },
    },

    sections = {
        lualine_a = {
            mode,
        },

        lualine_b = {
            branch,
            diff,
            {
                "diagnostics",
                sources = {
                    "nvim_diagnostic",
                },
                sections = {
                    "error",
                    "warn",
                    "info",
                    "hint",
                },
                symbols = {
                    error = " ",
                    warn = " ",
                    info = " ",
                    hint = "󰌵 ",
                },
                update_in_insert = true,
            },
            cwd_component,
            lsp_status,
            floaterm_component,
        },

        lualine_c = {},
        lualine_x = {},
    },
})


-- ============================================================
-- BUFFERLINE
-- ============================================================

require("bufferline").setup({
    options = {
        mode = "buffers",
        separator_style = "thin",

        indicator = {
            style = "underline",
        },

        show_buffer_icons = true,
        show_buffer_close_icons = false,
        show_close_icon = false,
        persist_buffer_sort = true,
        always_show_bufferline = false,
    },
})
