local M = {}

-- A cheat sheet for taking notes, docked beside the note rather than opened over
-- it. By default it never takes focus, so it can stay up while you type, and it
-- follows you: it is there for a Markdown buffer and gone for anything else, and
-- comes back when you return.
--
--   <leader>m   show or hide it
--   <leader>M   step into it: j/k move between entries, Enter puts the entry in
--               the note as a snippet (Tab through its fields), q/Esc steps back
--
-- What it lists is what render-markdown is set up to draw, read from the live
-- configuration where that is cheap -- the callout types, the extra checkbox
-- states -- so it cannot drift from what the buffer actually renders.

local ns = vim.api.nvim_create_namespace("markdown_hints")
local enabled = false
local float_buf, float_win
local min_width = 70

---@type table<integer, markdown.HintEntry> buffer line -> what Enter inserts there
local entries = {}

-- The callouts worth reaching for in notes, most useful first. Only those the
-- configuration actually renders are shown.
local favourite_callouts = {
    "NOTE", "TIP", "IMPORTANT", "WARNING", "CAUTION", "TODO", "QUESTION", "EXAMPLE", "BUG",
}

---@class markdown.HintEntry
---@field snippet string vim.snippet text
---@field block boolean on a line of its own, rather than at the cursor

local function render_config(buf)
    local ok, state = pcall(require, "render-markdown.state")
    if not ok then return nil end
    local got, cfg = pcall(state.get, buf)
    return got and cfg or nil
end

-- A row is { syntax, meaning, snippet?, block? }. With a snippet it can be
-- inserted; without one it is only information. `$` is escaped in snippets, as
-- the snippet grammar gives it a meaning of its own.
---@return { title: string, rows: table[] }[]
local function sections(buf)
    local cfg = render_config(buf)

    local callouts, extra = {}, 0
    if cfg and cfg.callout then
        local present = {}
        for _, c in pairs(cfg.callout) do present[tostring(c.raw):upper()] = true end
        for _, name in ipairs(favourite_callouts) do
            if present["[!" .. name .. "]"] then callouts[#callouts + 1] = name end
        end
        local total = 0
        for _ in pairs(present) do total = total + 1 end
        extra = math.max(0, total - #callouts)
    else
        callouts = vim.list_slice(favourite_callouts, 1, 6)
    end

    local custom = {}
    if cfg and cfg.checkbox and cfg.checkbox.custom then
        for name, c in pairs(cfg.checkbox.custom) do custom[#custom + 1] = { name, c.raw } end
        table.sort(custom, function(a, b) return a[1] < b[1] end)
    end

    local tasks = {
        { "- [ ] task", "an open task", "- [ ] ${1:task}", true },
        { "- [x] task", "a finished one", "- [x] ${1:task}", true },
    }
    for _, c in ipairs(custom) do
        tasks[#tasks + 1] = { "- " .. c[2] .. " task", c[1], "- " .. c[2] .. " ${1:task}", true }
    end

    -- The callout names as short rows: one long row is wider than everything
    -- else together, and then the whole window has to be. Each row is a list to
    -- read, not an entry to insert -- the callout entry above it inserts one.
    local callout_rows, row = {}, ""
    for _, name in ipairs(callouts) do
        if #row + #name + 2 > 30 and row ~= "" then
            callout_rows[#callout_rows + 1] = { row, "" }
            row = ""
        end
        row = row == "" and name or (row .. "  " .. name)
    end
    if row ~= "" then callout_rows[#callout_rows + 1] = { row, "" } end
    if extra > 0 then callout_rows[#callout_rows + 1] = { "+" .. extra .. " more types", "" } end

    return {
        { title = "Structure", rows = {
            { "# Heading", "## to ###### for smaller", "# ${1:Heading}", true },
            { "---", "a divider line", "---", true },
            { "> quote", "a block quote", "> ${1:quote}", true },
            { "> [!NOTE]", "a callout box", "> [!${1:NOTE}] ${2:Title}\n> ${3:Text}", true },
        } },
        { title = "Callout types", rows = callout_rows },
        { title = "Lists and tasks", rows = vim.list_extend({
            { "- item", "or * item, 1. item", "- ${1:item}", true },
        }, tasks) },
        { title = "Text", rows = {
            { "**bold**", "strong emphasis", "**${1:bold}**", false },
            { "*italic*", "emphasis", "*${1:italic}*", false },
            { "~~struck~~", "struck through", "~~${1:struck}~~", false },
            { "==marked==", "highlighted text", "==${1:marked}==", false },
            { "`code`", "inline code", "`${1:code}`", false },
        } },
        { title = "Blocks and links", rows = {
            { "```lua", "code block; add the language", "```${1:lua}\n${2:code}\n```", true },
            { "| a | b |", "table; |---|---| under header",
                "| ${1:a} | ${2:b} |\n| --- | --- |\n| ${3:} | ${4:} |", true },
            { "[text](url)", "a link", "[${1:text}](${2:url})", false },
            { "[[note]]", "a link to another note", "[[${1:note}]]", false },
            { "$x^2$", "maths; $$ for a block", "\\$${1:x^2}\\$", false },
        } },
        { title = "Keys in a note", rows = {
            { "Enter", "next item; empty item stops" },
            { "o  O", "new item below / above" },
            { "Enter (normal)", "tick or untick a task" },
            { "Tab  S-Tab", "next / previous snippet field" },
            { "Esc", "end the snippet" },
            { "<leader>m", "hide this window" },
            { "<leader>M", "pick from this window" },
        } },
    }
end

---Lay the sections out as lines, remembering which byte ranges to colour and
---which lines can be inserted.
local function layout(buf)
    local lines, marks, by_line = {}, {}, {}
    local syntax_width = 0
    local groups = sections(buf)

    for _, group in ipairs(groups) do
        for _, row in ipairs(group.rows) do
            -- Rows with no meaning are lists, not column entries.
            if row[2] ~= "" then
                syntax_width = math.max(syntax_width, vim.fn.strdisplaywidth(row[1]))
            end
        end
    end

    for index, group in ipairs(groups) do
        if index > 1 then lines[#lines + 1] = "" end
        lines[#lines + 1] = " " .. group.title
        marks[#marks + 1] = { #lines - 1, 0, -1, "Title" }

        for _, row in ipairs(group.rows) do
            local syntax, meaning = row[1], row[2]
            local pad = string.rep(" ", math.max(1, syntax_width - vim.fn.strdisplaywidth(syntax) + 2))
            local line = "  " .. syntax .. (meaning ~= "" and (pad .. meaning) or "")
            lines[#lines + 1] = line
            marks[#marks + 1] = { #lines - 1, 2, 2 + #syntax, "Special" }
            if meaning ~= "" then
                marks[#marks + 1] = { #lines - 1, 2 + #syntax + #pad, #line, "Comment" }
            end
            if row[3] then
                by_line[#lines] = { snippet = row[3], block = row[4] == true }
            end
        end
    end

    return lines, marks, by_line
end

local function close()
    if float_win and vim.api.nvim_win_is_valid(float_win) then
        pcall(vim.api.nvim_win_close, float_win, true)
    end
    float_win = nil
end

---The note this window is docked to.
local function note_window()
    if not (float_win and vim.api.nvim_win_is_valid(float_win)) then return nil end
    local win = vim.api.nvim_win_get_config(float_win).win
    return win and vim.api.nvim_win_is_valid(win) and win or nil
end

---Step back out to the note and stop accepting focus, so <C-w>w and the mouse
---of habit pass over it again.
function M.leave()
    local note = note_window()
    if float_win and vim.api.nvim_win_is_valid(float_win) then
        vim.wo[float_win].cursorline = false
        pcall(vim.api.nvim_win_set_config, float_win, { focusable = false })
    end
    if note then pcall(vim.api.nvim_set_current_win, note) end
end

---Move to the next (or previous) line that can be inserted, skipping titles,
---blank lines and the information-only rows.
local function step(direction)
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local last = vim.api.nvim_buf_line_count(0)
    local at = row + direction
    while at >= 1 and at <= last do
        if entries[at] then
            vim.api.nvim_win_set_cursor(0, { at, 0 })
            return
        end
        at = at + direction
    end
end

---Put an entry into the note.
---
---A block goes on a line of its own -- below the current one unless that is
---blank -- and an inline entry goes at the cursor, after the character under it
---the way `a` would. Either way it is a snippet, so the fields are filled in
---with Tab, and Esc ends it.
---@param entry markdown.HintEntry
---@param win integer
local function insert(entry, win)
    vim.api.nvim_set_current_win(win)
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()

    if entry.block then
        if line:match("%S") then
            vim.api.nvim_buf_set_lines(0, row, row, false, { "" })
            vim.api.nvim_win_set_cursor(0, { row + 1, 0 })
        end
        vim.cmd("startinsert")
    else
        local at = #line > 0 and col + 1 or 0
        vim.api.nvim_win_set_cursor(0, { row, math.min(at, #line) })
        vim.cmd(at >= #line and "startinsert!" or "startinsert")
    end

    -- After the mode change has actually happened.
    vim.defer_fn(function() vim.snippet.expand(entry.snippet) end, 10)
end

function M.activate()
    local entry = entries[vim.api.nvim_win_get_cursor(0)[1]]
    local note = note_window()
    if not entry then
        vim.notify("That line is information only. Move to an entry with j/k.", vim.log.levels.INFO,
            { title = "Markdown hints" })
        return
    end
    if not note then return end

    M.leave()
    insert(entry, note)
end

local function attach_keys(buf)
    local function map(lhs, fn, desc)
        vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true, silent = true, desc = desc })
    end
    map("<CR>", M.activate, "Insert this entry into the note")
    for _, key in ipairs({ "j", "<Down>", "<C-n>" }) do map(key, function() step(1) end, "Next entry") end
    for _, key in ipairs({ "k", "<Up>", "<C-p>" }) do map(key, function() step(-1) end, "Previous entry") end
    map("q", M.leave, "Back to the note")
    map("<Esc>", M.leave, "Back to the note")
    map("<leader>m", function()
        M.leave()
        M.toggle()
    end, "Hide the hints")
end

---Dock the window to the top right of `target`, drawing it first if need be.
local function show_for(target)
    local source_buf = vim.api.nvim_win_get_buf(target)
    local target_width = vim.api.nvim_win_get_width(target)
    local target_height = vim.api.nvim_win_get_height(target)

    -- Too narrow to hold a cheat sheet without covering the note it is for.
    if target_width < min_width then
        close()
        return
    end

    local lines, marks, by_line = layout(source_buf)

    if not (float_buf and vim.api.nvim_buf_is_valid(float_buf)) then
        float_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[float_buf].bufhidden = "hide"
        vim.bo[float_buf].filetype = "markdown_hints"
        attach_keys(float_buf)
    end

    local full = #lines
    local height = math.min(full, math.max(3, target_height - 2))
    if height < full then
        lines = vim.list_slice(lines, 1, height)
        lines[height] = "  ... the window is too short to show it all"
    end

    -- Only what is actually on screen can be picked.
    entries = {}
    for lnum, entry in pairs(by_line) do
        if height >= full or lnum < height then entries[lnum] = entry end
    end

    local width = 0
    for _, line in ipairs(lines) do width = math.max(width, vim.fn.strdisplaywidth(line)) end
    width = math.min(width + 1, math.floor(target_width * 0.6))

    vim.bo[float_buf].modifiable = true
    vim.api.nvim_buf_set_lines(float_buf, 0, -1, false, lines)
    vim.bo[float_buf].modifiable = false

    vim.api.nvim_buf_clear_namespace(float_buf, ns, 0, -1)
    for _, mark in ipairs(marks) do
        if mark[1] < height then
            pcall(vim.api.nvim_buf_set_extmark, float_buf, ns, mark[1], mark[2], {
                end_col = mark[3] >= 0 and mark[3] or nil,
                hl_group = mark[4],
                hl_eol = mark[3] < 0,
            })
        end
    end

    local config = {
        relative = "win",
        win = target,
        anchor = "NE",
        row = 0,
        col = target_width,
        width = width,
        height = height,
        style = "minimal",
        border = "rounded",
        zindex = 40,
        noautocmd = true,
    }

    if float_win and vim.api.nvim_win_is_valid(float_win) then
        -- Re-docking keeps whatever focus state it has: stepping into the
        -- window must survive the resize event it can itself cause.
        vim.api.nvim_win_set_config(float_win, config)
    else
        config.focusable = false
        config.title = " Markdown "
        config.title_pos = "center"
        float_win = vim.api.nvim_open_win(float_buf, false, config)
        vim.wo[float_win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual"
        vim.wo[float_win].wrap = false
        vim.wo[float_win].cursorlineopt = "line"
    end
end

---Show the window for the window you are in, or put it away: the right thing
---for wherever focus has just landed.
function M.refresh()
    local win = vim.api.nvim_get_current_win()

    -- Focus inside some other float -- a picker, a prompt -- says nothing about
    -- which note this is for. Leave things as they are until it closes. That
    -- includes this window itself, once it has been stepped into.
    if vim.api.nvim_win_get_config(win).relative ~= "" then return end

    local buf = vim.api.nvim_win_get_buf(win)
    if enabled and vim.bo[buf].buftype == "" and vim.bo[buf].filetype == "markdown" then
        show_for(win)
    else
        close()
    end
end

function M.toggle()
    enabled = not enabled
    M.refresh()

    -- Asked for and nothing appeared is the worst answer: say why. It will
    -- appear by itself once there is room.
    if enabled and not (float_win and vim.api.nvim_win_is_valid(float_win)) then
        local win = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_get_width(win) < min_width then
            vim.notify(
                "This window is too narrow for the hints (needs " .. min_width .. " columns). "
                    .. "They will appear when there is room.",
                vim.log.levels.INFO,
                { title = "Markdown hints" }
            )
        end
    end
end

---Show the window if it is not already, and step into it.
function M.focus()
    -- Brought up to date here rather than trusted: the window follows focus a
    -- tick late, so a key pressed straight after arriving in a note finds it
    -- not yet docked.
    enabled = true
    M.refresh()

    if not (float_win and vim.api.nvim_win_is_valid(float_win)) then
        vim.notify(
            "This window is too narrow for the hints (needs " .. min_width .. " columns).",
            vim.log.levels.INFO,
            { title = "Markdown hints" }
        )
        return
    end

    vim.api.nvim_win_set_config(float_win, { focusable = true })
    vim.api.nvim_set_current_win(float_win)
    vim.wo[float_win].cursorline = true

    local first = math.huge
    for lnum in pairs(entries) do first = math.min(first, lnum) end
    if first < math.huge then vim.api.nvim_win_set_cursor(float_win, { first, 0 }) end
end

function M.enabled()
    return enabled
end

function M.setup()
    local group = vim.api.nvim_create_augroup("MarkdownHints", { clear = true })
    vim.api.nvim_create_autocmd(
        { "BufEnter", "WinEnter", "TabEnter", "FileType", "WinResized", "VimResized" },
        {
            group = group,
            callback = function() vim.schedule(M.refresh) end,
            desc = "Keep the Markdown hints beside the note being edited",
        }
    )
    -- Leaving the window any way other than the keys above -- <C-w>w, a click --
    -- puts it back out of reach of focus.
    vim.api.nvim_create_autocmd("WinLeave", {
        group = group,
        callback = function()
            if float_win and vim.api.nvim_get_current_win() == float_win then
                vim.wo[float_win].cursorline = false
                pcall(vim.api.nvim_win_set_config, float_win, { focusable = false })
            end
        end,
        desc = "Take focus back from the Markdown hints window",
    })
    vim.api.nvim_create_user_command("MarkdownHints", M.toggle, {
        desc = "Show or hide the Markdown note-taking hints",
    })
end

return M
