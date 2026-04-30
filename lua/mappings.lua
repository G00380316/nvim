-- ============================================================
-- Core Requires
-- ============================================================

local Snacks = require("snacks")


-- ============================================================
-- State
-- ============================================================

local sticky_active = false
local sticky_word = nil
local case_sensitive = false

local previous_state_file = vim.fn.stdpath("data") .. "/previous_buffer.txt"
local last_buffer = nil
local previous_file = nil


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
    local prefix = case_sensitive and "" or "\\c"
    return prefix .. "\\<" .. escaped .. "\\>"
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
    local reg = vim.v.register
    if reg == "" then
        reg = '"'
    end

    local mode = vim.fn.mode()
    local is_visual = mode:match("[vV\22]") ~= nil

    -- Character-wise paste → leave untouched
    if not regtype_is_linewise(reg) then
        vim.cmd("normal! " .. direction)
        return
    end

    -- =========================
    -- VISUAL MODE (replacement)
    -- =========================
    if is_visual then
        local start_line = vim.fn.line("'<")
        local end_line = vim.fn.line("'>")

        -- Add spacing before replacement
        ensure_blank_line_above(start_line)
        ensure_blank_line_below(end_line)

        -- Replace selection
        vim.cmd("normal! " .. direction)

        local last_pasted = vim.fn.line("']")

        ensure_blank_line_below(last_pasted)
        return
    end

    -- =========================
    -- NORMAL MODE (your original)
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
-- Persistent Previous File Helpers
-- Used by zv / zh split mappings.
-- ============================================================

local function save_previous_buffer(path)
    if path and path ~= "" then
        vim.fn.writefile({ path }, previous_state_file)
    end
end

local function load_previous_buffer()
    if vim.fn.filereadable(previous_state_file) == 1 then
        local lines = vim.fn.readfile(previous_state_file)

        if lines[1] and vim.fn.filereadable(lines[1]) == 1 then
            return lines[1]
        end
    end

    return nil
end

previous_file = load_previous_buffer()

vim.api.nvim_create_autocmd("BufEnter", {
    callback = function()
        local current_buf = vim.api.nvim_get_current_buf()
        local current_file = vim.api.nvim_buf_get_name(current_buf)

        if not vim.api.nvim_buf_is_valid(current_buf) then
            return
        end

        if vim.bo[current_buf].buftype ~= "" or current_file == "" then
            return
        end

        if current_buf ~= last_buffer then
            if last_buffer and vim.api.nvim_buf_is_valid(last_buffer) then
                local last_file = vim.api.nvim_buf_get_name(last_buffer)

                if last_file ~= "" and vim.fn.filereadable(last_file) == 1 then
                    previous_file = last_file
                    save_previous_buffer(previous_file)
                end
            end

            last_buffer = current_buf
        end
    end,
})

local function open_split_with_previous(split_cmd, move_cmd)
    vim.cmd(split_cmd)
    vim.cmd("wincmd " .. move_cmd)

    if previous_file and vim.fn.filereadable(previous_file) == 1 then
        vim.cmd("edit " .. vim.fn.fnameescape(previous_file))
    end

    vim.schedule(function()
        vim.cmd("wincmd =")
    end)
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

local function refresh_split_layout()
    vim.schedule(function()
        pcall(vim.cmd, "wincmd =")
    end)
end

local function switch_to_spare_buffer_or_close(current_buf)
    local visible = {}

    -- Track buffers already open in windows.
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_is_valid(win) then
            local win_buf = vim.api.nvim_win_get_buf(win)

            if win_buf ~= current_buf then
                visible[win_buf] = true
            end
        end
    end

    -- Find any listed real buffer that is not already visible.
    for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        local candidate = info.bufnr

        if candidate ~= current_buf
            and not visible[candidate]
            and vim.api.nvim_buf_is_valid(candidate)
            and vim.api.nvim_buf_is_loaded(candidate)
            and vim.bo[candidate].buftype == ""
        then
            vim.api.nvim_set_current_buf(candidate)

            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(current_buf) then
                    pcall(vim.api.nvim_buf_delete, current_buf, { force = true })
                end

                pcall(vim.cmd, "wincmd =")
            end)

            return true
        end
    end

    return false
end

local function quit()
    local mode = vim.fn.mode()

    if mode == "i" then
        vim.cmd("stopinsert")
    elseif mode == "t" then
        vim.api.nvim_feedkeys(
            vim.api.nvim_replace_termcodes("<C-\\><C-n>", true, false, true),
            "n",
            false
        )
    end

    if pcall(vim.cmd, "Leet exit") then
        return
    end

    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local modified = vim.bo[buf].modified
    local buftype = vim.bo[buf].buftype

    if name == "" and not modified then
        pcall(vim.cmd, "qa")
        return
    end

    -- Terminal buffers should close normally.
    -- Do not replace them with a spare buffer.
    if buftype == "terminal" then
        if #vim.fn.win_findbuf(buf) > 1 then
            pcall(vim.cmd, "close")
        else
            pcall(vim.cmd, "bd!")
        end

        refresh_split_layout()
        return
    end

    local wins = vim.fn.win_findbuf(buf)

    if switch_to_spare_buffer_or_close(buf) then
        return
    end

    if #wins > 1 then
        pcall(vim.cmd, "close")
    else
        pcall(vim.cmd, "bd!")
    end

    refresh_split_layout()
end

-- ============================================================
-- CONSISTENT SPLIT LAYOUTS
-- Keep horizontal/vertical splits evenly sized.
-- ============================================================

local function equalize_splits()
    vim.cmd("wincmd =")
end

vim.keymap.set("n", "z=", equalize_splits, {
    noremap = true,
    silent = true,
    desc = "Equalize split layout",
})

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
    opts = {
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
    },
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

vim.keymap.set({ "v", "x" }, "<", "<gv", {
    noremap = true,
    silent = true,
    desc = "Outdent and keep selection",
})

vim.keymap.set({ "v", "x" }, ">", ">gv", {
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

vim.keymap.set({ "n", "v" }, "y", '"+y', {
    noremap = true,
    silent = true,
    desc = "Yank to system clipboard",
})

vim.keymap.set("n", "Y", '"+Y', {
    noremap = true,
    silent = true,
    desc = "Yank line to system clipboard",
})

vim.keymap.set({ "n", "v" }, "d", '"_d', {
    noremap = true,
    silent = true,
    desc = "Delete without clipboard",
})

vim.keymap.set("n", "D", '"_D', {
    noremap = true,
    silent = true,
    desc = "Delete line without clipboard",
})

vim.keymap.set({ "n", "v" }, "c", '"_c', {
    noremap = true,
    silent = true,
    desc = "Change without clipboard",
})

vim.keymap.set("n", "C", '"_C', {
    noremap = true,
    silent = true,
    desc = "Change line without clipboard",
})

vim.keymap.set({ "n", "v" }, "s", '"_s', {
    noremap = true,
    silent = true,
    desc = "Substitute without clipboard",
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

vim.keymap.set("x", "p", '"_dP', {
    noremap = true,
    silent = true,
    desc = "Replace selection without clipboard",
})

vim.keymap.set("x", "P", '"_dP', {
    noremap = true,
    silent = true,
    desc = "Replace selection without clipboard",
})


-- ============================================================
-- Jump List / Buffers / Windows
-- ============================================================

vim.keymap.set("n", "<C-o>", "<nop>", {
    silent = true,
    desc = "Disable default previous jump",
})

vim.keymap.set("n", "<C-i>", "<nop>", {
    silent = true,
    desc = "Disable default forward jump",
})

vim.keymap.set("n", "<C-]>", "<C-i>", {
    noremap = true,
    silent = true,
    desc = "Jump to next position",
})

vim.keymap.set("n", "<C-[>", "<C-o>", {
    noremap = true,
    silent = true,
    desc = "Jump to previous position",
})

vim.keymap.set("n", "<Tab>", "<cmd>bn<CR>", {
    noremap = true,
    silent = true,
    desc = "Next buffer",
})

vim.keymap.set("n", "<S-Tab>", "<cmd>bp<CR>", {
    noremap = true,
    silent = true,
    desc = "Previous buffer",
})

vim.keymap.set("n", "zv", function()
    open_split_with_previous("vsplit", "l")
end, {
    noremap = true,
    silent = true,
    desc = "Vertical split with previous file",
})

vim.keymap.set("n", "zh", function()
    open_split_with_previous("split", "j")
end, {
    noremap = true,
    silent = true,
    desc = "Horizontal split with previous file",
})

vim.keymap.set("n", "<C-w>", "<C-w>w", {
    noremap = true,
    silent = true,
    desc = "Switch to next window",
})

vim.keymap.set("i", "<C-w>", "<Esc><C-w>w", {
    noremap = true,
    silent = true,
    desc = "Switch to next window from insert mode",
})

vim.keymap.set("v", "<C-w>", "<C-w>w", {
    noremap = true,
    silent = true,
    desc = "Switch to next window in visual mode",
})

vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>w]], {
    noremap = true,
    silent = true,
    desc = "Switch to next window in terminal mode",
})


-- ============================================================
-- Search / Replace
-- ============================================================

vim.keymap.set("n", "<leader>c", clear_search, {
    desc = "Clear search highlight and pattern",
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

vim.keymap.set("n", "<leader>s", function()
    case_sensitive = not case_sensitive

    if sticky_active and sticky_word then
        vim.fn.setreg("/", build_search_pattern(sticky_word))
    end

    vim.notify(
        "Sticky Search case-sensitive: " .. tostring(case_sensitive),
        vim.log.levels.INFO,
        { timeout = 1000 }
    )
end, {
    desc = "Toggle sticky search case sensitivity",
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
-- LSP / fzf-lua
-- ============================================================

vim.keymap.set("n", "gd", function()
    require("fzf-lua").lsp_definitions()
end, {
    desc = "LSP definitions",
})

vim.keymap.set("n", "gr", function()
    require("fzf-lua").lsp_references()
end, {
    desc = "LSP references",
})

vim.keymap.set("n", "gi", function()
    require("fzf-lua").lsp_implementations()
end, {
    desc = "LSP implementations",
})

vim.keymap.set("n", "<leader>dd", function()
    require("fzf-lua").diagnostics_document()
end, {
    desc = "Diagnostics current buffer",
})

vim.keymap.set("n", "<leader>dw", function()
    require("fzf-lua").diagnostics_workspace()
end, {
    desc = "Diagnostics workspace",
})


-- ============================================================
-- Snacks Pickers
-- ============================================================

vim.keymap.set({ "n", "v", "i" }, "<C-f>", function()
    Snacks.picker.files()
end, {
    desc = "Find files",
})

vim.keymap.set({ "n", "v", "i" }, "<C-g>", function()
    Snacks.picker.grep()
end, {
    desc = "Grep",
})

vim.keymap.set("n", "<leader>h", function()
    Snacks.picker.help()
end, {
    desc = "Help picker",
})

vim.keymap.set("n", "zcf", function()
    Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
end, {
    desc = "Find config files",
})

vim.keymap.set({ "n", "x" }, "<C-l>", function()
    Snacks.picker.grep_word()
end, {
    desc = "Grep word or visual selection",
})

vim.keymap.set("n", "<C-h>", function()
    Snacks.picker.keymaps()
end, {
    desc = "Search keymaps",
})

vim.keymap.set({ "n", "v", "i" }, "<C-b>", function()
    Snacks.picker.buffers({
        sort_mru = true,
        current = true,
    })
end, {
    desc = "Choose buffer",
})

vim.keymap.set("n", "/", function()
    Snacks.picker.lines({
        layout = {
            preview = false,
        },
        win = {
            input = {
                keys = {
                    ["<C-c>"] = { "close", mode = { "n", "i" } },
                },
            },
        },
    })
end, {
    desc = "Find in current buffer",
})


-- ============================================================
-- Project / Directory Navigation
-- ============================================================

vim.keymap.set("n", "<leader>p", function()
    require("oil").open("~/Documents/Github")
end, {
    desc = "Open project directories",
})

vim.keymap.set("n", "<leader>cd", function()
    require("oil").open("~/Library/Mobile Documents/com~apple~CloudDocs/")
end, {
    desc = "Open iCloud documents",
})

vim.keymap.set("n", "<leader>d", function()
    require("oil").open("~/")
end, {
    desc = "Open home directory",
})

vim.keymap.set("n", "zf", function()
    Snacks.picker.files({ cwd = vim.fn.expand("~/") })
end, {
    desc = "Find user files",
})

vim.keymap.set("n", "<leader>f", function()
    Snacks.picker.files({ cwd = vim.fn.expand("~/Documents/Github") })
end, {
    desc = "Find project files",
})

vim.keymap.set("n", "<leader>g", function()
    Snacks.picker.grep({ cwd = vim.fn.expand("~/Documents/Github") })
end, {
    desc = "Grep project files",
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
-- Save / Source / Quit
-- ============================================================

vim.keymap.set("n", "<leader>o", ":update<CR>:source<CR>", {
    desc = "Update and source current file",
})

vim.keymap.set({ "n", "i", "v" }, "<C-s>", save_current_file, {
    noremap = true,
    silent = true,
    desc = "Save",
})

vim.keymap.set({ "n", "v", "i", "t" }, "<C-q>", quit, {
    noremap = true,
    silent = true,
    desc = "Smart close / quit",
})

vim.keymap.set("n", "q", quit, {
    noremap = true,
    silent = true,
    desc = "Smart close / quit",
})


-- ============================================================
-- Insert / Command / Terminal
-- ============================================================

vim.keymap.set("t", "<C-v>", "<C-\\><C-n>", {
    noremap = true,
    desc = "Exit terminal mode",
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
-- Quick Notes / Kitty / Lazygit
-- ============================================================

vim.keymap.set("n", "<leader>qn", function()
    local notes = vim.fn.expand("~/Library/Mobile Documents/com~apple~CloudDocs/Desktop/quicknotes.md")

    if vim.fn.filereadable(notes) == 0 then
        vim.fn.writefile({}, notes)
    end

    vim.cmd(
        "FloatermNew"
        .. " --height=0.85"
        .. " --width=0.85"
        .. " --title=QuickNotes"
        .. " --autoclose=2"
        .. " nvim "
        .. vim.fn.fnameescape(notes)
    )
end, {
    noremap = true,
    silent = true,
    desc = "Quick notes",
})

vim.keymap.set("n", "zg", function()
    vim.fn.jobstart({
        "kitty",
        "@",
        "launch",
        "--cwd",
        vim.fn.getcwd(),
        "--type",
        "tab",
        "lazygit",
    }, {
        detach = true,
    })
end, {
    noremap = true,
    silent = true,
    desc = "Open Lazygit in Kitty tab",
})

-- ============================================================
-- Alpha / Leet
-- ============================================================

vim.keymap.set({ "n", "t" }, "<C-a>", "<cmd>Alpha<CR>", {
    noremap = true,
    silent = true,
    desc = "Open Alpha",
})

vim.keymap.set("n", "zlo", function()
    vim.fn.jobstart({
        "kitty",
        "@",
        "launch",
        "--cwd",
        vim.fn.getcwd(),
        "--type",
        "tab",
        "nvim",
        "+Leet",
    }, {
        detach = true,
    })
end, {
    noremap = true,
    silent = true,
    desc = "Open Leet in Kitty tab",
})

vim.keymap.set("n", "zlt", "<cmd>Leet Run<CR>", {
    noremap = true,
    silent = true,
    desc = "Test Leet solution",
})

vim.keymap.set("n", "zls", "<cmd>Leet Submit<CR>", {
    noremap = true,
    silent = true,
    desc = "Submit Leet solution",
})

vim.keymap.set("n", "zll", "<cmd>Leet List<CR>", {
    noremap = true,
    silent = true,
    desc = "List Leet problems",
})

vim.keymap.set("n", "zlr", "<cmd>Leet Reset<CR>", {
    noremap = true,
    silent = true,
    desc = "Reset Leet solution",
})


-- ============================================================
-- Grug Far Search / Replace
-- ============================================================

vim.keymap.set("n", "zsw", function()
    require("grug-far").open({
        prefills = {
            search = vim.fn.expand("<cword>"),
        },
    })
end, {
    desc = "Search current word",
})

vim.keymap.set("v", "zsw", function()
    require("grug-far").with_visual_selection()
end, {
    desc = "Search selection",
})

vim.keymap.set("n", "zs", function()
    require("grug-far").open({
        transient = true,
    })
end, {
    desc = "Search window",
})
