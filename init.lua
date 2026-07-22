-- ============================================================
-- PLUGINS
-- ============================================================

-- Remove callbacks left in memory when this config is re-sourced after the
-- migration from LuaSnip to Blink's native vim.snippet support.
for _, group in ipairs({ "_luasnip_lazy_load", "luasnip" }) do
    pcall(vim.api.nvim_del_augroup_by_name, group)
end
for _, command in ipairs({ "LuaSnipUnlinkCurrent", "LuaSnipListAvailable" }) do
    pcall(vim.api.nvim_del_user_command, command)
end
for _, mode in ipairs({ "n", "i", "s", "x" }) do
    for _, mapping in ipairs({
        "<Plug>luasnip-expand-or-jump",
        "<Plug>luasnip-expand-snippet",
        "<Plug>luasnip-next-choice",
        "<Plug>luasnip-prev-choice",
        "<Plug>luasnip-jump-next",
        "<Plug>luasnip-jump-prev",
        "<Plug>luasnip-delete-check",
        "<Plug>luasnip-expand-repeat",
    }) do
        pcall(vim.keymap.del, mode, mapping)
    end
end

-- Stop legacy session plugins when this config is re-sourced in an instance
-- that previously loaded them.
for _, group in ipairs({ "obsession", "prosession", "ProSession" }) do
    pcall(vim.api.nvim_del_augroup_by_name, group)
end
for _, command in ipairs({
    "Obsession",
    "Prosession",
    "ProsessionClean",
    "ProsessionDelete",
    "ProsessionInfo",
    "ProsessionLast",
}) do
    pcall(vim.api.nvim_del_user_command, command)
end
vim.g.this_obsession = nil

vim.pack.add({
    -- Navigation
    { src = "https://github.com/stevearc/oil.nvim" },
    { src = "https://github.com/folke/snacks.nvim" },
    { src = "https://github.com/voldikss/vim-floaterm" },
    { src = "https://github.com/chrisgrieser/nvim-rip-substitute" },
    { src = "https://github.com/stevearc/quicker.nvim" },
    { src = "https://github.com/folke/flash.nvim" },

    -- Debugging
    { src = "https://github.com/mason-org/mason.nvim" },
    { src = "https://github.com/mfussenegger/nvim-dap" },
    { src = "https://github.com/jay-babu/mason-nvim-dap.nvim" },
    { src = "https://github.com/nvim-neotest/nvim-nio" },
    { src = "https://github.com/rcarriga/nvim-dap-ui" },
    { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
    { src = "https://github.com/jbyuki/one-small-step-for-vimkind" },
    { src = "https://github.com/mfussenegger/nvim-jdtls" },

    -- UI
    { src = "https://github.com/nvim-tree/nvim-web-devicons" },
    { src = "https://github.com/rebelot/kanagawa.nvim" },
    { src = "https://github.com/lewis6991/gitsigns.nvim" },
    { src = "https://github.com/refractalize/oil-git-status.nvim" },
    { src = "https://github.com/sindrets/diffview.nvim" },
    { src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
    { src = "https://github.com/3rd/image.nvim" },
    { src = "https://github.com/nvim-lualine/lualine.nvim" },
    { src = "https://github.com/nvim-treesitter/nvim-treesitter" },
    { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
    { src = "https://github.com/akinsho/bufferline.nvim" },
    { src = "https://github.com/SmiteshP/nvim-navic" },

    -- LSP
    { src = "https://github.com/neovim/nvim-lspconfig" },
    { src = "https://github.com/b0o/SchemaStore.nvim" },

    -- Completion
    { src = "https://github.com/saghen/blink.cmp" },
    { src = "https://github.com/cohama/lexima.vim" },
    { src = "https://github.com/tronikelis/ts-autotag.nvim" },

    -- Snippets (Blink uses Neovim's native vim.snippet engine.)
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
vim.o.updatetime = 200
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
vim.o.cursorlineopt = "number,line"
vim.o.signcolumn = "yes"
vim.o.laststatus = 3
vim.o.showmode = false
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
    severity_sort = true,
    update_in_insert = false,
    virtual_text = {
        spacing = 2,
        source = "if_many",
        prefix = "●",
    },
    float = {
        border = "rounded",
    },
})


-- ============================================================
-- WINBAR
-- Shows current function/class path using nvim-navic.
-- ============================================================


vim.o.winbar = "%{%v:lua.require'nvim-navic'.get_location()%}"


-- ============================================================
-- MODULE LOAD ORDER
-- Load plugin configs before mappings/autocmds that rely on them.
-- ============================================================

require("workspace").setup()
require("lsp")
require("plugins")
require("debugger_bootstrap")
require("mobile").setup()
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
                "lazygit",
                "toggleterm",
                "terminal",
            },
            winbar = {
                "oil",
                "lazygit",
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
        },

        lualine_c = {
            {
                "filename",
                path = 1,
                symbols = {
                    modified = " ●",
                    readonly = " ",
                    unnamed = "[Untitled]",
                },
            },
        },

        lualine_x = {
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
                update_in_insert = false,
            },
            lsp_status,
        },

        lualine_y = {
            cwd_component,
            floaterm_component,
        },

        lualine_z = {
            "location",
            "progress",
        },
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
        name_formatter = function(buf)
            if vim.bo[buf.bufnr].filetype == "lazygit" then return " LazyGit" end
            return buf.name
        end,
    },
})
