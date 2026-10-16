local M = {}

-- Enter in a Markdown list starts the next item, the way every note-taking
-- editor does: another bullet, the next number, another unchecked box. Enter on
-- an item with nothing in it ends the list instead.

-- The characters render-markdown draws as checkboxes: unchecked, checked, and
-- the common in-between states.
local box_chars = " xX%->~!/"

---@class markdown.ListItem
---@field indent string
---@field marker string the bullet or number as written
---@field gap string the whitespace between the marker and what follows
---@field box string? the checkbox as written, "[ ]" or "[x]"
---@field box_gap string whitespace between the checkbox and the text
---@field content string the text after the marker and checkbox
---@field prefix_len integer bytes of marker and checkbox at the start of the line
---@field own_prefix string what an item above this one starts with
---@field next_prefix string what the following line starts with

---@param line string
---@return markdown.ListItem?
local function parse(line)
    local indent, marker, gap, rest = line:match("^(%s*)([-*+])(%s+)(.*)$")
    local next_marker = marker

    if not marker then
        local number, delimiter
        indent, number, delimiter, gap, rest = line:match("^(%s*)(%d+)([.)])(%s+)(.*)$")
        if not number then return nil end
        marker = number .. delimiter
        next_marker = (tonumber(number) + 1) .. delimiter
    end

    local box, box_gap, content = rest:match("^(%[[" .. box_chars .. "]%])(%s*)(.*)$")
    if not box then
        box_gap, content = "", rest
    end

    return {
        indent = indent,
        marker = marker,
        gap = gap,
        box = box,
        box_gap = box_gap,
        content = content,
        prefix_len = #line - #content,
        own_prefix = indent .. marker .. gap .. (box and "[ ] " or ""),
        next_prefix = indent .. next_marker .. gap .. (box and "[ ] " or ""),
    }
end

M.parse = parse

---The list item a wrapped line belongs to: a line that is only the rest of an
---item's text, indented to line up under it. Found by looking up through the
---lines of the same item, stopping at a blank line or anything that is not text
---under that indent.
---@param row integer
---@return markdown.ListItem?
local function owner_of(row)
    local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if not line or not line:match("%S") or parse(line) then return nil end
    local indent = #line:match("^(%s*)")
    if indent == 0 then return nil end

    for up = row - 1, math.max(1, row - 40), -1 do
        local above = vim.api.nvim_buf_get_lines(0, up - 1, up, false)[1]
        if not above or not above:match("%S") then return nil end
        local item = parse(above)
        if item then
            -- Lined up under the item's text (or at least inside the item).
            if indent >= #item.indent + 1 and indent <= item.prefix_len then return item end
            return nil
        end
        if #above:match("^(%s*)") == 0 then return nil end
    end
    return nil
end

M.owner_of = owner_of

---Replace the current line's list syntax with nothing: the item was empty, so
---Enter on it is the way out of the list.
local function end_list(row)
    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { "" })
    vim.api.nvim_win_set_cursor(0, { row, 0 })
end

---Split the current line at the cursor and start the next item with the text
---that was after it.
function M.continue()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local line = vim.api.nvim_get_current_line()
    local item = parse(line)

    if not item then
        vim.api.nvim_feedkeys(vim.keycode("<CR>"), "n", false)
        return
    end

    if item.content:match("^%s*$") and col >= #line then
        end_list(row)
        return
    end

    local before = line:sub(1, col):gsub("%s+$", "")
    local after = line:sub(col + 1):gsub("^%s+", "")

    vim.api.nvim_buf_set_lines(0, row - 1, row, false, { before, item.next_prefix .. after })
    vim.api.nvim_win_set_cursor(0, { row + 1, #item.next_prefix })
end

---What <CR> should do right now. Answered as an expression so that every line
---that is not a list item keeps exactly what Enter did before -- lexima's
---handling of brackets and fences included.
local function enter()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]
    local item = parse(line)

    -- Only after the marker: Enter inside or before it is an ordinary Enter.
    if item and col >= item.prefix_len then
        return vim.keycode("<Cmd>lua require('markdown_lists').continue()<CR>")
    end

    -- The end of a line that was wrapped from a list item: the item is over, so
    -- Enter starts the next one rather than another line of the same text.
    if not item and col >= #line then
        local owner = owner_of(vim.api.nvim_win_get_cursor(0)[1])
        if owner then
            return vim.keycode("<Cmd>lua require('markdown_lists').next_after_wrapped()<CR>")
        end
    end

    -- lexima hands back key notation ("<CR>"), not key codes. Translated here
    -- because nothing downstream does it for us: a mapping that returns
    -- already-translated keys is the only form that behaves the same whether
    -- it is run directly or as blink.cmp's fallback.
    return vim.keycode(vim.fn["lexima#expand"]("<LT>CR>", "i"))
end

---Start the next item under a wrapped item's last line.
function M.next_after_wrapped()
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local owner = owner_of(row)
    if not owner then
        vim.api.nvim_feedkeys(vim.keycode("<CR>"), "n", false)
        return
    end
    vim.api.nvim_buf_set_lines(0, row, row, false, { owner.next_prefix })
    vim.api.nvim_win_set_cursor(0, { row + 1, #owner.next_prefix })
end

---Open a new item below (or above) the current one and start typing in it.
---@param above boolean
function M.open_item(above)
    local row = vim.api.nvim_win_get_cursor(0)[1]
    local item = parse(vim.api.nvim_get_current_line())
    -- On a line wrapped from an item, `o` starts the next item, `O` goes above this
    -- line (within the item), so only `o` looks up to the owner.
    if not item and not above then item = owner_of(row) end
    if not item then return end

    local prefix = above and item.own_prefix or item.next_prefix
    local at = above and row - 1 or row
    vim.api.nvim_buf_set_lines(0, at, at, false, { prefix })
    vim.api.nvim_win_set_cursor(0, { at + 1, #prefix })
    vim.cmd("startinsert!")
end

---The line with its checkbox flipped. A bullet that has none gains one, which
---is how a plain list becomes a checklist.
---@param line string
---@param force? "checked"|"unchecked" set rather than flip
---@return string? new nil if this is not a list item
local function toggled(line, force)
    local item = parse(line)
    if not item then return nil end

    local head = item.indent .. item.marker .. item.gap
    if not item.box then
        return head .. (force == "checked" and "[x] " or "[ ] ") .. item.content
    end

    -- Only x and X count as done. Any other state -- empty, or one of the
    -- in-between ones like [>] -- is ticked by toggling, rather than treated as
    -- done and cleared.
    local done = item.box:sub(2, 2):match("[xX]") ~= nil
    local checked
    if force then checked = force == "checked" else checked = not done end
    return head .. (checked and "[x]" or "[ ]") .. item.box_gap .. item.content
end

---Tick or untick the checkbox on each line of a range. With several lines they
---are set together -- all ticked unless every one already is -- instead of each
---being flipped on its own, which would swap a mixed selection around.
---@param first integer
---@param last integer
function M.toggle(first, last)
    first = first or vim.api.nvim_win_get_cursor(0)[1]
    last = last or first

    local lines = vim.api.nvim_buf_get_lines(0, first - 1, last, false)
    local force
    if last > first then
        local all_checked, any_item = true, false
        for _, line in ipairs(lines) do
            local item = parse(line)
            if item then
                any_item = true
                if not item.box or not item.box:sub(2, 2):match("[xX]") then all_checked = false end
            end
        end
        if not any_item then return end
        force = all_checked and "unchecked" or "checked"
    end

    for i, line in ipairs(lines) do
        lines[i] = toggled(line, force) or line
    end
    vim.api.nvim_buf_set_lines(0, first - 1, last, false, lines)
end

---@param buf integer
function M.attach(buf)
    vim.keymap.set("i", "<CR>", enter, {
        buffer = buf,
        expr = true,
        replace_keycodes = false,
        silent = true,
        desc = "Continue the Markdown list",
    })

    -- o and O are the same thing from normal mode. A count (3o) is native: it
    -- repeats typed text, which a prepared item would get wrong.
    for _, above in ipairs({ false, true }) do
        local key = above and "O" or "o"
        vim.keymap.set("n", key, function()
            if vim.v.count > 0 or not parse(vim.api.nvim_get_current_line()) then return key end
            return vim.keycode(string.format("<Cmd>lua require('markdown_lists').open_item(%s)<CR>", tostring(above)))
        end, {
            buffer = buf,
            expr = true,
            replace_keycodes = false,
            silent = true,
            desc = above and "Open a Markdown list item above" or "Open a Markdown list item below",
        })
    end

    -- Enter ticks the box on the line you are on. On a line that is not a list
    -- item it is the plain Enter it always was, which moves down.
    vim.keymap.set("n", "<CR>", function()
        if not parse(vim.api.nvim_get_current_line()) then return vim.keycode("<CR>") end
        return vim.keycode("<Cmd>lua require('markdown_lists').toggle()<CR>")
    end, {
        buffer = buf,
        expr = true,
        replace_keycodes = false,
        silent = true,
        desc = "Tick or untick the Markdown checkbox",
    })

    vim.keymap.set("x", "<CR>", function()
        local first, last = vim.fn.line("v"), vim.fn.line(".")
        if first > last then first, last = last, first end
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
        M.toggle(first, last)
    end, {
        buffer = buf,
        silent = true,
        desc = "Tick or untick every Markdown checkbox in the selection",
    })
end

return M
