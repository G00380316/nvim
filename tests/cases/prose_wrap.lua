-- Typing past the ruler: lists, tasks, quotes continue; headings, tables, code and fences do not break.
local words = {}
for i = 1, 30 do words[#words + 1] = "word" .. i end
local text = table.concat(words, " ") -- about 220 columns

local function type_line(filetype, prefix, body, before)
    vim.cmd("enew!")
    vim.bo.filetype = filetype
    vim.wait(60) -- the ruler gives the window its width a moment after it opens
    local lines = before or {}
    lines[#lines + 1] = prefix
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { #lines, #prefix })
    vim.cmd("normal! A" .. body)
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end
local function longest(lines)
    local n = 0
    for _, l in ipairs(lines) do n = math.max(n, #l) end
    return n
end

-- The ruler is on at 80 to begin with.
require("ruler").state()
local out

out = type_line("markdown", "- ", text)
T.ok(#out > 1 and longest(out) <= 80, "a bullet wraps at the ruler")
T.ok(out[2]:match("^  %S") and not out[2]:match("^%s*[-*]"), "the next line lines up under the text, no new bullet")

out = type_line("markdown", "- [ ] ", text)
T.ok(out[2]:match("^      %S"), "a task's next line lines up under its text, past the box (" .. out[2]:sub(1, 12) .. ")")

out = type_line("markdown", "1. ", text)
T.ok(out[2]:match("^   %S"), "a numbered item's next line lines up under the text")

out = type_line("markdown", "> ", text)
T.ok(out[2]:match("^> %S"), "a quote carries its > on")

out = type_line("markdown", "  - ", text)
T.ok(out[2]:match("^    %S"), "a nested item keeps its depth")

out = type_line("markdown", "## ", text)
T.eq(#out, 1, "a heading is never broken")

out = type_line("markdown", "| ", text .. "")
T.eq(#out, 1, "a table row is never broken")

out = type_line("markdown", "", text, { "```python" })
T.eq(#out, 2, "inside a code fence nothing is broken")

out = type_line("jupyter", "- ", text)
T.ok(#out > 1 and out[2]:match("^  %S"), "notebook prose wraps like notes")

out = type_line("gitcommit", "", text, { "subject line stays whole " .. text })
T.ok(#out >= 2 and #out[1] > 100, "the commit subject is not broken")

out = type_line("lua", "-- ", text)
T.ok(#out > 1 and out[2]:match("^%-%- "), "a code comment wraps and carries its leader")

out = type_line("lua", "local x = ", "alpha_beta + " .. text:gsub(" ", "_"))
T.eq(#out, 1, "a line of code is never broken")

-- Turned off with the ruler.
vim.cmd("RulerToggle")
out = type_line("markdown", "- ", text)
T.eq(#out, 1, "with the ruler off, nothing wraps")
vim.cmd("RulerToggle")

-- Enter at the end of a wrapped item starts the next item (the note carries on).
local lists = require("markdown_lists")
local function after_wrapped(lines)
    vim.cmd("enew!")
    vim.bo.filetype = "markdown"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { #lines, #lines[#lines] })
    lists.next_after_wrapped()
    return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

T.eq(after_wrapped({ "- [ ] alpha beta", "      gamma delta" })[3], "- [ ] ", "a task carries on as a new task")
T.eq(after_wrapped({ "3. one two", "   three four" })[3], "4. ", "a numbered item carries on with the next number")
T.eq(after_wrapped({ "  - a b", "    c d" })[3], "  - ", "a nested bullet keeps its depth")
T.eq(after_wrapped({ "> not a list", "  more" })[3], nil, "something that is not a list item is left to plain Enter")

vim.cmd("enew!")
vim.bo.filetype = "markdown"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- item", "", "  separate paragraph" })
T.eq(lists.owner_of(3), nil, "a blank line ends the item")

-- And Enter, as mapped, chooses that path on a wrapped line and a plain Enter elsewhere.
vim.cmd("enew!")
vim.bo.filetype = "markdown"
vim.api.nvim_buf_set_lines(0, 0, -1, false, { "- alpha beta", "  gamma delta" })
vim.api.nvim_win_set_cursor(0, { 2, 12 })
vim.cmd("startinsert!") -- insert mode, cursor after the last character
vim.wait(100)
local enter = vim.fn.maparg("<CR>", "i", false, true).callback
T.ok(enter and enter():find("next_after_wrapped", 1, true), "Enter at the end of a wrapped line starts the next item")

vim.cmd("stopinsert")
