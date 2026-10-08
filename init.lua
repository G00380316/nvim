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
    -- blink.lib is a hard dependency of blink.cmp from v2 onward; without it
    -- blink.cmp errors out at require time and takes the rest of init with it.
    { src = "https://github.com/saghen/blink.lib" },
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
    { src = "https://github.com/G00380316/live-server.nvim" },

    -- AI (OpenAI API key required -- a ChatGPT subscription does not cover it)
    { src = "https://github.com/olimorris/codecompanion.nvim" },
    { src = "https://github.com/wojciech-kulik/xcodebuild.nvim" },

    -- Shows what the next key does when you pause after a prefix
    { src = "https://github.com/folke/which-key.nvim" },
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

-- Insert mode gets its own cursor colour, so the mode shows at the cursor
-- itself, not only in the statusline.
local function insert_cursor_color()
    vim.api.nvim_set_hl(0, "CursorInsert", { bg = "#98bb6c", fg = "#1f1f28" })
end
insert_cursor_color()
vim.api.nvim_create_autocmd("ColorScheme", { callback = insert_cursor_color })
vim.o.guicursor = "a:Cursor/Cursor,n-v-c-sm:block-blinkon1,i-ci-ve:ver25-CursorInsert,r-cr-o:hor20"

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
    -- Message text only on the line the cursor is on; every other problem is
    -- just a mark in the sign column. A file full of errors stays readable.
    virtual_text = {
        spacing = 2,
        source = "if_many",
        prefix = "●",
        current_line = true,
    },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = "󰌵 ",
        },
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
require("panel_titles").setup()
require("responsive").setup()


-- ============================================================
-- MODULE LOAD ORDER
-- Load plugin configs before mappings/autocmds that rely on them.
-- ============================================================

require("workspace").setup()
require("lsp")
require("plugins")
require("debugger_bootstrap")
require("mobile").setup()
require("terminals").setup()
require("action_menus").setup()
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

-- Terminals are identified by their working directory rather than the shell
-- binary: `:t` on a terminal buffer name only ever yielded "zsh", identical
-- for every terminal and useless for telling them apart. The focused terminal
-- is highlighted so the active one is obvious at a glance.
local function floaterm_tabline()
    return require("terminals").tabline()
end

local mode = {
    "mode",
    fmt = function(str)
        return " " .. str
    end,
}

local branch = {
    "branch",
    cond = function() return require("responsive").show_statusline_part("branch") end,
    icon = "",
}

local lsp_status = {
    "lsp_status",
    cond = function() return require("responsive").show_statusline_part("lsp") end,
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

-- The project you are in, by the name you gave it. A file open from outside
-- it takes searches with it, and that is worth seeing: a scope that moved
-- silently is the kind of thing you only notice through its results.
local cwd_component = {
    cond = function() return require("responsive").show_statusline_part("project") end,
    function()
        local workspace = require("workspace")
        local visiting = workspace.visiting()
        local label = "󰉋 " .. workspace.label()

        return visiting and (label .. " \u{203a} " .. workspace.label(visiting)) or label
    end,
    color = {
        fg = "#88b4fa",
    },
}

local floaterm_component = {
    floaterm_tabline,
    cond = function()
        if not require("responsive").show_statusline_part("terminals") then return false end
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
        -- Nothing is excluded: the statusline is the one constant piece of
        -- chrome, so blanking it in the explorer or a terminal made those
        -- panels look detached from the rest of the frame.
        disabled_filetypes = {
            statusline = {},
            winbar = {},
        },
    },

    sections = {
        lualine_a = {
            mode,
        },

        -- Branch only: what changed is already marked in the gutter by
        -- gitsigns, and the counts here just repeated it.
        lualine_b = {
            branch,
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
                -- A terminal's buffer name is the raw
                -- `term://<cwd>//<pid>:<shell>` URI: long, and it says nothing
                -- useful. Show the terminal's directory instead.
                fmt = function(name)
                    if vim.bo.filetype == "floaterm" then
                        return require("terminals").name(vim.api.nvim_get_current_buf())
                    end
                    -- Folder and file, not the whole path from the project
                    -- root: enough to tell two files of one name apart.
                    local parts = vim.split(name, "/", { plain = true })
                    if #parts > 2 then
                        return parts[#parts - 1] .. "/" .. parts[#parts]
                    end
                    return name
                end,
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

        -- Where the cursor is. The percentage through the file is dropped:
        -- the line number says the same with less to read.
        lualine_z = {
            "location",
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

        modified_icon = "●",
        truncate_names = true,
        max_name_length = 24,
        show_duplicate_prefix = true,
        diagnostics = false,
        show_buffer_icons = true,
        show_buffer_close_icons = false,
        show_close_icon = false,
        persist_buffer_sort = true,
        always_show_bufferline = false,

        -- What is drawn here is exactly what <Tab>/<S-Tab>/<C-b> cycle
        -- through: every editor buffer, from any project. The two lists have
        -- to agree -- a tab no key can reach, or a key landing somewhere with
        -- no tab, is the same confusion either way round.
        custom_filter = function(bufnr)
            return require("buffers").is_editor(bufnr)
        end,
        name_formatter = function(buf)
            if vim.bo[buf.bufnr].filetype == "lazygit" then return " LazyGit" end
            return buf.name
        end,
    },
})
