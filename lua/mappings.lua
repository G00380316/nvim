-- ============================================================
-- Core Requires
-- ============================================================

local Snacks = require("snacks")


-- ============================================================
-- State
-- ============================================================

local sticky_active = false
local sticky_word = nil

-- ============================================================
-- General Helpers
-- ============================================================

local function has_lsp(bufnr)
    bufnr = bufnr or 0
    return #vim.lsp.get_clients({ bufnr = bufnr }) > 0
end

local function clear_search()
    vim.fn.setreg("/", "")
    vim.cmd("nohlsearch")

    sticky_active = false
    sticky_word = nil
end

local function open_in_file_manager()
    local file = vim.api.nvim_buf_get_name(0)

    if file == "" then
        print("No file associated with this buffer")
        return
    end

    local dir = vim.fn.fnamemodify(file, ":h")

    if vim.fn.has("mac") == 1 then
        vim.fn.jobstart({ "open", dir }, { detach = true })
    elseif vim.fn.has("win32") == 1 then
        vim.fn.jobstart({ "explorer", dir }, { detach = true })
    else
        vim.fn.jobstart({ "xdg-open", dir }, { detach = true })
    end
end


-- ============================================================
-- Sticky Search Helpers
-- n / N searches current word, but jumps pairs if on brackets/quotes.
-- ============================================================

local function build_search_pattern(word)
    local escaped = vim.fn.escape(word, "\\")
    return "\\c\\<" .. escaped .. "\\>"
end

local function jump_quote(direction, quote)
    local row, col0 = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.fn.getline(row)
    local col = col0 + 1

    if direction == "n" then
        local found = line:find(quote, col + 1, true)
        if found then
            vim.api.nvim_win_set_cursor(0, { row, found - 1 })
            return true
        end
    else
        local before = line:sub(1, col - 1)
        local last_pos = nil
        local start = 1

        while true do
            local found = before:find(quote, start, true)
            if not found then
                break
            end

            last_pos = found
            start = found + 1
        end

        if last_pos then
            vim.api.nvim_win_set_cursor(0, { row, last_pos - 1 })
            return true
        end
    end

    return false
end

local function visual_pair_jump(direction)
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local char = line:sub(col, col)

    -- Brackets
    if char:match("[%(%)%[%]%{%}]") then
        vim.cmd("normal! %")
        return true
    end

    -- Quotes
    if char == '"' or char == "'" then
        return jump_quote(direction, char)
    end

    return false
end

local function smart_search_and_jump(direction)
    local mode = vim.fn.mode()
    local is_visual = mode:match("[vV\22]") ~= nil

    -- In visual mode, only jump pairs.
    -- Do not restore old visual selection with gv.
    if is_visual then
        visual_pair_jump(direction)
        return
    end

    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local char = line:sub(col, col)

    if char:match("[%(%)%[%]%{%}]") then
        pcall(vim.cmd, "normal! %")
        return
    end

    if char == '"' or char == "'" then
        if jump_quote(direction, char) then
            return
        end
    end

    -- Sticky search fallback
    if not sticky_active then
        local word = vim.fn.expand("<cword>")
        if word == "" then
            print("No word under cursor to search")
            return
        end

        sticky_word = word
        sticky_active = true
        vim.fn.setreg("/", build_search_pattern(sticky_word))
    end

    if vim.fn.getreg("/") == "" then
        print("No active search pattern")
        return
    end

    pcall(vim.cmd, "normal! " .. direction)
end

-- ============================================================
-- Safe Paste Helpers
-- Keeps linewise pastes separated from surrounding text.
-- ============================================================

local function regtype_is_linewise(reg)
    local regtype = vim.fn.getregtype(reg or '"')
    return regtype:sub(1, 1) == "V"
end

local function line_is_blank(lnum)
    if lnum < 1 or lnum > vim.fn.line("$") then
        return true
    end

    return vim.fn.getline(lnum):match("^%s*$") ~= nil
end

local function ensure_blank_line_above(lnum)
    if lnum > 1 and not line_is_blank(lnum - 1) then
        vim.fn.append(lnum - 1, "")
    end
end

local function ensure_blank_line_below(lnum)
    if lnum < vim.fn.line("$") and not line_is_blank(lnum + 1) then
        vim.fn.append(lnum, "")
    end
end

local function safe_paste(direction)
    local mode = vim.fn.mode()
    local is_visual = mode:match("[vV\22]") ~= nil

    -- Exit visual mode AFTER capturing it
    if is_visual then
        vim.cmd("normal! \27")
    end

    local reg = vim.v.register
    if reg == "" then
        reg = '"'
    end

    -- =========================
    -- VISUAL MODE (replacement)
    -- =========================
    if is_visual then
        local start_line = vim.fn.line("'<")
        local end_line = vim.fn.line("'>")

        -- Grab yanked content BEFORE any deletion
        local yanked = vim.fn.getreg('0')
        local regtype = vim.fn.getregtype('0')

        ensure_blank_line_above(start_line)
        ensure_blank_line_below(end_line)

        -- Delete selection, restore register, paste
        vim.cmd('normal! gv"_d')
        vim.fn.setreg('"', yanked, regtype)
        vim.cmd('normal! P')

        local last_pasted = vim.fn.line("']")
        ensure_blank_line_below(last_pasted)
        return
    end

    -- Character-wise paste in normal mode → leave untouched
    if not regtype_is_linewise(reg) then
        vim.cmd("normal! " .. direction)
        return
    end

    -- =========================
    -- NORMAL MODE
    -- =========================
    local current_line = vim.fn.line(".")
    if direction == "p" then
        ensure_blank_line_below(current_line)
        vim.cmd("normal! p")
        local last_pasted = vim.fn.line("']")
        ensure_blank_line_below(last_pasted)
    else
        ensure_blank_line_above(current_line)
        vim.cmd("normal! P")
        local last_pasted = vim.fn.line("']")
        ensure_blank_line_below(last_pasted)
    end
end
-- ============================================================
-- Save / Quit Helpers
-- ============================================================

local function save_current_file()
    local bufnr = vim.api.nvim_get_current_buf()
    local mode = vim.api.nvim_get_mode().mode

    -- Leave insert/visual mode cleanly.
    if mode:sub(1, 1) == "i" then
        vim.cmd("stopinsert")
    elseif mode:sub(1, 1) == "v" or mode == "V" or mode == "\22" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>", true, false, true),
            "nx",
            false
        )
    end

    local function write_buffer()
        if vim.bo[bufnr].filetype ~= "oil" and has_lsp(bufnr) then
            pcall(vim.lsp.buf.format, { async = false })
        end

        local ok, err = pcall(vim.cmd, "write")
        if not ok then
            vim.notify(err, vim.log.levels.ERROR)
            return
        end

        clear_search()
    end

    local name = vim.api.nvim_buf_get_name(bufnr)

    -- Save unnamed buffer by asking for a path.
    if name == "" then
        local cwd = vim.fn.getcwd()
        local default_path = cwd .. "/"

        local ok, filepath = pcall(vim.fn.input, "Save as: ", default_path, "file")
        if not ok or not filepath or filepath == "" then
            return
        end

        filepath = vim.fn.fnamemodify(filepath, ":p")

        local dir = vim.fn.fnamemodify(filepath, ":h")
        if vim.fn.isdirectory(dir) == 0 then
            vim.fn.mkdir(dir, "p")
        end

        local save_ok, save_err = pcall(vim.cmd, "saveas " .. vim.fn.fnameescape(filepath))
        if not save_ok then
            vim.notify(save_err, vim.log.levels.ERROR)
            return
        end

        clear_search()
        return
    end

    write_buffer()
end

local function next_editor_buffer(current)
    return require("buffers").replacement(current)
end

local function close_editor_buffer(buf, preferred_replacement)
    local win = vim.api.nvim_get_current_win()
    local replacement = preferred_replacement
    if not (replacement
            and replacement ~= buf
            and vim.api.nvim_buf_is_valid(replacement))
    then
        replacement = next_editor_buffer(buf)
    end

    -- Keep the editor zone alive between the fixed tree and terminal panels.
    -- :bdelete on the displayed buffer would otherwise remove its window.
    if replacement then
        vim.api.nvim_win_set_buf(win, replacement)
    else
        require("ide_layout").open_filler({ win = win })
    end

    local success = pcall(vim.cmd, "confirm bdelete " .. buf)
    if not success or (vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted) then
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_win_set_buf(win, buf)
        end
        return false
    end
    return true
end

local function protect_terminal_tab_before_close()
    local current = vim.api.nvim_get_current_win()
    if vim.api.nvim_win_get_config(current).relative ~= "" then return end

    local normal_windows = vim.tbl_filter(function(win)
        return vim.api.nvim_win_get_config(win).relative == ""
    end, vim.api.nvim_tabpage_list_wins(0))
    if #normal_windows > 1 then return end

    -- Floaterm closes its own window while its buffer/job is being deleted.
    -- If that is the tab's sole window, Neovim closes the whole tab (and the
    -- last tab can look like, or become, an application quit). Give it an
    -- editor landing window first so Ctrl-Q can only remove the terminal.
    local editor = require("ide_layout").ensure_editor_window()
    require("ide_layout").open_filler({ win = editor })
end

local function close_current()
    local buf = vim.api.nvim_get_current_buf()
    local buftype = vim.bo[buf].buftype
    local filetype = vim.bo[buf].filetype
    local mode = vim.fn.mode()
    local was_typing = mode == "t"

    -- Leave modal editing states before changing buffers or windows.
    if mode == "t" then
        vim.cmd("stopinsert")
    elseif mode == "i" then
        vim.cmd("stopinsert")
    elseif mode:match("[vV\22]") then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end

    -- Closing the dashboard used to call :qa. It is now a permanent safe
    -- landing buffer, so a close key can never terminate the Neovim process.
    if filetype == "snacks_dashboard" then
        vim.notify("Nothing to close — use :q, :qa, or :qa! to exit Neovim", vim.log.levels.INFO)
        return
    end

    -- Floating tool windows can always be dismissed without affecting the
    -- application process.
    local win_config = vim.api.nvim_win_get_config(0)
    if win_config.relative ~= "" then
        if buftype == "terminal" then
            local job_id = vim.b[buf].terminal_job_id

            -- Kill terminal job directly instead of sending "exit"
            if job_id then
                pcall(vim.fn.jobstop, job_id)
            end

            pcall(vim.cmd, "bd!")
        else
            -- Oil help, Lazy, popup windows, etc.
            pcall(vim.cmd, "close")
        end

        return
    end

    -- Plugin-specific exits restore their replaced editor buffer correctly.
    local in_diffview = false
    pcall(function()
        in_diffview = require("diffview.lib").get_current_view() ~= nil
    end)
    if in_diffview or vim.b[buf].lazygit_editor then
        vim.cmd("GitCloseAll")
        return
    end

    if vim.g.leetcode_active == true then
        pcall(vim.cmd, "Leet exit")
        return
    end

    if buftype == "terminal" then
        protect_terminal_tab_before_close()
        -- Another terminal takes this one's place and the focus, so closing one
        -- of several leaves you in the terminal section. Only when it was the
        -- last does focus go back to the editor.
        local stayed
        if filetype == "floaterm" then
            stayed = require("terminals").close(buf, { insert = was_typing })
        else
            local job_id = vim.b[buf].terminal_job_id
            if job_id then pcall(vim.fn.jobstop, job_id) end
            pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
        if not stayed then
            local editor = require("ide_layout").find_editor_window()
            if editor then vim.api.nvim_set_current_win(editor) end
        end
    elseif buftype == "quickfix" then
        pcall(vim.cmd, "cclose")
    elseif filetype == "oil" then
        pcall(vim.cmd, "close")
    elseif vim.b[buf].terminal_edit then
        -- An editable terminal copy temporarily occupies the editor pane. Put
        -- its prior buffer back before deleting the copy so the pane -- and
        -- therefore the bottom terminal boundary -- never disappears.
        if not close_editor_buffer(buf, vim.b[buf].terminal_edit_previous_buf) then
            return
        end
    elseif buftype ~= "" then
        if #vim.api.nvim_tabpage_list_wins(0) > 1 then
            pcall(vim.cmd, "confirm close")
        else
            close_editor_buffer(buf)
        end
    else
        local editor_windows = 0
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            local config = vim.api.nvim_win_get_config(win)
            if config.relative == "" and require("ide_layout").is_editor_window(win) then
                editor_windows = editor_windows + 1
            end
        end

        -- In a split, close the pane first and keep its buffer available. In
        -- the final editor pane, close the buffer and reveal a replacement.
        if editor_windows > 1 then
            local ok = pcall(vim.cmd, "confirm close")
            if not ok then return end
        elseif not close_editor_buffer(buf) then
            return
        end
    end

    -- Rebalance the remaining layout after a successful close.
    vim.schedule(function()
        pcall(vim.cmd, "wincmd =")
        pcall(vim.cmd, "LayoutEnforce")
    end)
end

-- ============================================================
-- CONSISTENT SPLIT LAYOUTS
-- Keep horizontal/vertical splits evenly sized.
-- ============================================================

local function equalize_splits()
    vim.cmd("wincmd =")
    -- `wincmd =` redistributes width across every window, so the fixed-width
    -- explorer has to be re-asserted immediately afterwards.
    pcall(vim.cmd, "LayoutEnforce")
end

vim.api.nvim_create_autocmd({
    "VimResized",
    "WinNew",
    "WinClosed",
    "BufWinEnter",
}, {
    group = vim.api.nvim_create_augroup("ConsistentSplitLayout", { clear = true }),
    callback = function()
        vim.schedule(equalize_splits)
    end,
    desc = "Keep split layouts consistent",
})

-- ============================================================
-- Render Markdown
-- ============================================================

require("render-markdown").setup({
    heading = {
        width = "block",
        min_width = 50,
        border = true,
        backgrounds = {
            "RenderMarkdownH1Bg",
            "RenderMarkdownH2Bg",
            "RenderMarkdownH3Bg",
            "RenderMarkdownH4Bg",
            "RenderMarkdownH5Bg",
            "RenderMarkdownH6Bg",
        },
        foregrounds = {
            "RenderMarkdownH1",
            "RenderMarkdownH2",
            "RenderMarkdownH3",
            "RenderMarkdownH4",
            "RenderMarkdownH5",
            "RenderMarkdownH6",
        },
    },
    render_modes = { "n", "v", "i", "c" },
    checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = " " },
        custom = {
            todo = {
                raw = "[>]",
                rendered = "󰥔 ",
            },
        },
    },
    code = {
        position = "right",
        width = "block",
        left_pad = 2,
        right_pad = 4,
    },
    -- Notebooks are Markdown with a lot of code cells and some markers, and are
    -- drawn to fit more of them on screen and to hide nothing worth reading:
    --   * code cells without the bar above and below -- two rows each, and the
    --     bar is also what covered the results molten draws under a cell;
    --   * HTML comments left visible. In a notebook they are often real text
    --     (an "Academic Integrity" notice was sitting in one), and a comment
    --     is exactly what a renderer hides.
    file_types = { "markdown", "jupyter" },
    overrides = {
        filetype = {
            jupyter = {
                code = { border = "none" },
                html = { comment = { conceal = false } },
            },
        },
    },
})

-- The notebook filetype is Markdown to the parser, so highlighting and the
-- python inside the fences work as they do in a note.
vim.treesitter.language.register("markdown", "jupyter")
vim.api.nvim_create_autocmd("FileType", {
    pattern = "jupyter",
    callback = function(args) pcall(vim.treesitter.start, args.buf, "markdown") end,
    desc = "Highlight notebooks as Markdown",
})


-- ============================================================
-- Basic Movement / Editing
-- ============================================================

vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll half-page up and center" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll half-page down and center" })
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines without moving cursor" })

vim.keymap.set("n", "<BS>", "ge", {
    noremap = true,
    silent = true,
    desc = "Go to previous end of word",
})

vim.keymap.set("x", "<", "<gv", {
    noremap = true,
    silent = true,
    desc = "Outdent and keep selection",
})

vim.keymap.set("x", ">", ">gv", {
    noremap = true,
    silent = true,
    desc = "Indent and keep selection",
})

vim.keymap.set("x", "J", ":move '>+1<CR>gv=gv", {
    noremap = true,
    silent = true,
    desc = "Move selection down",
})

vim.keymap.set("x", "K", ":move '<-2<CR>gv=gv", {
    noremap = true,
    silent = true,
    desc = "Move selection up",
})


-- ============================================================
-- Clipboard / Delete / Paste
-- ============================================================

-- "x", never "v", for anything whose key is a character you might type: "v"
-- is visual *and* select, and select mode is where a snippet leaves you with
-- a placeholder highlighted, waiting to be typed over. Mapped through "v",
-- "c" changed the placeholder instead of replacing it with the letter c.
vim.keymap.set({ "n", "x" }, "y", '"+y', {
    noremap = true,
    silent = true,
    desc = "Yank to system clipboard",
})

vim.keymap.set("n", "Y", '"+Y', {
    noremap = true,
    silent = true,
    desc = "Yank line to system clipboard",
})

vim.keymap.set({ "n", "x" }, "d", '"_d', {
    noremap = true,
    silent = true,
    desc = "Delete without clipboard",
})

vim.keymap.set("n", "D", '"_D', {
    noremap = true,
    silent = true,
    desc = "Delete line without clipboard",
})

vim.keymap.set({ "n", "x" }, "c", '"_c', {
    noremap = true,
    silent = true,
    desc = "Change without clipboard",
})

vim.keymap.set("n", "C", '"_C', {
    noremap = true,
    silent = true,
    desc = "Change line without clipboard",
})

vim.keymap.set("n", "S", '"_S', {
    noremap = true,
    silent = true,
    desc = "Substitute line without clipboard",
})

vim.keymap.set("n", "x", '"_x', {
    noremap = true,
    silent = true,
    desc = "Delete char without clipboard",
})

vim.keymap.set("n", "X", '"_X', {
    noremap = true,
    silent = true,
    desc = "Delete previous char without clipboard",
})

vim.keymap.set("n", "p", function()
    safe_paste("p")
end, {
    noremap = true,
    silent = true,
    desc = "Safe paste below",
})

vim.keymap.set("n", "P", function()
    safe_paste("P")
end, {
    noremap = true,
    silent = true,
    desc = "Safe paste above",
})

vim.keymap.set("x", "p", function()
    safe_paste("p")
end, {
    noremap = true,
    silent = true,
    desc = "Safe paste replacement",
})

-- Usually P in visual mode is the same as p, but we'll keep it consistent
vim.keymap.set("x", "P", function()
    safe_paste("P")
end, {
    noremap = true,
    silent = true,
    desc = "Safe paste replacement",
})

-- ============================================================
-- Editor Buffer Navigation
-- ============================================================

local function cycle_editor_buffer(direction)
    require("buffers").cycle(direction)
end

vim.keymap.set("n", "<Tab>", function() cycle_editor_buffer(1) end, {
    silent = true,
    desc = "Next editor buffer",
})

vim.keymap.set("n", "<S-Tab>", function() cycle_editor_buffer(-1) end, {
    silent = true,
    desc = "Previous editor buffer",
})

-- [ and ] go back and forward through the buffers you have been in, like a
-- browser's Back and Forward. They used to drive the cursor jumplist, which
-- records every search hit, `G` and jump inside a file, so "back" landed on a
-- line you had passed through in whichever buffer that was -- places that read
-- as random. A buffer is what you actually want to return to. See
-- lua/buffer_history.lua.
require("buffer_history").setup()

local function jump_back() require("buffer_history").back(vim.v.count1) end
local function jump_forward() require("buffer_history").forward(vim.v.count1) end

-- Not mapped globally. Only buffers that belong in the editor get them (below):
-- pressed in a picker, the explorer, a terminal or a plugin's panel, they would
-- change the buffer underneath it.

-- A single [ or ] is the start of dozens of other mappings -- ]d, [q, ]b, and
-- the buffer-local ]] [[ ]m of whatever filetype is open -- so Vim waits
-- 'timeoutlen' after every press to learn whether another key is coming. That
-- wait was half a second on every jump.
--
-- Nothing can make a key both a complete mapping and a prefix without it, so
-- the prefix goes: the whole [x / ]x family moves to g[x / g]x, where the
-- which-key popup lists it after g. The one-key jumplist mappings are then
-- <nowait> in every buffer, so a longer mapping some plugin adds later cannot
-- bring the wait back.
local function is_bracket_family(lhs)
    local first = lhs:sub(1, 1)
    return #lhs > 1 and (first == "[" or first == "]")
end

---@param buffer? integer a buffer to move that buffer's own mappings, or nil for the global ones
local function move_bracket_family(buffer)
    local maps = buffer and vim.api.nvim_buf_get_keymap(buffer, "n") or vim.api.nvim_get_keymap("n")

    for _, map in ipairs(maps) do
        if is_bracket_family(map.lhs) and not (map.desc or ""):match("^which%-key") then
            local moved = "g" .. map.lhs
            local rhs = map.callback or map.rhs

            if rhs and rhs ~= "" then
                vim.keymap.set("n", moved, rhs, {
                    buffer = buffer,
                    desc = map.desc,
                    silent = map.silent == 1,
                    expr = map.expr == 1,
                    nowait = map.nowait == 1,
                    remap = map.noremap ~= 1,
                })
            end
            pcall(vim.keymap.del, "n", map.lhs, { buffer = buffer })
        end
    end
end

---Whether a buffer is what the editor zone shows: a file or a blank buffer, or
---the dashboard and placeholder that fill it when nothing is open. Not the
---explorer, a terminal, the quickfix list, a picker, or a plugin's panel.
local function editor_zone_buffer(buf)
    local filetype = vim.bo[buf].filetype
    if filetype == "snacks_dashboard" or filetype == "ide_layout_placeholder" then return true end
    if vim.bo[buf].buftype ~= "" then return false end
    return not require("ide_layout").is_tool_buffer(buf)
end

local function keep_brackets_instant(buf)
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype == "prompt" then return end

    -- The family still moves for every buffer: a plugin panel's own [x / ]x
    -- would otherwise be a prefix of nothing, and a silent dead key.
    move_bracket_family()
    move_bracket_family(buf)

    if not editor_zone_buffer(buf) then
        pcall(vim.keymap.del, "n", "[", { buffer = buf })
        pcall(vim.keymap.del, "n", "]", { buffer = buf })
        return
    end

    vim.keymap.set("n", "[", jump_back, {
        buffer = buf,
        nowait = true,
        silent = true,
        desc = "Back to the previous buffer",
    })
    vim.keymap.set("n", "]", jump_forward, {
        buffer = buf,
        nowait = true,
        silent = true,
        desc = "Forward to the next buffer",
    })
end

-- FileType as well as BufWinEnter: a filetype plugin adds its own [[ and ]m
-- as the buffer is configured, and this has to move them after it has.
vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
    group = vim.api.nvim_create_augroup("InstantBrackets", { clear = true }),
    callback = function(args)
        vim.schedule(function() keep_brackets_instant(args.buf) end)
    end,
    desc = "Keep [ and ] instant by moving the [x / ]x family under g",
})

-- ============================================================
-- Editor Splits / Pane Sizing
-- ============================================================

local function focus_editor_pane()
    pcall(vim.cmd, "EditorFocus")
end

local function split_editor(command)
    focus_editor_pane()
    vim.cmd(command)
end

local function resize_editor(command)
    focus_editor_pane()
    vim.cmd(command)
end

vim.api.nvim_create_user_command("EditorSplitVertical", function()
    split_editor("vsplit")
end, { desc = "Split the current editor buffer vertically" })

vim.api.nvim_create_user_command("EditorSplitHorizontal", function()
    split_editor("split")
end, { desc = "Split the current editor buffer horizontally" })

vim.api.nvim_create_user_command("EditorPaneWider", function()
    resize_editor("vertical resize +5")
end, { desc = "Grow the editor pane horizontally" })

vim.api.nvim_create_user_command("EditorPaneNarrower", function()
    resize_editor("vertical resize -5")
end, { desc = "Shrink the editor pane horizontally" })

vim.api.nvim_create_user_command("EditorPaneTaller", function()
    resize_editor("resize +3")
end, { desc = "Grow the editor pane vertically" })

vim.api.nvim_create_user_command("EditorPaneShorter", function()
    resize_editor("resize -3")
end, { desc = "Shrink the editor pane vertically" })

vim.api.nvim_create_user_command("EditorPanesEqual", function()
    focus_editor_pane()
    vim.cmd("wincmd =")
end, { desc = "Equalize editor panes" })

vim.keymap.set("n", "zv", "<cmd>EditorSplitVertical<CR>", {
    silent = true,
    desc = "Vertical editor split",
})

vim.keymap.set("n", "zh", "<cmd>EditorSplitHorizontal<CR>", {
    silent = true,
    desc = "Horizontal editor split",
})

vim.keymap.set("n", "z=", "<cmd>EditorPanesEqual<CR>", {
    silent = true,
    desc = "Equalize editor panes",
})

-- The z-prefixed keys above and the action selectors (zs, zg, zd ...) belong to
-- the editor. The SSH launcher's windows are not the editor: pressing zs in
-- its list opened the live-server menu, and zv split the editor out from under
-- a form you were filling in. They get Vim's own meaning of those keys back
-- there, rather than dead ones -- `zh` and `zs` scroll sideways again.
local function restore_native_z_keys(buf)
    local keys = { "zv", "zh", "z=" }
    for _, menu in pairs(require("action_menus").menus) do
        if menu.lhs and menu.lhs:match("^z") then keys[#keys + 1] = menu.lhs end
    end

    for _, lhs in ipairs(keys) do
        vim.keymap.set("n", lhs, lhs, {
            buffer = buf,
            remap = false,
            silent = true,
            desc = "Vim's own " .. lhs,
        })
    end
end

vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("NativeZKeysInSsh", { clear = true }),
    pattern = { "ssh-launcher", "ssh-launcher-preview", "ssh-launcher-form", "ssh-launcher-dialog" },
    callback = function(args) restore_native_z_keys(args.buf) end,
    desc = "Keep the editor's z keys out of the SSH launcher",
})

vim.keymap.set("n", "<C-Right>", "<cmd>EditorPaneWider<CR>", {
    silent = true,
    desc = "Grow editor pane right",
})

vim.keymap.set("n", "<C-Left>", "<cmd>EditorPaneNarrower<CR>", {
    silent = true,
    desc = "Shrink editor pane from right",
})

vim.keymap.set("n", "<C-Up>", "<cmd>EditorPaneTaller<CR>", {
    silent = true,
    desc = "Grow editor pane upward",
})

vim.keymap.set("n", "<C-Down>", "<cmd>EditorPaneShorter<CR>", {
    silent = true,
    desc = "Shrink editor pane vertically",
})

-- ============================================================
-- Search / Replace
-- ============================================================

vim.keymap.set("n", "<leader>c", function()
    clear_search()
    -- Also drops a half-filled snippet, so its highlights go too.
    if vim.snippet.active() then vim.snippet.stop() end
end, {
    desc = "Clear search highlight and pattern, and any unfinished snippet",
})

vim.keymap.set({ "n", "x" }, "n", function()
    smart_search_and_jump("n")
end, {
    desc = "Sticky search next / matching pair",
})

vim.keymap.set({ "n", "x" }, "N", function()
    smart_search_and_jump("N")
end, {
    desc = "Sticky search previous / matching pair",
})

vim.keymap.set("n", "<leader>r", "*Ncgn", {
    noremap = true,
    silent = true,
    desc = "Start interactive replace for word",
})

vim.keymap.set({ "n", "i" }, "<C-.>", function()
    local function do_repeat()
        vim.api.nvim_feedkeys(".", "n", false)
    end

    if vim.fn.mode() == "i" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>n", true, false, true),
            "n",
            false
        )
        vim.defer_fn(do_repeat, 30)
    else
        vim.api.nvim_feedkeys("n", "n", false)
        vim.defer_fn(do_repeat, 30)
    end
end, {
    noremap = true,
    silent = true,
    desc = "Replace current match and find next",
})

vim.keymap.set({ "n", "i" }, "<C-,>", function()
    local function do_repeat()
        vim.api.nvim_feedkeys(".", "n", false)
    end

    if vim.fn.mode() == "i" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<Esc>N", true, false, true),
            "n",
            false
        )
        vim.defer_fn(do_repeat, 30)
    else
        vim.api.nvim_feedkeys("N", "n", false)
        vim.defer_fn(do_repeat, 30)
    end
end, {
    noremap = true,
    silent = true,
    desc = "Replace previous match",
})


-- ============================================================
-- LSP navigation (Snacks is the single picker backend)
-- ============================================================

vim.keymap.set("n", "gd", function()
    Snacks.picker.lsp_definitions()
end, {
    desc = "LSP definitions",
})

vim.keymap.set("n", "gr", function()
    Snacks.picker.lsp_references()
end, {
    desc = "LSP references",
})

vim.keymap.set("n", "gi", function()
    Snacks.picker.lsp_implementations()
end, {
    desc = "LSP implementations",
})

vim.keymap.set("n", "<leader>dd", function()
    Snacks.picker.diagnostics_buffer()
end, {
    desc = "Diagnostics current buffer",
})

vim.keymap.set("n", "<leader>dw", function()
    Snacks.picker.diagnostics({ cwd = require("workspace").context() })
end, {
    desc = "Diagnostics workspace",
})


-- ============================================================
-- Snacks Pickers
-- ============================================================

-- context(), not get(): a file open from outside the project takes the search
-- with it, so you can look through where it actually lives instead of
-- searching a root that cannot even see it. Returning to one of the project's
-- own files brings the scope back on its own.
vim.keymap.set({ "n", "v", "i" }, "<C-f>", function()
    Snacks.picker.files({ cwd = require("workspace").context() })
end, {
    desc = "Find files",
})

vim.keymap.set({ "n", "v", "i" }, "<C-g>", function()
    Snacks.picker.grep({ cwd = require("workspace").context() })
end, {
    desc = "Grep",
})

vim.keymap.set("n", "<leader>h", function()
    Snacks.picker.help()
end, {
    desc = "Help picker",
})

vim.api.nvim_create_user_command("ConfigFiles", function()
    Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Find a file in this Neovim config" })

vim.keymap.set({ "n", "x" }, "<leader>l", function()
    Snacks.picker.grep_word({ cwd = require("workspace").context() })
end, {
    desc = "Grep word or visual selection",
})

vim.keymap.set("n", "<leader>k", function()
    require("workflow_keymaps").open()
end, {
    desc = "My Neovim workflow keymaps",
})

vim.keymap.set("n", "<leader>K", function()
    Snacks.picker.keymaps()
end, {
    desc = "Search every active keymap",
})

-- Vim's own keys are not mappings, so neither <leader>k nor <leader>K can find
-- them: nothing in the keymap tables knows that `caw` changes a word. They get
-- their own searchable list, which also says which of them this config has
-- taken for something else.
vim.keymap.set("n", "<leader>v", function()
    require("vim_keymaps").open()
end, {
    desc = "Search Vim's own keys",
})

-- Everything this config can do, by name: build, stage a hunk, switch project,
-- open the SSH launcher. The selectors still exist for browsing one tool; this
-- is for when you know what you want and not where it lives.
vim.keymap.set("n", "<leader><leader>", function()
    require("palette").open()
end, {
    desc = "Command palette",
})

-- Bring a PDF, Word file, web page or image in as a Markdown note.
vim.keymap.set("n", "<leader>i", function()
    require("note_import").pick()
end, {
    desc = "Import a document as a note",
})

vim.api.nvim_create_user_command("Palette", function()
    require("palette").open()
end, { desc = "Search every action by name" })

vim.keymap.set({ "n", "i", "x", "t" }, "<C-\\>", function()
    require("workflow_keymaps").open()
end, {
    noremap = true,
    silent = true,
    desc = "Open my Neovim commands from any mode",
})

-- Every open buffer, not just this project's. Hiding the rest only made them
-- unreachable, so they are listed and tagged with the project they belong to
-- instead -- dimmed for the current one, highlighted when it is somewhere
-- else, so a buffer from another project is obvious rather than absent.
vim.keymap.set({ "n", "v", "i" }, "<C-b>", function()
    -- The buffer you are already in is the one result that can never be the
    -- answer. `current = false` alone does not remove it: the picker's own
    -- input buffer is the current one by the time its finder runs, so which
    -- buffer to drop has to be decided here, before the picker opens.
    local origin = vim.api.nvim_get_current_buf()
    if not require("buffers").is_editor(origin) then
        local win = require("ide_layout").find_editor_window()
        origin = win and vim.api.nvim_win_get_buf(win) or origin
    end

    Snacks.picker.buffers({
        sort_mru = true,
        current = false,
        transform = function(item) return item.buf ~= origin end,
        format = function(item, picker)
            local parts = Snacks.picker.format.buffer(item, picker)
            local label, is_current = require("buffers").workspace_label(item.buf)
            if label then
                parts[#parts + 1] = { "  " }
                -- Standard groups on purpose: the SnacksPicker* ones are not
                -- defined in this setup and would render as plain text.
                parts[#parts + 1] = {
                    Snacks.picker.util.align(label, 18),
                    is_current and "Comment" or "Special",
                }
            end
            return parts
        end,
    })
end, {
    desc = "Choose buffer",
})

---Every line of this buffer in a searchable list; Enter jumps to the one you
---pick, however far away it is. `pattern` pre-fills the search.
---@param pattern? string
local function find_in_buffer(pattern)
    Snacks.picker.lines({
        pattern = pattern,
        layout = {
            preview = false,
        },
    })
end

vim.keymap.set("n", "/", function() find_in_buffer() end, {
    desc = "Find in current buffer",
})


-- ============================================================
-- Project / Directory Navigation
-- ============================================================

local function choose_workspace_folder()
    Snacks.picker.explorer({
        title = "Choose Folder as Workspace  ·  l expand  ·  Enter choose",
        cwd = vim.fn.expand("~/"),
        hidden = true,
        ignored = true,
        follow_file = false,
        auto_close = true,
        layout = { preset = "vertical", preview = false },
        actions = {
            choose_workspace = function(picker, item)
                if not item or not item.file then return end

                local path = vim.fs.normalize(item.file)
                if vim.fn.isdirectory(path) == 0 then
                    path = vim.fn.fnamemodify(path, ":h")
                end

                picker:close()
                vim.schedule(function()
                    require("workspace").open(path, { exact = true })
                end)
            end,
        },
        win = {
            list = {
                keys = {
                    ["<CR>"] = "choose_workspace",
                },
            },
        },
    })
end

vim.keymap.set("n", "<leader>w", choose_workspace_folder, {
    desc = "Choose folder as workspace",
})

vim.keymap.set("n", "<leader>f", function()
    Snacks.picker.files({ cwd = vim.fn.expand("~/") })
end, {
    desc = "Find user files",
})

local function open_project_switcher()
    local workspace = require("workspace")

    -- A finder rather than a fixed list: naming and forgetting act on the list
    -- you are looking at, so it has to be able to answer again.
    local function projects()
        local current = workspace.get()
        local items = {}

        for _, path in ipairs(workspace.recent(20)) do
            local name = workspace.label(path)
            local is_current = path == current
            local is_open = workspace.is_open(path)
            items[#items + 1] = {
                -- What you can see is what you can type: the filter reads the
                -- name and nothing else, so a row never matches on a path or
                -- a status word that is nowhere on it.
                text = name,
                name = name,
                file = path,
                current = is_current,
                open = is_open,
            }
        end

        items[#items + 1] = {
            text = "Browse for another folder…",
            name = "Browse for another folder…",
            browse = true,
        }
        return items
    end

    Snacks.picker.pick({
        title = "Switch Project  ·  Ctrl-E name  ·  Ctrl-D close, again to forget",
        finder = projects,
        preview = false,
        layout = { preset = "vscode" },
        actions = {
            -- Named, not renamed: the directory is untouched, so a project
            -- called something friendlier is still found where it always was.
            name_project = function(picker, item)
                if not item or item.browse then return end
                vim.ui.input({
                    prompt = "Name for " .. item.name .. " (empty to clear): ",
                    default = workspace.alias(item.file) or "",
                }, function(value)
                    if not value then return end
                    workspace.set_alias(item.file, value)
                    picker:find({ refresh = true })
                end)
            end,
            -- One key, two steps, in the order they have to happen. A project
            -- that is open is put away first -- its tab, splits and terminals
            -- go and it stays listed -- and once nothing of it is open, the
            -- same key takes it out of the list, leaving the directory alone.
            -- Forgetting an open project is refused anyway, since every tab
            -- re-asserts its own workspace, so the two never needed two keys.
            put_away_project = function(picker, item)
                if not item or item.browse then return end

                local done
                if workspace.is_open(item.file) then
                    done = workspace.close(item.file)
                else
                    done = workspace.forget(item.file)
                end
                if not done then return end

                -- A redraw puts the cursor back on the first row, which would
                -- make "press it again" act on a different project -- the
                -- current one, most likely. It stays on the same project, or
                -- on the row it was in once that project is gone.
                local row = picker.list.cursor
                picker:find({
                    refresh = true,
                    on_done = function()
                        local index, found = 0, nil
                        for _, listed in ipairs(picker:items()) do
                            index = index + 1
                            if listed.file == item.file then found = index break end
                        end
                        picker.list:view(found or math.min(row, math.max(index, 1)))
                    end,
                })
            end,
        },
        win = {
            input = {
                keys = {
                    ["<C-e>"] = { "name_project", mode = { "n", "i" } },
                    ["<C-d>"] = { "put_away_project", mode = { "n", "i" } },
                },
            },
        },
        format = function(item)
            if item.browse then
                return {
                    { "󰉋  ", "Directory" },
                    { item.name, "SnacksPickerLabel" },
                }
            end

            local status = item.current and "CURRENT" or item.open and "OPEN   " or "       "
            return {
                { status,    item.current and "DiagnosticOk" or item.open and "DiagnosticInfo" or "Comment" },
                { "  " },
                { item.name, "SnacksPickerFile" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end

            vim.schedule(function()
                if item.browse then
                    choose_workspace_folder()
                elseif not item.current then
                    workspace.open(item.file, { exact = true })
                end
            end)
        end,
    })
end

vim.keymap.set("n", "<leader>p", open_project_switcher, {
    desc = "Switch live project context",
})

vim.keymap.set("n", "<C-o>", open_project_switcher, {
    desc = "Switch live project context",
})

vim.keymap.set("n", "go", open_in_file_manager, {
    noremap = true,
    silent = true,
    desc = "Open current folder in Finder/Explorer",
})

vim.keymap.set("n", "gx", function()
    local raw = vim.fn.expand("<cWORD>")
    local target = vim.fn.fnamemodify(vim.fn.expand(raw), ":p")

    if raw:match("^https?://") then
        vim.system({ "open", raw })
    elseif target:match("^https?://") then
        vim.system({ "open", target })
    elseif vim.fn.isdirectory(target) == 1 then
        vim.system({ "open", target })
    elseif vim.fn.filereadable(target) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(target))
    else
        print("Unknown target: " .. raw)
    end
end, {
    silent = true,
    desc = "Open links, files, and directories",
})


-- ============================================================
-- Save / Source / Quit / Set Working Dir
-- ============================================================

vim.keymap.set("n", "<leader>o", ":update<CR>:source<CR>", {
    desc = "Update and source current file",
})

vim.keymap.set({ "n", "i", "v" }, "<C-s>", save_current_file, {
    noremap = true,
    silent = true,
    desc = "Save",
})

local function close_with_ctrl_q()
    close_current()
end

vim.keymap.set({ "n", "v", "i", "t" }, "<C-q>", close_with_ctrl_q, {
    noremap = true,
    silent = true,
    desc = "Close current buffer, pane, panel, or terminal (never exit Neovim)",
})

-- Ctrl-Q is the universal close key. Ctrl-C is deliberately left available
-- for plugin-local cancel/close actions and its normal interrupt behaviour.
-- These built-in shortcuts can close panes or the application, so leave
-- exiting Neovim to explicit :q/:qa/:qa! commands.
for _, lhs in ipairs({ "<C-w>q", "<C-w>c", "ZZ", "ZQ" }) do
    vim.keymap.set("n", lhs, "<Nop>", {
        silent = true,
        desc = "Disabled: use Ctrl-Q to close",
    })
end

-- Runtime ftplugins commonly add q/Esc shortcuts that silently run :quit,
-- :bdelete, or a close action. Neutralize only those close-like local mappings;
-- editing/navigation meanings and plugin-local Ctrl-C actions are left alone.
local function enforce_close_key_contract(buf)
    if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype == "terminal" then return end

    vim.api.nvim_buf_call(buf, function()
        for _, mode in ipairs({ "n", "i" }) do
            for _, lhs in ipairs({ "q", "<Esc>" }) do
                local map = vim.fn.maparg(lhs, mode, false, true)
                if map.buffer == 1 then
                    local meaning = ((map.desc or "") .. " " .. (map.rhs or "")):lower()
                    local closes = meaning:find("close", 1, true)
                        or meaning:find("quit", 1, true)
                        or meaning:find("cancel", 1, true)
                        or meaning:find("bdelete", 1, true)
                        or meaning:find("<cmd>bd", 1, true)
                    if closes and map.rhs ~= "<Nop>" then
                        vim.keymap.set(mode, lhs, "<Nop>", {
                            buffer = buf,
                            silent = true,
                            desc = "Disabled: use Ctrl-Q to close",
                        })
                    end
                end
            end
        end
    end)
end

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
    group = vim.api.nvim_create_augroup("UniversalCloseKeys", { clear = true }),
    callback = function(args)
        vim.schedule(function() enforce_close_key_contract(args.buf) end)
    end,
    desc = "Reserve Ctrl-Q as the universal close key",
})

-- Deliberately change the workspace instead of creating a temporary cwd.
vim.keymap.set("n", "zcd", function()
    require("workspace").from_here()
end, { desc = "Use this file's project, or the explorer's folder, as workspace" })

-- ============================================================
-- Insert / Command / Terminal
-- ============================================================

vim.keymap.set("t", "<C-v>", "<C-\\><C-n>", {
    noremap = true,
    desc = "Browse and yank terminal output with normal motions",
})

vim.keymap.set("c", "<CR>", function()
    if vim.fn.pumvisible() == 1 then
        return "<C-y>"
    end

    return "<CR>"
end, {
    expr = true,
})

vim.keymap.set("i", "<CR>", function()
    if vim.fn.pumvisible() == 1 then
        local info = vim.fn.complete_info({ "selected" })

        if info.selected == -1 then
            return vim.api.nvim_replace_termcodes("<C-n><C-y>", true, false, true)
        end

        return vim.api.nvim_replace_termcodes("<C-y>", true, false, true)
    end

    return vim.api.nvim_replace_termcodes("<CR>", true, false, true)
end, {
    expr = true,
})

vim.keymap.set("n", "<CR>", function()
    local col = vim.fn.col(".")
    local line = vim.fn.getline(".")
    local char = line:sub(col, col)

    if char == "" or char:match("%s") then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("w", true, false, true),
            "n",
            true
        )
    else
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes('"_ciw', true, false, true),
            "n",
            true
        )
    end
end, {
    noremap = true,
    silent = true,
    desc = "Enter: move word or change inner word",
})


-- ============================================================
-- Quick Notes / Kitty
-- ============================================================

vim.api.nvim_create_user_command("QuickNotes", function()
    local notes = vim.fn.expand("~/Library/Mobile Documents/com~apple~CloudDocs/Desktop/quicknotes.md")

    if vim.fn.filereadable(notes) == 0 then
        vim.fn.writefile({}, notes)
    end

    pcall(vim.cmd, "EditorFocus")
    vim.cmd("edit " .. vim.fn.fnameescape(notes))
end, { desc = "Open quick notes" })

-- ============================================================
-- Flash Search
-- ============================================================

-- flash.nvim locates the end of a match by reading Neovim's internal
-- `search_match_lines` / `search_match_endcol` C globals over LuaJIT FFI.
-- Neovim nightly no longer exports either symbol, so every `s` jump died with
-- "symbol not found" before a single match could be collected. Upstream has no
-- fix (checked against origin/main), so re-derive the end position with an
-- ordinary `ce` search, which needs no internals at all.
local function patch_flash_ffi()
    local exported = pcall(function()
        local ffi = require("ffi")
        ffi.cdef([[unsigned int search_match_lines;]])
        return ffi.C.search_match_lines
    end)
    if exported then return end

    local ok, Search = pcall(require, "flash.search")
    if not ok then return end
    local Pos = require("flash.search.pos")

    function Search:_next(flags)
        flags = flags or ""
        local pattern = self.state.pattern.search
        local found, pos = pcall(vim.fn.searchpos, pattern, flags)
        if not found or pos[1] == 0 then return end

        local start = Pos({ pos[1], pos[2] - 1 })
        -- "ce" lands on the final character of the match just matched; "n"
        -- keeps the cursor put so the caller's own iteration is unaffected.
        local ok_end, epos = pcall(vim.fn.searchpos, pattern, "ceWn")
        local finish = (ok_end and epos[1] ~= 0) and Pos({ epos[1], epos[2] - 1 }) or start

        return { win = self.win, pos = start, end_pos = finish }
    end
end

pcall(patch_flash_ffi)

vim.keymap.set({ "x", "o" }, "s", function() require("flash").jump() end, { desc = "Flash" })

-- Flash only ever sees the lines on screen, and gives up the moment what you
-- have typed matches nothing there. In normal mode that is where `/` takes over:
-- the same text, over every line of the buffer. Flash exits without keeping the
-- keys typed after the one that failed, and a quick typist has already typed
-- some, so those are collected and carried into the search rather than being
-- run as commands.
vim.keymap.set("n", "s", function()
    local before = vim.api.nvim_win_get_cursor(0)
    local state = require("flash").jump()

    if not state or #state.results > 0 or state.pattern:empty() then return end
    if not vim.deep_equal(before, vim.api.nvim_win_get_cursor(0)) then return end

    local typed = state.pattern()
    while true do
        local key = vim.fn.getchar(0)
        if key == 0 then break end
        if type(key) ~= "number" or key < 32 then
            if key == 27 then return end   -- Escape: they changed their mind
            break
        end
        typed = typed .. vim.fn.nr2char(key)
    end

    vim.schedule(function() find_in_buffer(typed) end)
end, { desc = "Flash, or search the whole buffer if nothing on screen matches" })
-- vim.keymap.set({ "n" }, "sa", function()
--     require("flash").jump({
--         pattern = ".", -- initialize pattern with any char
--         search = {
--             mode = function(pattern)
--                 -- remove leading dot
--                 if pattern:sub(1, 1) == "." then
--                     pattern = pattern:sub(2)
--                 end
--                 -- return word pattern and proper skip pattern
--                 return ([[\<%s\w*\>]]):format(pattern), ([[\<%s]]):format(pattern)
--             end,
--         },
--         -- select the range
--         jump = { pos = "range" },
--     })
-- end, { desc = "Flash select any word" })


-- ============================================================
-- Run Programs
-- ============================================================


-- What run() and runtest() in ~/.zshrc know how to handle. Checking here only
-- saves opening a terminal for a file nothing can be done with; the shell
-- functions stay the authority and say so in the panel when these have
-- drifted. Names as well as extensions, because a Dockerfile has no extension
-- and a Makefile is not a .make.
-- run / runtest are zsh functions, so they go through the terminal panel, not
-- jobstart (which cannot execute a shell function -- the "'run' is not
-- executable" error). See runner.lua.
local function run_current_file() require("runner").run("run") end
local function test_current_file() require("runner").run("runtest") end

vim.keymap.set("n", "<leader>e", run_current_file, {
    silent = true,
    desc = "Run current file",
})

-- Note this makes <leader>x a prefix: the Xcode selector now waits out
-- 'timeoutlen' before opening, in case an r is coming.
vim.keymap.set("n", "<leader>xr", test_current_file, {
    silent = true,
    desc = "Test current file",
})

vim.api.nvim_create_user_command("RunWith", function() require("runner").run("run", { ask = true }) end, {
    desc = "Run the file (here, or under the cursor in the explorer) with arguments you type",
})

vim.api.nvim_create_user_command("RunTestWith", function() require("runner").run("runtest", { ask = true }) end, {
    desc = "Test the file with arguments you type",
})

vim.api.nvim_create_user_command("Run", run_current_file, {
    desc = "Run the current file through the zsh run function",
})

vim.api.nvim_create_user_command("RunTest", test_current_file, {
    desc = "Test the current file through the zsh runtest function",
})

-- The chores from ~/.zshrc that make sense inside the editor: palette only.
require("shell_tools").setup()

-- The "how do I ..." list: surround a word, change what is inside a block, swap
-- lines. Same list as the palette, opened already filtered to the editing recipes.
-- Select, then S and the character: S" quotes it, S( or Sb brackets it, S* makes
-- it bold. The same job as the "Surround selection" recipes with one key.
vim.keymap.set("x", "S", function()
    require("recipes").surround_selection()
end, { desc = "Surround the selection with the next character typed" })

local function open_recipes()
    -- From a selection, leave visual mode first: that is what sets the '< and
    -- '> marks the "surround selection" recipes work on.
    if vim.fn.mode():match("[vV\22]") then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end
    require("palette").open("Edit ")
end

vim.api.nvim_create_user_command("Recipes", open_recipes, {
    desc = "Search editing recipes: surround, blocks, lines",
})

vim.keymap.set({ "n", "x" }, "<leader>?", open_recipes, {
    desc = "Search editing recipes (surround, blocks, lines)",
})
