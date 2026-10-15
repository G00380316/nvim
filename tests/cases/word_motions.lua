-- w and b stop at _ and - by default, and WordJoin brings back whole identifiers.
local function keys_from(line, col, keys)
    vim.cmd("enew!")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, { line })
    vim.api.nvim_win_set_cursor(0, { 1, col })
    vim.cmd("normal! " .. keys)
    return vim.api.nvim_win_get_cursor(0)[2]
end
local text = "foo_bar-baz qux"

T.eq(require("word_motions").is_split(), true, "split by default")
-- foo(0-2) _(3) bar(4-6) -(7) baz(8-10) qux(12-14)
T.eq(keys_from(text, 0, "w"), 3, "w stops at the underscore")
T.eq(keys_from(text, 0, "ww"), 4, "then at bar")
T.eq(keys_from(text, 0, "wwww"), 8, "past the dash to baz")
T.eq(keys_from(text, 8, "b"), 7, "b goes back to the dash")
T.eq(keys_from(text, 4, "e"), 6, "e ends the segment, not the identifier")

vim.cmd("WordJoin")
T.eq(keys_from(text, 0, "w"), 12, "joined: w goes to the next whole word")
-- A filetype that adds - itself is still handled.
vim.cmd("WordSplit")
vim.cmd("enew!")
vim.bo.filetype = "css"
vim.wait(100)
T.ok(not vim.tbl_contains(vim.split(vim.bo.iskeyword, ",", { plain = true }), "-"), "css does not bring - back (" .. vim.bo.iskeyword .. ")")
