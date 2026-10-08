local M = {}

-- Enter in a Markdown list starts the next item, the way every note-taking
-- editor does: another bullet, the next number, another unchecked box. Enter on
-- an item with nothing in it ends the list instead.

-- The characters render-markdown draws as checkboxes: unchecked, checked, and
-- the common in-between states.
local box_chars = " xX%->~!/"

---@class markdown.ListItem
---@field next_prefix string what the following line starts with
---@field content string the text after the marker and checkbox
---@field prefix_len integer bytes of marker and checkbox at the start of the line

---@param line string
---@return markdown.ListItem?
local function parse(line)
    local indent, marker, gap, rest = line:match("^(%s*)([-*+])(%s+)(.*)$")
    local next_marker = marker

    if not marker then
        local number, delimiter
        indent, number, delimiter, gap, rest = line:match("^(%s*)(%d+)([.)])(%s+)(.*)$")
        if not number then return nil end
        next_marker = (tonumber(number) + 1) .. delimiter
    end

    local box, content = rest:match("^(%[[" .. box_chars .. "]%])%s*(.*)$")
    if not box then content = rest end

    return {
        next_prefix = indent .. next_marker .. gap .. (box and "[ ] " or ""),
        content = content,
        prefix_len = #line - #content,
    }
end

M.parse = parse

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

    -- lexima hands back key notation ("<CR>"), not key codes. Translated here
    -- because nothing downstream does it for us: a mapping that returns
    -- already-translated keys is the only form that behaves the same whether
    -- it is run directly or as blink.cmp's fallback.
    return vim.keycode(vim.fn["lexima#expand"]("<LT>CR>", "i"))
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
end

return M
