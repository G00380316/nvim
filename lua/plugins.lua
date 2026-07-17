-- ============================================================
-- PLUGIN CONFIGS
-- ============================================================

local Snacks = require("snacks")

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

    transparent = false,
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
            NormalFloat = { bg = theme.ui.bg_m1 },
            FloatBorder = { fg = theme.ui.bg_p2, bg = theme.ui.bg_m1 },
            FloatTitle = { fg = theme.ui.special, bg = theme.ui.bg_m1, bold = true },

            Pmenu = {
                fg = theme.ui.shade0,
                bg = theme.ui.bg_m1,
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
                bg = theme.ui.bg_p1,
                bold = true,
            },
            BufferLineFill = { bg = theme.ui.bg_m3 },
            BufferLineBackground = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },
            BufferLineSeparator = { fg = theme.ui.bg_m3, bg = theme.ui.bg_m3 },
            BufferLineSeparatorVisible = { fg = theme.ui.bg_m3, bg = theme.ui.bg_m3 },
            BufferLineSeparatorSelected = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
            BufferLineIndicatorSelected = {
                fg = theme.ui.special,
                sp = theme.ui.special,
                bold = true,
                underline = true,
            },

            NvimTreeNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
            NvimTreeNormalNC = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
            NvimTreeCursorLine = { bg = theme.ui.bg_p1 },
            NvimTreeWinSeparator = { fg = theme.ui.bg_p2, bg = theme.ui.bg_m1 },
            WinSeparator = { fg = theme.ui.bg_p2, bg = theme.ui.bg },

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
-- Treesitter / Auto Tag
-- ============================================================

require("ts-autotag").setup({})

require("nvim-treesitter").setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
})


-- ============================================================
-- Snacks
-- ============================================================

require("snacks").setup({
    bigfile = { enabled = true },
    dashboard = {
        enabled = true,
        width = 48,
        preset = {
            header = [[
███╗   ██╗██╗   ██╗██╗███╗   ███╗
████╗  ██║██║   ██║██║████╗ ████║
██╔██╗ ██║██║   ██║██║██╔████╔██║
██║╚██╗██║╚██╗ ██╔╝██║██║╚██╔╝██║
██║ ╚████║ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═══╝  ╚═══╝  ╚═╝╚═╝     ╚═╝]],
            keys = {
                { icon = "󰉋 ", key = "o", desc = "Open Workspace", action = "<C-o>" },
                {
                    icon = " ",
                    key = "f",
                    desc = "Find File",
                    action = function()
                        Snacks.picker.files({ cwd = require("workspace").get() })
                    end,
                },
                {
                    icon = " ",
                    key = "g",
                    desc = "Find Text",
                    action = function()
                        Snacks.picker.grep({ cwd = require("workspace").get() })
                    end,
                },
                { icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
                { icon = " ", key = "t", desc = "Terminal", action = "<C-t>" },
                { icon = " ", key = "q", desc = "Quit", action = ":confirm qa" },
            },
        },
        sections = {
            { section = "header" },
            { section = "keys", gap = 1, padding = 1 },
            {
                icon = " ",
                title = "Recent Workspaces",
                section = "projects",
                dirs = function() return require("workspace").recent(5) end,
                session = false,
                pick = false,
                limit = 5,
                padding = 1,
                action = function(dir)
                    require("workspace").open(dir, { exact = true })
                end,
            },
        },
    },
    input = { enabled = true },
    quickfile = { enabled = true },
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
                    ["<Space>l"] = { "flash", mode = { "n", "i" } },
                    ["s"] = { "flash" },
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

        actions = {
            flash = function(picker)
                require("flash").jump({
                    pattern = "^",
                    label = { after = { 0, 0 } },
                    search = {
                        mode = "search",
                        exclude = {
                            function(win)
                                return vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "snacks_picker_list"
                            end,
                        },
                    },
                    action = function(match)
                        local idx = picker.list:row2idx(match.pos[1])
                        picker.list:_move(idx, true, true)
                    end,
                })
            end,
        },

    },
})

-- A dashboard is the permanent empty editor zone, so closing it should quit
-- Neovim rather than let the fixed sidebar or terminal consume its space.
vim.api.nvim_create_autocmd("User", {
    pattern = "SnacksDashboardOpened",
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].filetype == "snacks_dashboard" then
            require("dashboard").keep_single(buf)
            vim.keymap.set("n", "q", "<cmd>confirm qa<CR>", {
                buffer = buf,
                silent = true,
                desc = "Quit from empty workspace dashboard",
            })
            vim.keymap.set("n", "<C-q>", "<cmd>confirm qa<CR>", {
                buffer = buf,
                silent = true,
                desc = "Quit from empty workspace dashboard",
            })
        end
    end,
    desc = "Keep the dashboard as the editor-area filler",
})


-- ============================================================
-- NvimTree File Explorer
-- ============================================================

local tree_api = require("nvim-tree.api")
local tree_sort_modes = { "name", "extension", "modification_time" }
local tree_sort_index = 1
local tree_width = 30
local last_editor_win = nil
local last_panel_win = nil

local function leetcode_active()
    return vim.g.leetcode_active == true
end

local function window_is_valid(win)
    return win and vim.api.nvim_win_is_valid(win)
end

local function window_filetype(win)
    return window_is_valid(win) and vim.bo[vim.api.nvim_win_get_buf(win)].filetype or ""
end

local function is_panel(win)
    local filetype = window_filetype(win)
    return filetype == "NvimTree"
        or filetype == "floaterm"
        or filetype == "NeogitStatus"
        or filetype == "grug-far"
end

local function find_window(filetype)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if window_filetype(win) == filetype then
            return win
        end
    end
end

local function find_editor_window()
    if window_is_valid(last_editor_win) and not is_panel(last_editor_win) then
        return last_editor_win
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local config = vim.api.nvim_win_get_config(win)
        if not is_panel(win) and config.relative == "" then
            return win
        end
    end
end

local function focus_editor()
    local current = vim.api.nvim_get_current_win()
    if is_panel(current) then
        last_panel_win = current
    end
    local editor = find_editor_window()
    if editor then
        last_editor_win = editor
        vim.api.nvim_set_current_win(editor)
        return true
    end
    return false
end

local function focus_editor_or_last_panel()
    local current = vim.api.nvim_get_current_win()
    if is_panel(current) then
        focus_editor()
    elseif window_is_valid(last_panel_win) and is_panel(last_panel_win) then
        last_editor_win = current
        vim.api.nvim_set_current_win(last_panel_win)
    end
end

local function switch_editor_buffer(direction)
    if focus_editor() or not is_panel(vim.api.nvim_get_current_win()) then
        vim.cmd(direction > 0 and "bnext" or "bprevious")
    end
end

local function focus_tree()
    if leetcode_active() then
        vim.notify("NvimTree is disabled in LeetCode", vim.log.levels.INFO)
        return
    end

    local current = vim.api.nvim_get_current_win()
    if window_filetype(current) == "NvimTree" then
        tree_api.tree.close()
        return
    end

    local tree = find_window("NvimTree")
    if tree then
        last_editor_win = not is_panel(current) and current or last_editor_win
        last_panel_win = tree
        vim.api.nvim_set_current_win(tree)
    else
        tree_api.tree.open({ path = require("workspace").get(), focus = true })
        last_panel_win = vim.api.nvim_get_current_win()
    end
end

local function focus_terminal()
    local current = vim.api.nvim_get_current_win()
    if window_filetype(current) == "floaterm" then
        vim.cmd("FloatermToggle")
        return
    end

    local terminal = find_window("floaterm")
    if terminal then
        last_editor_win = not is_panel(current) and current or last_editor_win
        last_panel_win = terminal
        vim.api.nvim_set_current_win(terminal)
        vim.cmd("startinsert")
    else
        focus_editor()
        vim.cmd("FloatermToggle")
    end
end

vim.api.nvim_create_autocmd("WinEnter", {
    callback = function()
        local win = vim.api.nvim_get_current_win()
        if not is_panel(win) and vim.api.nvim_win_get_config(win).relative == "" then
            last_editor_win = win
        end
    end,
    desc = "Remember the editor window between sidebar and terminal visits",
})

local function tree_node_path()
    local node = tree_api.tree.get_node_under_cursor()
    return node and node.absolute_path or nil
end

local function nvim_tree_on_attach(bufnr)
    local function map(lhs, rhs, desc)
        vim.keymap.set("n", lhs, rhs, {
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
            desc = "NvimTree: " .. desc,
        })
    end

    local function open_tree_node(action)
        local node = tree_api.tree.get_node_under_cursor()
        if node and node.name == ".git" and node.type == "directory" then
            vim.notify(".git stays collapsed in the project explorer", vim.log.levels.INFO)
            return
        end
        action()
    end

    -- Preserve the previous explorer mappings.
    map("g?", tree_api.tree.toggle_help, "Help")
    map("<CR>", function() open_tree_node(tree_api.node.open.edit) end, "Open")
    map("zv", function() open_tree_node(tree_api.node.open.vertical) end, "Open: Vertical Split")
    map("zh", function() open_tree_node(tree_api.node.open.horizontal) end, "Open: Horizontal Split")
    map("gT", function() open_tree_node(tree_api.node.open.tab) end, "Open: New Tab")
    map("<C-t>", focus_terminal, "Focus/Toggle Terminal")
    map("<C-p>", tree_api.node.open.preview, "Preview")
    map("<C-c>", tree_api.tree.close, "Hide Explorer")
    map("q", tree_api.tree.close, "Hide Explorer")
    map("<Space>l", tree_api.tree.reload, "Refresh")
    map("<BS>", tree_api.node.navigate.parent_close, "Parent Node")
    map("gr", function()
        tree_api.tree.change_root(vim.fn.getcwd())
    end, "Open Working Directory")
    map("gc", function()
        local path = tree_node_path()
        if not path then return end
        local dir = vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
        require("workspace").set(dir, { exact = true })
    end, "Set Workspace Root")
    map("gd", function()
        local path = tree_node_path()
        if path then vim.system({ "open", "-R", path }, { detach = true }) end
    end, "Reveal in Finder")
    map("go", function()
        local path = tree_node_path()
        if path then vim.system({ "open", path }, { detach = true }) end
    end, "Open Externally")
    map("gs", function()
        tree_sort_index = tree_sort_index % #tree_sort_modes + 1
        tree_api.tree.reload()
        vim.notify("Explorer sorted by " .. tree_sort_modes[tree_sort_index]:gsub("_", " "))
    end, "Change Sort")
    map("gx", tree_api.node.run.system, "Open Externally")
    map("g.", tree_api.filter.dotfiles.toggle, "Toggle Hidden Files")
    map("gt", function()
        local trash = vim.fn.expand("~/.Trash")
        if vim.fn.isdirectory(trash) == 1 then tree_api.tree.change_root(trash) end
    end, "Open Trash")

    -- Familiar tree editing/navigation keys in addition to the preserved keys.
    map("a", tree_api.fs.create, "Create")
    map("r", tree_api.fs.rename, "Rename")
    map("d", tree_api.fs.trash, "Trash")
    map("x", tree_api.fs.cut, "Cut")
    map("c", tree_api.fs.copy.node, "Copy")
    map("p", tree_api.fs.paste, "Paste")
    map("y", tree_api.fs.copy.filename, "Copy Name")
    map("Y", tree_api.fs.copy.absolute_path, "Copy Absolute Path")
    map("<Tab>", function() switch_editor_buffer(1) end, "Next Editor Tab")
    map("<S-Tab>", function() switch_editor_buffer(-1) end, "Previous Editor Tab")
end

require("nvim-tree").setup({
    on_attach = nvim_tree_on_attach,
    hijack_netrw = true,
    sync_root_with_cwd = true,
    respect_buf_cwd = true,
    sort = {
        sorter = function()
            return tree_sort_modes[tree_sort_index]
        end,
    },
    update_focused_file = {
        enable = true,
        update_root = false,
        exclude = function(event)
            local path = vim.api.nvim_buf_get_name(event.buf)
            local filetype = vim.bo[event.buf].filetype
            return path:find("/%.git/") ~= nil
                or filetype:match("^Neogit") ~= nil
                or filetype == "gitcommit"
                or filetype == "gitrebase"
        end,
    },
    view = {
        side = "left",
        width = tree_width,
        preserve_window_proportions = true,
        signcolumn = "yes",
    },
    renderer = {
        group_empty = true,
        highlight_git = "name",
        highlight_opened_files = "name",
        indent_markers = { enable = true },
    },
    filters = {
        dotfiles = false,
        git_ignored = false,
    },
    git = {
        enable = true,
        ignore = false,
        show_on_dirs = true,
    },
    diagnostics = { enable = true },
    actions = {
        open_file = {
            quit_on_open = false,
            resize_window = false,
            window_picker = { enable = true },
        },
    },
    tab = {
        sync = { open = true, close = true },
    },
})

-- Keep the explorer at a compact IDE-sidebar width. winfixwidth prevents
-- editor splits and equalize commands from stretching it.
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    pattern = "NvimTree",
    callback = function(args)
        local win = vim.fn.bufwinid(args.buf)
        if win == -1 then
            return
        end

        vim.wo[win].winfixwidth = true
        if vim.api.nvim_win_get_width(win) ~= tree_width then
            vim.api.nvim_win_set_width(win, tree_width)
        end
    end,
    desc = "Lock the project explorer to a compact sidebar width",
})

vim.keymap.set({ "n", "i", "v" }, "<C-e>", function()
    if vim.fn.mode():sub(1, 1) ~= "n" then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end
    focus_tree()
end, {
    noremap = true,
    silent = true,
    desc = "Show/Hide File Explorer",
})

-- Keep the project explorer present like an IDE sidebar. It stays open when
-- files are selected; q, Ctrl-C, or Ctrl-E explicitly hide it.
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function(data)
        vim.defer_fn(function()
            if leetcode_active() then
                tree_api.tree.close()
                return
            end

            local path = vim.api.nvim_buf_get_name(data.buf)
            local root = require("workspace").get()
            if tree_api.tree.is_visible() then
                tree_api.tree.change_root(root)
            else
                tree_api.tree.toggle({ path = root, focus = false })
            end
            if path ~= "" and vim.fn.isdirectory(path) ~= 1 then
                tree_api.tree.find_file({ buf = data.buf, open = true, focus = false })
            end
        end, 50)
    end,
    desc = "Open the persistent project explorer sidebar",
})


-- ============================================================
-- Image Rendering
-- Kitty image backend for markdown/images.
-- ============================================================

vim.api.nvim_create_autocmd("BufReadPost", {
    pattern = { "*.md", "*.markdown", "*.norg", "*.typ", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    once = true,
    callback = function()
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
    end,
    desc = "Load image rendering only for documents that need it",
})


-- ============================================================
-- Floaterm
-- ============================================================

vim.g.floaterm_wintype = "split"
vim.g.floaterm_position = "belowright"
local terminal_height = 12
vim.g.floaterm_height = terminal_height
vim.g.floaterm_autoclose = 0
vim.g.floaterm_autohide = 1
vim.g.floaterm_title = "terminal $1/$2"

-- Use the same slim separator language for the bottom panel and sidebar.
vim.opt.fillchars:append({
    vert = "│",
    horiz = "─",
    horizup = "┴",
    horizdown = "┬",
    verthoriz = "┼",
})

local function resize_terminal(delta)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local bufnr = vim.api.nvim_win_get_buf(win)
        if vim.bo[bufnr].filetype == "floaterm" then
            local height = vim.api.nvim_win_get_height(win)
            local maximum = math.max(5, vim.o.lines - 6)
            terminal_height = math.max(5, math.min(maximum, height + delta))
            vim.g.floaterm_height = terminal_height
            vim.api.nvim_win_set_height(win, terminal_height)
            return
        end
    end
    vim.notify("Terminal panel is hidden", vim.log.levels.INFO)
end

local function new_terminal()
    focus_editor()
    vim.cmd("FloatermNew --cwd=" .. vim.fn.fnameescape(require("workspace").get()))
end

vim.api.nvim_create_autocmd("FileType", {
    pattern = "floaterm",
    callback = function()
        local opts = {
            noremap = true,
            silent = true,
            buffer = true,
        }

        vim.wo.winfixheight = true
        vim.wo.winhighlight = "WinSeparator:NvimTreeWinSeparator"
        vim.b.floaterm_position = "belowright"
        terminal_height = math.min(terminal_height, math.max(5, vim.o.lines - 6))
        vim.api.nvim_win_set_height(0, terminal_height)

        if not vim.b.floaterm_initial_clear then
            vim.b.floaterm_initial_clear = true
            local buf = vim.api.nvim_get_current_buf()
            vim.defer_fn(function()
                if not vim.api.nvim_buf_is_valid(buf) then return end
                local job = vim.b[buf].terminal_job_id
                if job then vim.api.nvim_chan_send(job, "clear\r") end
            end, 150)
        end

        vim.keymap.set("t", "<C-Up>", function() resize_terminal(3) end, opts)
        vim.keymap.set("t", "<C-Down>", function() resize_terminal(-3) end, opts)
        vim.keymap.set("n", "<C-Up>", function() resize_terminal(3) end, opts)
        vim.keymap.set("n", "<C-Down>", function() resize_terminal(-3) end, opts)
    end,
})

vim.api.nvim_set_keymap("n", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zp", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zn", "<cmd>:FloatermNext<CR>", { noremap = true, silent = true })

vim.keymap.set({ "n", "v", "i" }, "<C-t>", focus_terminal, {
    noremap = true,
    silent = true,
    desc = "Focus/toggle bottom terminal",
})

vim.keymap.set("n", "<Space>t", new_terminal, {
    noremap = true,
    silent = true,
    desc = "Open another bottom terminal",
})

vim.keymap.set("t", "<C-t>", function()
    vim.cmd("stopinsert")
    focus_terminal()
end, { silent = true, desc = "Hide bottom terminal" })

vim.keymap.set("t", "<C-e>", function()
    vim.cmd("stopinsert")
    focus_tree()
end, { silent = true, desc = "Focus file explorer" })

local function navigate_window(direction, tmux_flag)
    if vim.fn.mode() == "t" then vim.cmd("stopinsert") end

    local current = vim.api.nvim_get_current_win()
    vim.cmd("wincmd " .. direction)

    -- At a Neovim edge, continue into the adjacent tmux pane when available.
    if vim.api.nvim_get_current_win() == current and vim.env.TMUX and vim.env.TMUX ~= "" then
        vim.system({ "tmux", "select-pane", tmux_flag }, { detach = true })
        return
    end

    if window_filetype(vim.api.nvim_get_current_win()) == "floaterm" then
        vim.cmd("startinsert")
    end
end

local function map_window_navigation(lhs, direction, tmux_flag, label)
    vim.keymap.set({ "n", "t" }, lhs, function()
        navigate_window(direction, tmux_flag)
    end, { silent = true, desc = "Move to " .. label .. " window/tmux pane" })
end

map_window_navigation("<C-h>", "h", "-L", "left")
map_window_navigation("<C-j>", "j", "-D", "lower")
map_window_navigation("<C-k>", "k", "-U", "upper")
map_window_navigation("<C-l>", "l", "-R", "right")

vim.api.nvim_create_user_command("FocusEditor", focus_editor_or_last_panel, {
    desc = "Switch between the editor and the last focused panel",
})
vim.api.nvim_create_user_command("EditorFocus", focus_editor, {
    desc = "Focus the center editor without toggling back to a panel",
})
vim.api.nvim_create_user_command("FocusTree", focus_tree, { desc = "Focus or toggle the file explorer" })
vim.api.nvim_create_user_command("FocusTerminal", focus_terminal, { desc = "Focus or toggle the terminal" })
vim.api.nvim_create_user_command("TerminalNew", new_terminal, { desc = "Open another bottom terminal" })
vim.api.nvim_create_user_command("EditorTabNext", function()
    switch_editor_buffer(1)
end, { desc = "Open the next editor tab from any panel" })
vim.api.nvim_create_user_command("EditorTabPrevious", function()
    switch_editor_buffer(-1)
end, { desc = "Open the previous editor tab from any panel" })

vim.keymap.set("n", "ztk", function() resize_terminal(3) end, {
    desc = "Make terminal panel taller",
})

vim.keymap.set("n", "ztj", function() resize_terminal(-3) end, {
    desc = "Make terminal panel shorter",
})


-- ============================================================
-- Source Control
-- ============================================================

local git_width = tree_width

require("diffview").setup({
    enhanced_diff_hl = true,
    use_icons = true,
    file_panel = {
        listing_style = "tree",
        win_config = {
            position = "left",
            width = git_width,
        },
    },
})

require("neogit").setup({
    kind = "vsplit",
    graph_style = "unicode",
    integrations = {
        diffview = true,
        snacks = true,
    },
    status = {
        recent_commit_count = 5,
        HEAD_padding = 8,
        mode_padding = 1,
    },
    preview_buffer = { kind = "floating_console" },
    popup = { kind = "floating", show_title = true },
    mappings = {
        status = {
            ["q"] = "Close",
            ["<C-q>"] = "Close",
            ["<C-j>"] = false,
            ["<C-k>"] = false,
            ["<C-t>"] = focus_terminal,
        },
        finder = {
            ["q"] = "Close",
            ["<C-q>"] = "Close",
            ["<C-j>"] = false,
            ["<C-k>"] = false,
        },
        commit_editor = {
            ["q"] = "Close",
            ["<C-q>"] = "Close",
        },
        rebase_editor = {
            ["q"] = "Close",
            ["<C-q>"] = "Close",
        },
    },
})

local function git_window()
    return find_window("NeogitStatus")
end

local function lock_git_width(buf)
    local win = vim.fn.bufwinid(buf)
    if win == -1 then return end
    vim.wo[win].winfixwidth = true
    vim.wo[win].winhighlight = "WinSeparator:NvimTreeWinSeparator"
    if vim.api.nvim_win_get_width(win) ~= git_width then
        vim.api.nvim_win_set_width(win, git_width)
    end
end

local function close_git_panel(win)
    local root = require("workspace").get()
    local ok, status = pcall(function()
        return require("neogit.buffers.status").instance(root)
    end)
    if ok and status then
        status:close()
    elseif window_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
end

local closing_git_windows = false

local function close_all_git_windows()
    if closing_git_windows then return end
    closing_git_windows = true

    -- Dispose every Diffview tab, not only whichever one is currently focused.
    pcall(function()
        local lib = require("diffview.lib")
        for index = #lib.views, 1, -1 do
            local view = lib.views[index]
            pcall(view.close, view)
            lib.dispose_view(view)
        end
    end)

    -- Close Neogit's globally tracked overlays before the status sidebar.
    for _, module_name in ipairs({
        "neogit.lib.popup",
        "neogit.buffers.commit_view",
        "neogit.buffers.git_command_history",
        "neogit.buffers.log_view",
        "neogit.buffers.reflog_view",
        "neogit.buffers.refs_view",
        "neogit.buffers.commit_select_view",
    }) do
        pcall(function()
            local module = require(module_name)
            if module.instance and module.instance.close then
                module.instance:close()
            end
        end)
    end

    local status_win = git_window()
    if status_win then close_git_panel(status_win) end

    -- Neogit closes windows on the scheduler. Sweep any untracked auxiliary
    -- buffers after those safe plugin callbacks have run.
    vim.schedule(function()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.bo[buf].filetype:match("^Neogit") then
                pcall(vim.api.nvim_win_close, win, true)
            end
        end
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype:match("^Neogit") then
                pcall(vim.api.nvim_buf_delete, buf, { force = true })
            end
        end
        focus_editor()
        closing_git_windows = false
    end)
end

vim.api.nvim_create_user_command("GitCloseAll", close_all_git_windows, {
    desc = "Close every Neogit and Diffview window",
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    pattern = { "Neogit*", "COMMIT_EDITMSG", "git-rebase-todo" },
    callback = function(args)
        vim.schedule(function()
            if not vim.api.nvim_buf_is_valid(args.buf) or vim.b[args.buf].git_close_all_wrapped then return end

            local filetype = vim.bo[args.buf].filetype
            local name = vim.api.nvim_buf_get_name(args.buf)
            if filetype == "NeogitHelpPopup" then return end

            if not filetype:match("^Neogit")
                and not (name:find("/%.git/") and (filetype == "gitcommit" or filetype == "gitrebase"))
            then
                return
            end

            local plugin_close
            for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(args.buf, "n")) do
                if mapping.lhs == "q" then
                    plugin_close = mapping.callback
                    break
                end
            end

            local function close_git_stack()
                if plugin_close then pcall(plugin_close) end
                vim.schedule(close_all_git_windows)
            end

            vim.keymap.set("n", "q", close_git_stack, {
                buffer = args.buf,
                silent = true,
                desc = "Close all Git windows",
            })
            vim.keymap.set("n", "<C-q>", close_git_stack, {
                buffer = args.buf,
                silent = true,
                desc = "Close all Git windows",
            })
            vim.b[args.buf].git_close_all_wrapped = true
        end)
    end,
    desc = "Use one quit action for the Git UI stack except its help popup",
})

local function toggle_git_panel()
    local win = git_window()
    if win then
        if vim.api.nvim_get_current_win() == win then
            close_all_git_windows()
        else
            last_panel_win = win
            vim.api.nvim_set_current_win(win)
        end
        return
    end

    local workspace = require("workspace")
    local root = workspace.git_root()
    if not root then
        vim.notify("Workspace is not a Git repository: " .. workspace.get(), vim.log.levels.WARN)
        return
    end

    focus_editor()
    require("neogit").open({ kind = "vsplit", cwd = root })
    vim.schedule(function()
        local opened = git_window()
        if opened then
            last_panel_win = opened
            lock_git_width(vim.api.nvim_win_get_buf(opened))
        end
    end)
end

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    pattern = "NeogitStatus",
    callback = function(args)
        vim.schedule(function() lock_git_width(args.buf) end)
    end,
    desc = "Lock Source Control to the same width as the file explorer",
})

vim.api.nvim_create_autocmd("User", {
    pattern = "NeogitStatusRefreshed",
    callback = function()
        local win = git_window()
        if win then lock_git_width(vim.api.nvim_win_get_buf(win)) end
    end,
    desc = "Restore Source Control width after Git refreshes",
})

vim.api.nvim_create_user_command("GitPanel", toggle_git_panel, {
    desc = "Toggle the right Source Control panel",
})

vim.keymap.set({ "n", "t" }, "zgg", function()
    if vim.fn.mode() == "t" then vim.cmd("stopinsert") end
    toggle_git_panel()
end, {
    noremap = true,
    silent = true,
    desc = "Focus/toggle Source Control",
})
vim.keymap.set("n", "zgd", function()
    vim.cmd("DiffviewOpen")
end, { desc = "Git changed-file diff" })
vim.keymap.set("n", "zgh", function()
    vim.cmd("DiffviewFileHistory")
end, { desc = "Git repository history" })
vim.keymap.set("n", "zgc", function()
    require("neogit").open({ "commit", cwd = require("workspace").get() })
end, { desc = "Git commit" })


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

    hooks = {
        enter = {
            function()
                vim.g.leetcode_active = true
                tree_api.tree.close()
            end,
        },
        leave = {
            function()
                vim.g.leetcode_active = false
                vim.schedule(function()
                    tree_api.tree.open({ path = require("workspace").get(), focus = false })
                end)
            end,
        },
    },

    storage = {
        home = "~/Documents/Github/Leetcode",
        cache = vim.fn.stdpath("cache") .. "/leetcode",
    },
})



-- ============================================================
-- Misc Plugin Setup
-- ============================================================

require("ssh_launcher").setup()
require("grug-far").setup({
    -- options related to the target window for goto or open actions
    openTargetWindow = {
        -- filter for windows to exclude when considering candidate targets. It's a list of either:
        -- * filetype to exclude
        -- * filter function of the form: function(winid: number): boolean (return true to exclude)
        exclude = { "NvimTree", "floaterm", "NeogitStatus", "grug-far" },

        -- preferred location for target window relative to the grug-far window. If an existing candidate
        -- window that is not excluded by the exclude filter exists in that direction, it will be reused,
        -- otherwise a new window will be created in that direction.
        -- available options: "prev" | "left" | "right" | "above" | "below"
        preferredLocation = 'right',

        -- use a temporary scratch buffer, in order to prevent language servers starting up and
        -- consuming resources as you are moving through the results. The buffer is converted to
        -- a real buffer once you navigate to it explicitly
        useScratchBuffer = true,
    },
})

local search_instance_name = "workspace-right-search"
local restore_git_after_search = false

vim.api.nvim_create_user_command("GrugRightPanelSlot", function()
    local git = git_window()
    restore_git_after_search = git ~= nil
    if git then
        close_git_panel(git)
        -- Neogit schedules its window close. Vacate the shared sidebar now so
        -- Grug Far cannot briefly create a second right-hand panel.
        if vim.api.nvim_win_is_valid(git) then
            vim.api.nvim_win_close(git, true)
        end
    end

    focus_editor()
    vim.cmd("rightbelow " .. git_width .. "vsplit")
end, {
    desc = "Create the disposable right Search/Replace slot",
})

local function configure_search_panel(instance)
    local buf = instance:get_buf()
    local should_restore_git = restore_git_after_search
    restore_git_after_search = false
    local git_restore_requested = false

    local function restore_git()
        if not should_restore_git or git_restore_requested then return end
        git_restore_requested = true
        vim.schedule(function()
            if not git_window() then toggle_git_panel() end
        end)
    end

    local win = vim.fn.bufwinid(buf)
    if win ~= -1 then
        vim.wo[win].winfixwidth = true
        vim.wo[win].winhighlight = "WinSeparator:NvimTreeWinSeparator"
        vim.api.nvim_win_set_width(win, git_width)
        last_panel_win = win
    end

    local function close_search()
        if not instance:is_valid() then return end
        -- Closing while Grug Far is still doing its first scheduled render can
        -- leave queued search updates targeting a buffer that has been wiped.
        instance:when_ready(function()
            vim.schedule(function()
                if not instance:is_valid() then return end
                local context = instance._params.context
                require("grug-far.tasks").abortAndFinishAllTasks(context)
                context.state.bufClosed = true
                instance:close()
                restore_git()
            end)
        end)
    end
    vim.keymap.set("n", "q", close_search, {
        buffer = buf,
        silent = true,
        desc = "Close and wipe Search/Replace",
    })
    vim.keymap.set("n", "<C-c>", close_search, {
        buffer = buf,
        silent = true,
        desc = "Close and wipe Search/Replace",
    })

    vim.api.nvim_create_autocmd("BufWipeout", {
        buffer = buf,
        once = true,
        callback = restore_git,
        desc = "Restore Source Control after transient Search/Replace",
    })
end

local function open_search_panel(opts, visual)
    local grug = require("grug-far")
    if grug.has_instance(search_instance_name) then
        local instance = grug.get_instance(search_instance_name)
        if instance and instance:is_valid() then
            instance:open()
            return
        end
        require("grug-far.instances").remove_instance(search_instance_name)
    end

    opts = vim.tbl_deep_extend("force", opts or {}, {
        transient = true,
        instanceName = search_instance_name,
        windowCreationCommand = "GrugRightPanelSlot",
    })
    local instance = visual and grug.with_visual_selection(opts) or grug.open(opts)
    configure_search_panel(instance)
end

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    pattern = "grug-far",
    callback = function(args)
        vim.schedule(function()
            local win = vim.fn.bufwinid(args.buf)
            if win ~= -1 then
                vim.wo[win].winfixwidth = true
                vim.api.nvim_win_set_width(win, git_width)
            end
        end)
    end,
    desc = "Keep Search/Replace in the fixed right sidebar slot",
})

vim.keymap.set("n", "<leader>s", function()
    open_search_panel({}, false)
end, { desc = "Search/Replace right panel" })

vim.keymap.set("n", "<leader>sw", function()
    open_search_panel({ prefills = { search = vim.fn.expand("<cword>") } }, false)
end, { desc = "Search current word in right panel" })

vim.keymap.set("v", "<leader>sw", function()
    open_search_panel({}, true)
end, { desc = "Search selection in right panel" })
