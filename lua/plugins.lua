-- ============================================================
-- PLUGIN CONFIGS
-- ============================================================


-- ============================================================
-- Kanagawa Theme
-- ============================================================

require("kanagawa").setup({
    compile = false,
    undercurl = true,

    commentStyle = { italic = true },
    functionStyle = {},
    keywordStyle = { italic = false },
    statementStyle = { bold = true },
    typeStyle = {},

    transparent = true,
    dimInactive = false,
    terminalColors = true,

    colors = {
        palette = {},
        theme = {
            wave = {},
            dragon = {},
            all = {
                ui = {
                    bg_gutter = "none",
                    border = "rounded",
                },
            },
        },
    },

    overrides = function(colors)
        local theme = colors.theme

        local makeDiagnosticColor = function(color)
            local c = require("kanagawa.lib.color")
            return {
                fg = color,
                bg = c(color):blend(theme.ui.bg, 0.95):to_hex(),
            }
        end

        return {
            NormalFloat = { bg = "none" },
            FloatBorder = { bg = "none" },
            FloatTitle = { bg = "none" },

            Pmenu = {
                fg = theme.ui.shade0,
                bg = "NONE",
                blend = vim.o.pumblend,
            },
            PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
            PmenuSbar = { bg = theme.ui.bg_m1 },
            PmenuThumb = { bg = theme.ui.bg_p2 },

            NormalDark = {
                fg = theme.ui.fg_dim,
                bg = theme.ui.bg_m3,
            },

            LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
            MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

            TelescopeTitle = { fg = theme.ui.special, bold = true },
            TelescopePromptBorder = { fg = theme.ui.special },
            TelescopeResultsNormal = { fg = theme.ui.fg_dim },
            TelescopeResultsBorder = { fg = theme.ui.special },
            TelescopePreviewBorder = { fg = theme.ui.special },

            BufferLineBufferSelected = {
                fg = theme.ui.fg,
                bg = "none",
                bold = true,
            },
            BufferLineFill = { bg = "none" },
            BufferLineBackground = { bg = "none" },
            BufferLineSeparator = { fg = theme.ui.bg_m3, bg = "none" },
            BufferLineSeparatorVisible = { fg = theme.ui.bg_m3, bg = "none" },
            BufferLineSeparatorSelected = { fg = theme.ui.bg_m3, bg = "none" },
            BufferLineIndicatorSelected = {
                fg = theme.ui.special,
                sp = theme.ui.special,
                bold = true,
                underline = true,
            },

            DiagnosticVirtualTextHint = makeDiagnosticColor(theme.diag.hint),
            DiagnosticVirtualTextInfo = makeDiagnosticColor(theme.diag.info),
            DiagnosticVirtualTextWarn = makeDiagnosticColor(theme.diag.warning),
            DiagnosticVirtualTextError = makeDiagnosticColor(theme.diag.error),

            String = {
                fg = colors.palette.carpYellow,
                italic = true,
            },
        }
    end,

    theme = "wave",
    background = {
        dark = "dragon",
    },
})


-- ============================================================
-- fzf-lua
-- ============================================================

require("fzf-lua").setup({
    winopts = {
        preview = {
            layout = "vertical",
            vertical = "up:60%",
        },
    },
    lsp = {
        symbols = {
            symbol_icons = true,
        },
    },
})


-- ============================================================
-- Treesitter / Auto Tag
-- ============================================================

require("ts-autotag").setup({})

require("nvim-treesitter").setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
})

require("nvim-treesitter").install({ "javascript" })


-- ============================================================
-- Snacks
-- ============================================================

require("snacks").setup({
    picker = {
        ui_select = true,

        layout = {
            cycle = true,
            style = "modern",
        },

        win = {
            input = {
                keys = {
                    ["<C-d>"] = { "bufdelete", mode = { "n", "i" } },
                },
            },
        },

        matcher = {
            frecency = true,
        },

        exclude = {
            "node_modules",
            ".git",
            "dist",
            "build",
            "target",
        },

        sources = {
            files = {
                hidden = true,
            },
        },
    },
})


-- ============================================================
-- Oil File Explorer
-- ============================================================

require("oil").setup({
    default_file_explorer = true,
    watch_for_changes = true,
    delete_to_trash = true,

    columns = {
        "icon",
    },

    skip_confirm_for_simple_edits = true,
    use_default_keymaps = false,

    view_options = {
        show_hidden = true,
    },

    float = {
        padding = 2,
        max_width = 80,
        max_height = 20,
        border = "rounded",
    },

    keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = "actions.select",
        ["zv"] = { "actions.select", opts = { vertical = true } },
        ["zh"] = { "actions.select", opts = { horizontal = true } },
        ["<C-t>"] = { "actions.select", opts = { tab = true } },
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = { "actions.close", mode = "n" },
        ["<C-l>"] = "actions.refresh",
        ["<BS>"] = { "actions.parent", mode = "n" },
        ["gr"] = { "actions.open_cwd", mode = "n" },
        ["gc"] = { "actions.cd", mode = "n" },

        -- Reveal selected file/folder in Finder.
        ["gd"] = {
            function()
                local oil = require("oil")
                local entry = oil.get_cursor_entry()
                local dir = oil.get_current_dir()

                if not entry or not dir then
                    print("No entry found")
                    return
                end

                local path = dir .. entry.name
                print("Reveal:", path)
                vim.system({ "open", "-R", path }):wait()
            end,
            mode = "n",
        },

        -- Open selected file/folder externally.
        ["go"] = {
            function()
                local oil = require("oil")
                local entry = oil.get_cursor_entry()
                local dir = oil.get_current_dir()

                if not entry or not dir then
                    print("No entry found")
                    return
                end

                local path = dir .. entry.name
                print("Open:", path)
                vim.system({ "open", path }):wait()
            end,
            mode = "n",
        },

        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["gt"] = { "actions.toggle_trash", mode = "n" },
    },

    keys = {
        vim.keymap.set({ "n", "i", "v" }, "<C-e>", function()
            vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
                "n",
                true
            )
            require("oil").toggle_float()
        end, {
            desc = "Toggle Oil Float",
        }),
    },

    win_options = {
        signcolumn = "yes:2",
    },
})


-- ============================================================
-- Oil Git Status
-- ============================================================

require("oil-git-status").setup({
    show_ignored = true,

    symbols = {
        index = {
            ["!"] = "!",
            ["?"] = "?",
            ["A"] = "A",
            ["C"] = "C",
            ["D"] = "D",
            ["M"] = "M",
            ["R"] = "R",
            ["T"] = "T",
            ["U"] = "U",
            [" "] = " ",
        },
        working_tree = {
            ["!"] = "!",
            ["?"] = "?",
            ["A"] = "A",
            ["C"] = "C",
            ["D"] = "D",
            ["M"] = "M",
            ["R"] = "R",
            ["T"] = "T",
            ["U"] = "U",
            [" "] = " ",
        },
    },
})


-- ============================================================
-- Image Rendering
-- Kitty image backend for markdown/images.
-- ============================================================

require("image").setup({
    backend = "kitty",
    processor = "magick_cli",

    integrations = {
        markdown = {
            enabled = true,
            clear_in_insert_mode = false,
            download_remote_images = true,
            only_render_image_at_cursor = false,
            only_render_image_at_cursor_mode = "popup",
            floating_windows = false,
            filetypes = { "markdown", "vimwiki" },
        },
        neorg = {
            enabled = true,
            filetypes = { "norg" },
        },
        typst = {
            enabled = true,
            filetypes = { "typst" },
        },
        html = {
            enabled = false,
        },
        css = {
            enabled = false,
        },
    },

    max_width = nil,
    max_height = nil,
    max_width_window_percentage = nil,
    max_height_window_percentage = 50,

    window_overlap_clear_enabled = false,
    window_overlap_clear_ft_ignore = {
        "cmp_menu",
        "cmp_docs",
        "snacks_notif",
        "scrollview",
        "scrollview_sign",
    },

    editor_only_render_when_focused = false,
    tmux_show_only_in_active_window = false,

    hijack_file_patterns = {
        "*.png",
        "*.jpg",
        "*.jpeg",
        "*.gif",
        "*.webp",
        "*.avif",
    },
})


-- ============================================================
-- Floaterm
-- ============================================================

vim.g.floaterm_autoclose = true

vim.api.nvim_create_autocmd("FileType", {
    pattern = "floaterm",
    callback = function()
        local opts = {
            noremap = true,
            silent = true,
            buffer = true,
        }

        vim.keymap.set("t", "<C-k>", "<C-\\><C-n>:q<CR>", opts)
        vim.keymap.set("n", "<C-k>", ":q<CR>", opts)
    end,
})

vim.api.nvim_set_keymap("n", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zp", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zn", "<cmd>:FloatermNext<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<C-t>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<C-t>", "<cmd>FloatermNew<CR>", { noremap = true, silent = true })


-- ============================================================
-- Gitsigns
-- ============================================================

require("gitsigns").setup({
    signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
    },

    update_debounce = 100,
    status_formatter = nil,
})


-- ============================================================
-- LeetCode
-- ============================================================

require("leetcode").setup({
    lang = "python3",
    image_support = true,

    storage = {
        home = "~/Documents/Github/Leetcode",
        cache = vim.fn.stdpath("cache") .. "/leetcode",
    },
})


-- ============================================================
-- Alpha Dashboard
-- ============================================================

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")

dashboard.section.header.val = {
    "                                                 ",
    " ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
    " ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
    " ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
    " ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
    " ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
    " ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
    "                                                 ",
}

dashboard.section.header.opts.position = "center"
dashboard.section.footer.opts.position = "center"

dashboard.section.buttons.val = {
    dashboard.button("o", "  Open Folders", function()
        require("oil").open("~/")
    end),

    dashboard.button("p", "  Open Github Folders", function()
        require("oil").open("~/Documents/Github/")
    end),

    dashboard.button("r", "  Connect to Remote", "<cmd>SshLauncher<CR>"),

    dashboard.button(
        "l",
        "  LeetCode",
        "<cmd>silent !kitty @ launch --type=tab --cwd=$(pwd) nvim +'lua vim.schedule(function() vim.cmd(\"Leet\") end)'<CR>"
    ),

    dashboard.button("t", "  Terminal", function()
        vim.cmd("term")
        vim.api.nvim_feedkeys("i", "n", false)
    end),
}

local fortune = require("alpha.fortune")
dashboard.section.footer.val = fortune()

dashboard.section.header.opts.hl = "Statement"
dashboard.section.buttons.opts.hl = "Type"
dashboard.section.footer.opts.hl = "Type"

table.insert(dashboard.opts.layout, 1, {
    type = "padding",
    val = 5,
})

alpha.setup(dashboard.opts)


-- ============================================================
-- Misc Plugin Setup
-- ============================================================

require("ssh_launcher").setup()
require("grug-far").setup()
