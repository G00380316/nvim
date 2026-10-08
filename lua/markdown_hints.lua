local M = {}

-- A cheat sheet for taking notes, docked beside the note rather than opened over
-- it. It never takes focus, so it can stay up while you type, and it follows you:
-- it is there for a Markdown buffer and gone for anything else, and comes back
-- when you return. Toggled with <leader>m in a Markdown buffer.
--
-- What it lists is what render-markdown is set up to draw, read from the live
-- configuration where that is cheap -- the callout types, the extra checkbox
-- states -- so it cannot drift from what the buffer actually renders.

local ns = vim.api.nvim_create_namespace("markdown_hints")
local enabled = false
local float_buf, float_win

-- The callouts worth reaching for in notes, most useful first. Only those the
-- configuration actually renders are shown.
local min_width = 70

local favourite_callouts = {
    "NOTE", "TIP", "IMPORTANT", "WARNING", "CAUTION", "TODO", "QUESTION", "EXAMPLE", "BUG",
}

local function render_config(buf)
    local ok, state = pcall(require, "render-markdown.state")
    if not ok then return nil end
    local got, cfg = pcall(state.get, buf)
    return got and cfg or nil
end

---@return { title: string, rows: string[][] }[]
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
        { "- [ ] task", "an open task" },
        { "- [x] task", "a finished one" },
    }
    for _, c in ipairs(custom) do
        tasks[#tasks + 1] = { "- " .. c[2] .. " task", c[1] }
    end

    -- The callout names as short rows: one long row is wider than everything
    -- else together, and then the whole window has to be.
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
            { "# Heading", "## to ###### for smaller" },
            { "---", "a divider line" },
            { "> quote", "a block quote" },
            { "> [!NOTE]", "a callout box" },
        } },
        { title = "Callout types", rows = callout_rows },
        { title = "Lists and tasks", rows = vim.list_extend({
            { "- item", "or * item, 1. item" },
        }, tasks) },
        { title = "Text", rows = {
            { "**bold**", "*italic*   ~~struck~~" },
            { "==marked==", "highlighted text" },
            { "`code`", "inline code" },
        } },
        { title = "Blocks and links", rows = {
            { "```lua", "code block; add the language" },
            { "| a | b |", "table; |---|---| under header" },
            { "[text](url)", "a link" },
            { "[[note]]", "a link to another note" },
            { "$x^2$", "maths; $$ for a block" },
        } },
        { title = "Keys in a note", rows = {
            { "Enter", "next item; empty item stops" },
            { "o  O", "new item below / above" },
            { "Enter (normal)", "tick or untick a task" },
            { "Tab  S-Tab", "next / previous snippet field" },
            { "Esc", "end the snippet" },
            { "<leader>m", "hide this window" },
        } },
    }
end

---Lay the sections out as lines, remembering which byte ranges to colour.
local function layout(buf)
    local lines, marks = {}, {}
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
        end
    end

    return lines, marks
end

local function close()
    if float_win and vim.api.nvim_win_is_valid(float_win) then
        pcall(vim.api.nvim_win_close, float_win, true)
    end
    float_win = nil
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

    local lines, marks = layout(source_buf)

    if not (float_buf and vim.api.nvim_buf_is_valid(float_buf)) then
        float_buf = vim.api.nvim_create_buf(false, true)
        vim.bo[float_buf].bufhidden = "hide"
        vim.bo[float_buf].filetype = "markdown_hints"
    end

    local height = math.min(#lines, math.max(3, target_height - 2))
    if height < #lines then
        lines = vim.list_slice(lines, 1, height)
        lines[height] = "  ... the window is too short to show it all"
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
        focusable = false,
        zindex = 40,
        noautocmd = true,
    }

    if float_win and vim.api.nvim_win_is_valid(float_win) then
        vim.api.nvim_win_set_config(float_win, config)
    else
        config.title = " Markdown "
        config.title_pos = "center"
        float_win = vim.api.nvim_open_win(float_buf, false, config)
        vim.wo[float_win].winhighlight = "NormalFloat:NormalFloat,FloatBorder:FloatBorder"
        vim.wo[float_win].wrap = false
    end
end

---Show the window for the window you are in, or put it away: the right thing
---for wherever focus has just landed.
function M.refresh()
    local win = vim.api.nvim_get_current_win()

    -- Focus inside some other float -- a picker, a prompt -- says nothing about
    -- which note this is for. Leave things as they are until it closes.
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
    vim.api.nvim_create_user_command("MarkdownHints", M.toggle, {
        desc = "Show or hide the Markdown note-taking hints",
    })
end

return M
