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

            OilNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
            OilNormalNC = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
            OilCursorLine = { bg = theme.ui.bg_p1 },
            OilSelectedFile = { fg = theme.ui.fg, bg = theme.ui.bg_p1, bold = true },
            OilSelectedFileSign = { fg = theme.ui.special, bg = theme.ui.bg_m1 },
            OilWinSeparator = { fg = theme.ui.bg_p2, bg = theme.ui.bg_m1 },
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
        -- The IDE frame opens this explicitly after Oil. Snacks' UIEnter
        -- auto-open happens too early and centers against the full screen.
        enabled = false,
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
            },
        },
        sections = {
            { section = "header" },
            { section = "keys",  gap = 1, padding = 1 },
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
                    ["<C-c>"] = { "cancel", mode = { "n", "i" } },
                    ["<C-q>"] = { "cancel", mode = { "n", "i" }, desc = "Close picker" },
                    ["<Esc>"] = { "focus_list", mode = { "n", "i" } },
                    ["q"] = { function() end, mode = "n", desc = "Use Ctrl-Q to close" },
                    ["<Space>l"] = { "flash", mode = { "n", "i" } },
                    ["s"] = { "flash" },
                },
            },
            list = {
                keys = {
                    ["<C-c>"] = "cancel",
                    ["<C-q>"] = { "cancel", desc = "Close picker" },
                    ["<Esc>"] = "focus_input",
                    ["q"] = { function() end, desc = "Use Ctrl-Q to close" },
                },
            },
            preview = {
                keys = {
                    ["<C-c>"] = "cancel",
                    ["<C-q>"] = { "cancel", desc = "Close picker" },
                    ["<Esc>"] = "focus_list",
                    ["q"] = { function() end, desc = "Use Ctrl-Q to close" },
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

-- The dashboard is the permanent empty editor zone. It is never a mapped exit
-- point; Ctrl-Q handles it as a safe no-op instead of terminating Neovim.
vim.api.nvim_create_autocmd("User", {
    pattern = "SnacksDashboardOpened",
    callback = function()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].filetype == "snacks_dashboard" then
            require("editor_filler").keep_single(buf)
            pcall(vim.keymap.del, "n", "q", { buffer = buf })
        end
    end,
    desc = "Keep the dashboard as the editor-area filler",
})


-- ============================================================
-- Oil File Explorer Sidebar
-- ============================================================

local oil = require("oil")
local ide_layout = require("ide_layout")
local explorer_width = 30
local last_editor_win = nil
local last_panel_win = nil
local oil_focus_generation = 0

local function leetcode_active()
    return vim.g.leetcode_active == true
end

local function window_is_valid(win)
    return win and vim.api.nvim_win_is_valid(win)
end

local function window_filetype(win)
    return window_is_valid(win) and vim.bo[vim.api.nvim_win_get_buf(win)].filetype or ""
end

-- A terminal that is not one of ours belongs to another plugin's session
-- (ssh-launcher opens one per tab via jobstart({term=true})). Reshaping the
-- windows around it while it is still connecting can tear the session down, so
-- this frame's rules simply do not apply to such a tab.
local function has_foreign_terminal()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" and vim.bo[buf].filetype ~= "floaterm" then
            return true
        end
    end
    return false
end

local function is_panel(win)
    return ide_layout.is_panel_window(win)
end

local function find_window(filetype)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if window_filetype(win) == filetype then
            return win
        end
    end
end

local function find_editor_window()
    if window_is_valid(last_editor_win)
        and vim.api.nvim_win_get_tabpage(last_editor_win) == vim.api.nvim_get_current_tabpage()
        and not is_panel(last_editor_win)
    then
        return last_editor_win
    end
    return ide_layout.find_editor_window()
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
    require("buffers").cycle(direction)
end

local function focus_terminal()
    oil_focus_generation = oil_focus_generation + 1
    ide_layout.note_explicit_focus()
    local current = vim.api.nvim_get_current_win()
    if window_filetype(current) == "floaterm" then
        focus_editor()
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

local function oil_entry_path()
    local entry = oil.get_cursor_entry()
    local directory = oil.get_current_dir()
    if not entry or not directory then return nil, nil end
    return vim.fs.joinpath(directory, entry.name), entry
end

-- Directories continue navigating inside the sidebar. Files deliberately open
-- in the editor zone so Oil itself is never replaced by a selected file.
local function select_oil_entry(kind)
    local path, entry = oil_entry_path()
    if not path then return end
    if entry.type == "directory" then
        oil.select()
        return
    end

    focus_editor()
    if kind == "vertical" then
        vim.cmd("vsplit " .. vim.fn.fnameescape(path))
    elseif kind == "horizontal" then
        vim.cmd("split " .. vim.fn.fnameescape(path))
    elseif kind == "tab" then
        vim.cmd("tabedit " .. vim.fn.fnameescape(path))
    else
        vim.cmd("edit " .. vim.fn.fnameescape(path))
    end
end

-- Prefer the window explicitly marked as the sidebar; a stray oil buffer that
-- landed in an editor window must never be mistaken for the real explorer.
local function find_oil_sidebar()
    return ide_layout.find_sidebar()
end

local function close_oil_sidebar()
    local win = find_oil_sidebar()
    -- Hide only. bufhidden=hide plus cleanup_delay_ms=false keeps the buffer
    -- (and its filesystem watcher) alive, so reopening is a re-display rather
    -- than a rebuild.
    if win then vim.api.nvim_win_close(win, true) end
end

oil.setup({
    default_file_explorer = true,
    watch_for_changes = true,
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    columns = { "icon" },
    use_default_keymaps = false,
    -- The sidebar is a persistent IDE panel: hiding it must never destroy it.
    -- Oil's default (2000ms) deletes every hidden oil buffer once none are
    -- displayed — which is exactly the moment the sidebar is hidden — so the
    -- explorer was being torn down and rebuilt from scratch on every toggle.
    cleanup_delay_ms = false,
    view_options = {
        show_hidden = true,
        natural_order = true,
        sort = {
            { "type", "asc" },
            { "name", "asc" },
        },
    },
    win_options = {
        number = false,
        relativenumber = false,
        cursorline = true,
        signcolumn = "yes:3",
        winfixwidth = true,
        winhighlight = "Normal:OilNormal,NormalNC:OilNormalNC,WinSeparator:OilWinSeparator",
    },
    keymaps = {
        ["g?"] = { "actions.show_help", mode = "n" },
        ["<CR>"] = function() select_oil_entry() end,
        ["zv"] = function() select_oil_entry("vertical") end,
        ["zh"] = function() select_oil_entry("horizontal") end,
        ["gT"] = function() select_oil_entry("tab") end,
        ["<C-t>"] = focus_terminal,
        ["<C-p>"] = "actions.preview",
        ["<C-c>"] = close_oil_sidebar,
        ["<C-q>"] = close_oil_sidebar,
        ["<Space>l"] = "actions.refresh",
        ["<BS>"] = { "actions.parent", mode = "n" },
        ["gr"] = { "actions.open_cwd", mode = "n" },
        ["gc"] = function()
            local path = oil_entry_path()
            if path then
                local directory = vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path)
                require("workspace").set(directory, { exact = true })
            end
        end,
        ["gd"] = function()
            local path = oil_entry_path()
            if path then vim.system({ "open", "-R", path }, { detach = true }) end
        end,
        ["go"] = function()
            local path = oil_entry_path()
            if path then vim.system({ "open", path }, { detach = true }) end
        end,
        ["gs"] = { "actions.change_sort", mode = "n" },
        ["gx"] = "actions.open_external",
        ["g."] = { "actions.toggle_hidden", mode = "n" },
        ["gt"] = { "actions.toggle_trash", mode = "n" },
        ["<Tab>"] = function() switch_editor_buffer(1) end,
        ["<S-Tab>"] = function() switch_editor_buffer(-1) end,
    },
})

require("oil-git-status").setup({
    show_ignored = true,
    -- The first column is the index (staged), the second is the working tree.
    -- These mirror the familiar NvimTree-style Git marks instead of raw
    -- porcelain letters.
    symbols = {
        index = {
            ["!"] = "◌",
            ["?"] = "★",
            ["A"] = "✓",
            ["C"] = "✓",
            ["D"] = "✓",
            ["M"] = "✓",
            ["R"] = "➜",
            ["T"] = "✓",
            ["U"] = "",
            [" "] = " ",
        },
        working_tree = {
            ["!"] = "◌",
            ["?"] = "★",
            ["A"] = "+",
            ["C"] = "≡",
            ["D"] = "",
            ["M"] = "✗",
            ["R"] = "➜",
            ["T"] = "≠",
            ["U"] = "",
            [" "] = " ",
        },
    },
})

local oil_follow_namespace = vim.api.nvim_create_namespace("OilFollowedEditorFile")

local function mark_oil_entry(win, filename)
    if not window_is_valid(win) then return end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype ~= "oil" then return end

    vim.api.nvim_buf_clear_namespace(buf, oil_follow_namespace, 0, -1)
    for line = 1, vim.api.nvim_buf_line_count(buf) do
        local entry = oil.get_entry_on_line(buf, line)
        if entry and entry.name == filename then
            vim.api.nvim_buf_set_extmark(buf, oil_follow_namespace, line - 1, 0, {
                line_hl_group = "OilSelectedFile",
                sign_text = "▎",
                sign_hl_group = "OilSelectedFileSign",
                priority = 150,
            })
            vim.api.nvim_win_set_cursor(win, { line, 0 })
            return
        end
    end
end

local function reveal_editor_file_in_oil(path)
    local sidebar = find_oil_sidebar()
    if not sidebar or path == "" or vim.fn.filereadable(path) ~= 1 then return end

    local directory = vim.fs.normalize(vim.fs.dirname(path))
    local filename = vim.fs.basename(path)
    local oil_buf = vim.api.nvim_win_get_buf(sidebar)
    local current_directory = oil.get_current_dir(oil_buf)

    if current_directory and vim.fs.normalize(current_directory) == directory then
        mark_oil_entry(sidebar, filename)
        return
    end

    vim.api.nvim_win_call(sidebar, function()
        oil.open(directory, nil, function()
            vim.schedule(function() mark_oil_entry(sidebar, filename) end)
        end)
    end)
end

local function open_oil_sidebar(opts)
    opts = opts or {}
    if opts.focus then
        oil_focus_generation = oil_focus_generation + 1
        ide_layout.note_explicit_focus()
    end
    local return_focus_generation = oil_focus_generation
    if leetcode_active() then
        close_oil_sidebar()
        if opts.focus then vim.notify("Oil is disabled in LeetCode", vim.log.levels.INFO) end
        return
    end

    local current = vim.api.nvim_get_current_win()
    local existing = find_oil_sidebar()
    if existing then
        ide_layout.claim_panel("oil", existing)
        if opts.focus then
            last_editor_win = not is_panel(current) and current or last_editor_win
            last_panel_win = existing
            vim.api.nvim_set_current_win(existing)
        end
        if opts.after_open then opts.after_open(existing) end
        return existing
    end

    if not focus_editor() then
        local editor = ide_layout.ensure_editor_window()
        if editor then vim.api.nvim_set_current_win(editor) end
    end
    local editor_buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_name(editor_buf) == ""
        and vim.bo[editor_buf].buftype == ""
        and not vim.bo[editor_buf].modified
    then
        -- Keep the editor side alive without opening the dashboard before Oil.
        ide_layout.placeholder(vim.api.nvim_get_current_win())
    end
    vim.cmd("topleft " .. explorer_width .. "vsplit")
    local sidebar = vim.api.nvim_get_current_win()
    -- Marked before oil.open so the singleton guard below can tell this
    -- window apart from a stray oil buffer the moment BufWinEnter fires;
    -- oil's callback runs too late to claim ownership in time.
    ide_layout.claim_panel("oil", sidebar)
    oil.open(require("workspace").get(), nil, function()
        if not window_is_valid(sidebar) then return end
        ide_layout.mark_panel("oil", sidebar, vim.api.nvim_win_get_buf(sidebar))
        vim.wo[sidebar].winfixwidth = true
        vim.api.nvim_win_set_width(sidebar, explorer_width)
        local editor = find_editor_window()
        if editor then
            reveal_editor_file_in_oil(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(editor)))
        end
        vim.api.nvim_exec_autocmds("User", {
            pattern = "IdeOilSidebarReady",
            modeline = false,
            data = { win = sidebar },
        })
        -- Oil finalizes its own window setup after this callback returns, so
        -- reclaiming focus has to happen on the next tick to actually stick.
        if not opts.focus then
            vim.schedule(function()
                if return_focus_generation == oil_focus_generation then focus_editor() end
            end)
        end
        if opts.after_open then opts.after_open(sidebar) end
    end)
    last_panel_win = sidebar
    return sidebar
end

ide_layout.register_sidebar_opener(open_oil_sidebar)

local function focus_tree()
    local current = vim.api.nvim_get_current_win()
    if window_filetype(current) == "oil" then
        focus_editor()
        return
    end
    open_oil_sidebar({ focus = true })
end

-- Exactly one explorer instance: oil may only ever live in the sidebar window.
-- Anything that drops an oil buffer into an editor window instead -- the netrw
-- hijack on `:edit <dir>`, a plugin calling oil.open(), a stray split -- would
-- otherwise become a second, unmanaged explorer sitting next to the real one.
-- Such a window is evicted and its directory surfaced in the one true sidebar.
--
-- This scans window state rather than trusting the triggering event's buffer:
-- oil swaps in a scratch buffer while BufWinEnter fires, so the event's `buf`
-- and the window's actual buffer disagree mid-flight.
local oil_guard_busy = false

local function enforce_single_oil()
    if oil_guard_busy or leetcode_active() then return end

    local sidebar, strays = nil, {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if window_filetype(win) == "oil"
            and vim.api.nvim_win_get_config(win).relative == ""
            and not vim.wo[win].previewwindow
        then
            if vim.w[win].oil_sidebar and not sidebar then
                sidebar = win
            else
                strays[#strays + 1] = win
            end
        end
    end
    if #strays == 0 then return end

    oil_guard_busy = true
    local directory
    for _, win in ipairs(strays) do
        local buf = vim.api.nvim_win_get_buf(win)
        directory = directory or oil.get_current_dir(buf)
        local previous = vim.fn.bufnr("#")
        if previous > 0
            and previous ~= buf
            and vim.api.nvim_buf_is_valid(previous)
            and vim.bo[previous].filetype ~= "oil"
        then
            vim.api.nvim_win_set_buf(win, previous)
        else
            ide_layout.placeholder(win)
        end
    end
    oil_guard_busy = false

    -- Honour the intent: show the requested directory in the real explorer.
    local target = sidebar or open_oil_sidebar({ focus = false })
    if directory and target and window_is_valid(target) then
        vim.api.nvim_win_call(target, function() oil.open(directory) end)
    end
end

local oil_guard_pending = false
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "WinEnter" }, {
    group = vim.api.nvim_create_augroup("OilSingleton", { clear = true }),
    callback = function()
        -- These events fire in bursts (oil alone emits several per open);
        -- coalesce them into one check per tick.
        if oil_guard_pending then return end
        oil_guard_pending = true
        vim.schedule(function()
            oil_guard_pending = false
            enforce_single_oil()
        end)
    end,
    desc = "Keep Oil to a single sidebar instance",
})

-- Keep the explorer at a compact IDE-sidebar width. winfixwidth prevents
-- editor splits and equalize commands from stretching it.
vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, {
    pattern = "oil",
    callback = function(args)
        local win = vim.fn.bufwinid(args.buf)
        if win == -1 then
            return
        end

        if vim.w[win].oil_sidebar then
            ide_layout.mark_panel("oil", win, args.buf)
        end
        vim.wo[win].winfixwidth = true
        if vim.w[win].oil_sidebar and vim.api.nvim_win_get_width(win) ~= explorer_width then
            vim.api.nvim_win_set_width(win, explorer_width)
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
    desc = "Open/focus File Explorer",
})

local function fill_empty_editor_after_oil(focus)
    local editor = find_editor_window()
    if not editor then return end
    local buf = vim.api.nvim_win_get_buf(editor)
    if vim.b[buf].ide_layout_placeholder
        or (vim.api.nvim_buf_get_name(buf) == ""
            and vim.bo[buf].buftype == ""
            and not vim.bo[buf].modified)
    then
        ide_layout.open_filler({ win = editor, ensure_sidebar = false, focus = focus })
    end
end

local function open_ide_frame()
    local focus_token = ide_layout.focus_token()
    local focus_editor = not ide_layout.is_protected_window(vim.api.nvim_get_current_win())
    open_oil_sidebar({
        focus = false,
        after_open = function()
            vim.schedule(function()
                fill_empty_editor_after_oil(
                    focus_editor and ide_layout.focus_unchanged(focus_token)
                )
            end)
        end,
    })
end

-- Keep the project explorer present like an IDE sidebar. Oil is created first;
-- only then may the dashboard occupy the editor zone beside it.
vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
        vim.defer_fn(open_ide_frame, 10)
    end,
    desc = "Open the persistent project explorer sidebar",
})

vim.api.nvim_create_autocmd("TabNewEntered", {
    group = vim.api.nvim_create_augroup("OilTabSidebar", { clear = true }),
    callback = function()
        vim.schedule(function()
            -- A tab opened for someone else's terminal session is theirs.
            if has_foreign_terminal() then return end
            open_ide_frame()
        end)
    end,
    desc = "Keep the Oil sidebar present in new tabs",
})

vim.api.nvim_create_user_command("OilSidebarOpen", function()
    open_oil_sidebar({ focus = false })
end, { desc = "Open the persistent Oil sidebar" })

vim.api.nvim_create_user_command("LayoutDashboard", function()
    ide_layout.open_filler({ win = find_editor_window() })
end, { desc = "Open Oil first, then the dashboard in the editor zone" })

vim.api.nvim_create_autocmd("BufEnter", {
    callback = function(args)
        if not vim.api.nvim_buf_is_valid(args.buf)
            or vim.bo[args.buf].buftype ~= ""
            or vim.bo[args.buf].filetype == "oil"
        then
            return
        end

        local path = vim.api.nvim_buf_get_name(args.buf)
        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(args.buf)
                and vim.api.nvim_get_current_buf() == args.buf
            then
                reveal_editor_file_in_oil(path)
            end
        end)
    end,
    desc = "Reveal and mark the active editor file in Oil",
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
-- Project contexts keep their own live terminal rows in separate tabpages.
-- Hiding an existing bottom-position terminal when another project opens one
-- would destroy the first project's pane layout, even though its job survives.
vim.g.floaterm_autohide = 0
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
    oil_focus_generation = oil_focus_generation + 1
    ide_layout.note_explicit_focus()
    focus_editor()
    vim.cmd("FloatermNew --cwd=" .. vim.fn.fnameescape(require("workspace").get()))
end

-- Splits the bottom panel itself in half rather than carving a full-height
-- column out of the editor. floaterm's vsplit runs a plain `:vsplit` against
-- the *current* window, so focusing the panel first keeps the new terminal
-- inside the bottom strip.
-- Terminal windows sharing the bottom row, left to right.
local function terminal_row_windows()
    local wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if window_filetype(win) == "floaterm" and vim.api.nvim_win_get_config(win).relative == "" then
            wins[#wins + 1] = win
        end
    end
    table.sort(wins, function(a, b)
        return vim.api.nvim_win_get_position(a)[2] < vim.api.nvim_win_get_position(b)[2]
    end)
    return wins
end

-- A terminal row is only in its fixed panel position when every terminal has
-- the same top edge and every other normal window ends above it.
-- Checking geometry keeps the guard independent of whatever split tree a
-- plugin or an editor command happened to create.
local function terminal_row_is_bottom(wins)
    if #wins == 0 then return true end

    local terminal_set = {}
    local top
    local bottom
    for _, win in ipairs(wins) do
        terminal_set[win] = true
        local position = vim.api.nvim_win_get_position(win)
        local edge = position[1] + vim.api.nvim_win_get_height(win)
        if top and (position[1] ~= top or edge ~= bottom) then return false end
        top = position[1]
        bottom = edge
    end

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if not terminal_set[win]
            and vim.api.nvim_win_get_config(win).relative == ""
        then
            local position = vim.api.nvim_win_get_position(win)
            if position[1] + vim.api.nvim_win_get_height(win) > top then
                return false
            end
        end
    end

    return true
end

-- Rebuild only the terminal portion of the frame. Moving one terminal to the
-- bottom establishes the horizontal boundary; the remaining terminals are
-- then moved beside it to recover the shared row without disturbing editor
-- splits above it.
local function move_terminal_row_to_bottom(wins)
    if #wins == 0 then return end

    local focused = vim.api.nvim_get_current_win()
    for _, win in ipairs(wins) do
        vim.wo[win].winfixheight = false
    end

    vim.api.nvim_win_call(wins[1], function() vim.cmd("wincmd J") end)
    local previous = wins[1]
    for index = 2, #wins do
        vim.fn.win_splitmove(wins[index], previous, {
            vertical = true,
            rightbelow = true,
        })
        previous = wins[index]
    end

    if vim.api.nvim_win_is_valid(focused) then
        vim.api.nvim_set_current_win(focused)
    end
end

-- floaterm sizes a vsplit from g:floaterm_width, which leaves lopsided halves;
-- share the panel's width evenly instead.
local function balance_terminal_row()
    local wins = terminal_row_windows()
    if #wins < 2 then return end

    local total = 0
    for _, win in ipairs(wins) do
        total = total + vim.api.nvim_win_get_width(win)
    end
    total = total + (#wins - 1) -- separators reclaimed by the split itself

    local share = math.floor(total / #wins)
    for index = 1, #wins - 1 do
        if vim.api.nvim_win_get_width(wins[index]) ~= share then
            pcall(vim.api.nvim_win_set_width, wins[index], share)
        end
    end
end

-- The panel must only ever redistribute its own width. Anything that asks for
-- more than the panel has makes Vim reclaim the difference from its neighbours
-- -- in practice crushing the fixed-width explorer down to a single column.
local function restore_sidebar_width()
    local sidebar = find_oil_sidebar()
    if sidebar
        and vim.api.nvim_win_is_valid(sidebar)
        and vim.api.nvim_win_get_width(sidebar) ~= explorer_width
    then
        pcall(vim.api.nvim_win_set_width, sidebar, explorer_width)
    end
end

local function split_terminal()
    local terminal = find_window("floaterm")
    if not terminal then
        new_terminal()
        return
    end

    vim.api.nvim_set_current_win(terminal)
    -- Without an explicit width floaterm sizes the new window from
    -- g:floaterm_width (a fraction of the whole screen), which does not fit
    -- inside the panel and steals the shortfall from the sidebar.
    local half = math.max(10, math.floor(vim.api.nvim_win_get_width(terminal) / 2))
    vim.cmd(string.format(
        "FloatermNew --wintype=vsplit --position=rightbelow --width=%d --cwd=%s",
        half,
        vim.fn.fnameescape(require("workspace").get())
    ))
    vim.schedule(function()
        balance_terminal_row()
        restore_sidebar_width()
    end)
end

local function terminal_picker()
    require("terminals").pick()
end

-- Every terminal belongs to the bottom panel, including the halves created by
-- split_terminal: they share the panel's height and stay pinned to it.
vim.api.nvim_create_autocmd("FileType", {
    pattern = "floaterm",
    callback = function()
        ide_layout.mark_panel("terminal", vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf())
        vim.b.floaterm_workspace = vim.b.floaterm_workspace or require("workspace").get()
        local opts = {
            noremap = true,
            silent = true,
            buffer = true,
        }

        vim.wo.winhighlight = "WinSeparator:OilWinSeparator"
        vim.wo.winfixheight = true
        -- Height is pinned, width is not: the halves of a split panel have to
        -- be able to give width to each other, and an inherited winfixwidth
        -- silently defeats balancing them.
        vim.wo.winfixwidth = false
        vim.b.floaterm_position = "belowright"
        terminal_height = math.min(terminal_height, math.max(5, vim.o.lines - 6))
        vim.api.nvim_win_set_height(0, terminal_height)

        vim.keymap.set({ "n", "t" }, "<C-Up>", function() resize_terminal(3) end, opts)
        vim.keymap.set({ "n", "t" }, "<C-Down>", function() resize_terminal(-3) end, opts)
        vim.keymap.set("n", "i", function()
            require("terminals").edit({
                cursor = vim.api.nvim_win_get_cursor(0),
                startinsert = true,
            })
        end, vim.tbl_extend("force", opts, {
            desc = "Edit terminal output from the cursor",
        }))
        vim.keymap.set("n", "<leader>e", function() require("terminals").edit() end,
            vim.tbl_extend("force", opts, { desc = "Edit this terminal's output" }))
    end,
})

-- Terminal-mode mappings must never be bare letters: a `t` mapping for "zp"
-- swallows those keystrokes before the shell sees them, so they could not be
-- typed at a prompt. Letter mappings stay in normal/visual mode only, and
-- terminal mode gets Ctrl-chords alongside <C-Up>/<C-Down> for resizing.
local function cycle_terminal(direction)
    return function()
        -- Switching windows is not allowed from terminal mode; drop out first
        -- and defer, then focus() puts the target terminal back into insert.
        if vim.fn.mode() == "t" then vim.cmd("stopinsert") end
        vim.schedule(function() require("terminals").cycle(direction) end)
    end
end

vim.keymap.set({ "n", "v" }, "zp", cycle_terminal(-1),
    { noremap = true, silent = true, desc = "Focus the previous terminal" })
vim.keymap.set({ "n", "v" }, "zn", cycle_terminal(1),
    { noremap = true, silent = true, desc = "Focus the next terminal" })

vim.keymap.set({ "n", "t" }, "<C-Left>", cycle_terminal(-1),
    { noremap = true, silent = true, desc = "Focus the previous terminal" })
vim.keymap.set({ "n", "t" }, "<C-Right>", cycle_terminal(1),
    { noremap = true, silent = true, desc = "Focus the next terminal" })

vim.keymap.set({ "n", "v", "i" }, "<C-t>", focus_terminal, {
    noremap = true,
    silent = true,
    desc = "Open/focus bottom terminal",
})

-- Every terminal action has a terminal-mode chord, so managing terminals never
-- requires leaving insert/terminal mode first. The actions themselves run
-- window commands, which are illegal from terminal mode, so each one drops to
-- normal mode and defers -- Neovim refuses to re-enter normal mode from within
-- a terminal-mode mapping's own callback.
local function from_terminal(action)
    return function()
        if vim.fn.mode() == "t" then vim.cmd("stopinsert") end
        vim.schedule(action)
    end
end

-- <C-v> is deliberately not used here: mappings.lua already owns it as "exit
-- terminal mode". <C-s> shadows XON flow control, which is inert in a modern
-- shell -- the same trade this config already makes for <C-w>/<C-h>.
vim.keymap.set("t", "<C-s>", from_terminal(split_terminal),
    { noremap = true, silent = true, desc = "Split the bottom terminal panel in half" })
-- Terminal buffers are read-only, so "edit this output" means editing a copy.
-- <C-g> works directly from terminal mode. Once <C-v> has entered
-- terminal-normal mode, jumping to text and pressing i opens an editable copy
-- at that exact cursor position; a still returns to the live shell.
vim.keymap.set("t", "<C-g>", from_terminal(function() require("terminals").edit() end),
    { noremap = true, silent = true, desc = "Edit terminal output in a scratch buffer" })

-- One "make me a new thing" key: whatever you are looking at decides what gets
-- created. In a terminal it is another terminal; anywhere else it is a new
-- file in the editor zone (never in the explorer or the terminal panel).
local function new_file_or_terminal()
    if window_filetype(vim.api.nvim_get_current_win()) == "floaterm" then
        new_terminal()
        return
    end

    focus_editor()
    vim.cmd("enew")
    vim.cmd("startinsert")
end

vim.keymap.set({ "n", "v", "i" }, "<C-a>", function()
    if vim.fn.mode():sub(1, 1) ~= "n" then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end
    new_file_or_terminal()
end, { noremap = true, silent = true, desc = "New file (new terminal in a terminal)" })

vim.keymap.set("t", "<C-a>", from_terminal(new_terminal),
    { noremap = true, silent = true, desc = "Open another bottom terminal" })

vim.keymap.set("t", "<C-t>", function()
    vim.cmd("stopinsert")
    focus_terminal()
end, { silent = true, desc = "Return to the editor from the terminal" })

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
vim.api.nvim_create_user_command("FocusTree", focus_tree, { desc = "Open or focus the file explorer" })
vim.api.nvim_create_user_command("FocusTerminal", focus_terminal, { desc = "Open or focus the terminal" })
vim.api.nvim_create_user_command("TerminalNew", new_terminal, { desc = "Open another bottom terminal" })
vim.api.nvim_create_user_command("TerminalSplit", split_terminal,
    { desc = "Split the bottom terminal panel in half" })
vim.api.nvim_create_user_command("TerminalList", terminal_picker, { desc = "List and jump to an open terminal" })
vim.api.nvim_create_user_command("EditorTabNext", function()
    switch_editor_buffer(1)
end, { desc = "Open the next editor tab from any panel" })
vim.api.nvim_create_user_command("EditorTabPrevious", function()
    switch_editor_buffer(-1)
end, { desc = "Open the previous editor tab from any panel" })

-- ============================================================
-- Source Control
-- ============================================================

local git_width = explorer_width

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

local lazygit_buffers = {}

local function close_diffviews()
    pcall(function()
        local lib = require("diffview.lib")
        for index = #lib.views, 1, -1 do
            local view = lib.views[index]
            pcall(view.close, view)
            lib.dispose_view(view)
        end
    end)
end

local function remember_editor_before_lazygit(win, buf)
    vim.w[win].lazygit_previous_buf = buf
    vim.w[win].lazygit_previous_bufhidden = vim.bo[buf].bufhidden
    if vim.bo[buf].buftype == "" then vim.bo[buf].bufhidden = "hide" end
end

local function lazygit_editor_window()
    if focus_editor() then return vim.api.nvim_get_current_win() end

    -- Oil and the other panels are protected: LazyGit may only replace an
    -- editor buffer. Recreate the editor zone if this tab has only panels.
    return ide_layout.ensure_editor_window()
end

local function restore_editor_after_lazygit(buf)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if vim.api.nvim_win_is_valid(win) then
            local previous = vim.w[win].lazygit_previous_buf
            if previous
                and previous ~= buf
                and vim.api.nvim_buf_is_valid(previous)
            then
                vim.api.nvim_win_set_buf(win, previous)
                vim.bo[previous].bufhidden = vim.w[win].lazygit_previous_bufhidden or ""
            else
                ide_layout.open_filler({ win = win })
            end
            vim.w[win].lazygit_previous_buf = nil
            vim.w[win].lazygit_previous_bufhidden = nil
        end
    end
end

local function close_lazygit(buf)
    buf = buf or lazygit_buffers[require("workspace").get()]
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return end
    local project = vim.b[buf].lazygit_workspace
    restore_editor_after_lazygit(buf)
    local job = vim.b[buf].terminal_job_id
    if job then pcall(vim.fn.jobstop, job) end
    if vim.api.nvim_buf_is_valid(buf) then
        pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end
    if project and lazygit_buffers[project] == buf then lazygit_buffers[project] = nil end
end

local function open_lazygit()
    if vim.fn.executable("lazygit") ~= 1 then
        vim.notify("lazygit is not installed", vim.log.levels.ERROR)
        return
    end

    local workspace = require("workspace")
    local project = workspace.get()
    local lazygit_buf = lazygit_buffers[project]
    if lazygit_buf and not vim.api.nvim_buf_is_valid(lazygit_buf) then
        lazygit_buffers[project] = nil
        lazygit_buf = nil
    end

    if lazygit_buf then
        if vim.api.nvim_get_current_buf() == lazygit_buf then
            return
        else
            local win = lazygit_editor_window()
            local current = vim.api.nvim_get_current_buf()
            if current ~= lazygit_buf then remember_editor_before_lazygit(win, current) end
            vim.api.nvim_win_set_buf(win, lazygit_buf)
            vim.cmd("startinsert")
        end
        return
    end

    local root = workspace.git_root()
    if not root then
        vim.notify("Workspace is not a Git repository: " .. workspace.get(), vim.log.levels.WARN)
        return
    end

    local editor_win = lazygit_editor_window()
    remember_editor_before_lazygit(editor_win, vim.api.nvim_get_current_buf())
    lazygit_buf = vim.api.nvim_create_buf(true, false)
    lazygit_buffers[project] = lazygit_buf
    vim.api.nvim_win_set_buf(editor_win, lazygit_buf)
    local job = vim.fn.jobstart({ "lazygit" }, { term = true, cwd = root })
    if job <= 0 then
        local failed_buf = lazygit_buf
        restore_editor_after_lazygit(failed_buf)
        pcall(vim.api.nvim_buf_delete, failed_buf, { force = true })
        lazygit_buffers[project] = nil
        vim.notify("Could not start lazygit", vim.log.levels.ERROR)
        return
    end
    vim.bo[lazygit_buf].filetype = "lazygit"
    vim.bo[lazygit_buf].buflisted = true
    vim.bo[lazygit_buf].bufhidden = "hide"
    vim.b[lazygit_buf].lazygit_editor = true
    vim.b[lazygit_buf].lazygit_workspace = project
    pcall(vim.api.nvim_buf_set_name, lazygit_buf, "lazygit://" .. root)

    local created_buf = lazygit_buf
    vim.keymap.set({ "n", "t" }, "<C-q>", function() close_lazygit(created_buf) end, {
        buffer = lazygit_buf,
        silent = true,
        desc = "Close LazyGit editor buffer",
    })

    vim.api.nvim_create_autocmd("TermClose", {
        buffer = lazygit_buf,
        once = true,
        callback = function(args)
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(args.buf) then
                    restore_editor_after_lazygit(args.buf)
                    pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
                end
                if lazygit_buffers[project] == args.buf then lazygit_buffers[project] = nil end
            end)
        end,
        desc = "Restore the editor after LazyGit exits",
    })
    vim.api.nvim_create_autocmd("BufEnter", {
        buffer = lazygit_buf,
        callback = function(args)
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(args.buf)
                    and vim.api.nvim_get_current_buf() == args.buf
                then
                    vim.cmd("startinsert")
                end
            end)
        end,
        desc = "Enter terminal mode when revisiting the LazyGit buffer",
    })
    vim.cmd("startinsert")
end

local function close_all_git_windows()
    close_diffviews()
    close_lazygit(lazygit_buffers[require("workspace").get()])
end

vim.api.nvim_create_user_command("GitCloseAll", close_all_git_windows, {
    desc = "Close LazyGit and every Diffview window",
})

vim.api.nvim_create_user_command("GitPanel", open_lazygit, {
    desc = "Open or focus the LazyGit editor buffer",
})

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
                close_oil_sidebar()
            end,
        },
        leave = {
            function()
                vim.g.leetcode_active = false
                vim.schedule(function()
                    open_oil_sidebar({ focus = false })
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
require("rip-substitute").setup({
    popupWin = {
        border = "rounded",
        title = " Replace ",
        position = "bottom",
    },
    keymaps = {
        abort = "<C-c>",
    },
})

local quicker = require("quicker")

local function close_quicker_results()
    if not quicker.is_open() then return end

    -- Quickfix can temporarily become the last window during startup. Create
    -- a safe editor landing pane before closing it so Ctrl-Q never triggers
    -- E444 and never falls through to quitting Neovim.
    if #vim.api.nvim_tabpage_list_wins(0) == 1 then
        local editor = ide_layout.ensure_editor_window()
        ide_layout.open_filler({ win = editor })
    end
    quicker.close()
end

quicker.setup({
    edit = {
        enabled = true,
        autosave = "unmodified",
    },
    keys = {
        {
            ">",
            function()
                quicker.expand({ before = 2, after = 2, add_to_existing = true })
            end,
            desc = "Expand quickfix context",
        },
        {
            "<",
            function() quicker.collapse() end,
            desc = "Collapse quickfix context",
        },
    },
    on_qf = function(buf)
        vim.keymap.set("n", "q", "<Nop>", {
            buffer = buf,
            silent = true,
            desc = "Disabled: use Ctrl-Q to close",
        })
        vim.keymap.set("n", "<C-c>", close_quicker_results, {
            buffer = buf,
            silent = true,
            desc = "Close editable results",
        })
        vim.keymap.set("n", "<C-q>", close_quicker_results, {
            buffer = buf,
            silent = true,
            desc = "Close editable results",
        })
    end,
})

local function open_project_results(query)
    query = vim.trim(query or "")
    if query == "" then return end

    local root = require("workspace").get()
    vim.system({
        "rg",
        "--vimgrep",
        "--smart-case",
        "--hidden",
        "--glob",
        "!.git",
        query,
        ".",
    }, { cwd = root, text = true }, function(result)
        vim.schedule(function()
            if result.code == 1 then
                vim.notify("No matches for: " .. query, vim.log.levels.INFO)
                return
            end
            if result.code ~= 0 then
                local message = vim.trim(result.stderr or "")
                vim.notify(message ~= "" and message or "Project search failed", vim.log.levels.ERROR)
                return
            end

            vim.fn.setqflist({}, "r", {
                title = "Search: " .. query,
                lines = vim.split(result.stdout or "", "\n", { trimempty = true }),
                efm = "%f:%l:%c:%m",
            })
            if quicker.is_open() then
                quicker.refresh()
                local results_win = find_window("qf")
                if results_win then vim.api.nvim_set_current_win(results_win) end
            else
                quicker.open({ focus = true })
            end
        end)
    end)
end

vim.api.nvim_create_user_command("ProjectResults", function(opts)
    if opts.args ~= "" then
        open_project_results(opts.args)
        return
    end
    vim.ui.input({
        prompt = "Project search: ",
        default = vim.fn.expand("<cword>"),
    }, open_project_results)
end, {
    nargs = "*",
    desc = "Search the workspace into an editable quickfix buffer",
})

vim.keymap.set({ "n", "x" }, "<leader>s", function()
    require("rip-substitute").sub()
end, { desc = "Replace in buffer or selection" })

vim.keymap.set("n", "<leader>sq", "<cmd>ProjectResults<CR>", {
    silent = true,
    desc = "Search project into editable results",
})

vim.keymap.set("n", "<leader>st", function()
    if quicker.is_open() then
        local results_win = find_window("qf")
        if results_win then vim.api.nvim_set_current_win(results_win) end
    else
        quicker.open({ focus = true })
    end
end, {
    silent = true,
    desc = "Open/focus editable results",
})


-- ============================================================
-- Live Server
-- ============================================================

-- Every option has a working default, and root detection already falls back to
-- the editor cwd -- which workspace.setup() pins to the workspace root -- so
-- the project the server picks matches the one the rest of this config uses.
require("live_server").setup({})


-- ============================================================
-- Layout Invariant
--
-- The IDE frame has three rules that must hold no matter how a window was
-- closed: the explorer is the leftmost window at its fixed width, there is
-- always at least one editor window, and all visible terminals occupy one
-- fixed-height row beneath the editor zone. `wincmd =` and window/buffer close
-- paths can violate any of them, so this re-asserts the complete frame instead
-- of trying to catch every individual path that can break it.
-- ============================================================

local layout_guard_busy = false

local function enforce_layout()
    if layout_guard_busy or leetcode_active() or has_foreign_terminal() then return end
    layout_guard_busy = true

    local ok = pcall(function()
        local sidebar = find_oil_sidebar()

        -- An editor zone must exist for the sidebar to sit beside. Without one
        -- the sidebar is the only window and inherits the full width.
        if not find_editor_window() then
            local editor = ide_layout.ensure_editor_window()
            ide_layout.open_filler({ win = editor })
            sidebar = find_oil_sidebar()
        end

        local terminals = terminal_row_windows()
        if not terminal_row_is_bottom(terminals) then
            move_terminal_row_to_bottom(terminals)
        end

        if sidebar and vim.api.nvim_win_is_valid(sidebar) then
            -- Leftmost: anything that ended up left of it gets moved aside.
            if vim.api.nvim_win_get_position(sidebar)[2] ~= 0 then
                vim.api.nvim_win_call(sidebar, function() vim.cmd("wincmd H") end)
            end
            if vim.api.nvim_win_get_width(sidebar) ~= explorer_width then
                vim.api.nvim_win_set_width(sidebar, explorer_width)
            end
            vim.wo[sidebar].winfixwidth = true
        end

        -- Moving the sidebar or equalizing another split can resize the panel
        -- even when its topology is still correct. Re-pin its dimensions on
        -- every guard pass, then balance only the terminal row's width.
        local height = math.min(terminal_height, math.max(5, vim.o.lines - 6))
        for _, win in ipairs(terminals) do
            if vim.api.nvim_win_is_valid(win) then
                if vim.api.nvim_win_get_height(win) ~= height then
                    vim.api.nvim_win_set_height(win, height)
                end
                vim.wo[win].winfixheight = true
                vim.wo[win].winfixwidth = false
            end
        end
        balance_terminal_row()
    end)

    layout_guard_busy = false
    return ok
end

vim.api.nvim_create_user_command("LayoutEnforce", enforce_layout,
    { desc = "Re-assert the explorer, editor, and bottom terminal layout" })

vim.api.nvim_create_autocmd({ "WinClosed", "WinNew", "WinResized", "BufWinEnter", "TabEnter", "VimResized" }, {
    group = vim.api.nvim_create_augroup("LayoutInvariant", { clear = true }),
    callback = function() vim.schedule(enforce_layout) end,
    desc = "Hold the IDE layout invariant",
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = vim.api.nvim_create_augroup("EditorZoneRouting", { clear = true }),
    callback = function(args)
        ide_layout.remember_visible_panel_buffer(args.buf)
        ide_layout.route_editor_buffer(args.buf)
    end,
    desc = "Route non-panel buffers out of the Oil and terminal panels",
})
