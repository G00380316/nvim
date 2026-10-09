-- Closing a terminal with the close key keeps you in the terminal section when another exists,
-- and goes back to the editor when it was the last.
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("TerminalNew")
vim.wait(800)
vim.cmd("TerminalNew")
vim.wait(800)
T.ok(#require("terminals").list() >= 2, "two terminals exist")

local first = vim.api.nvim_get_current_buf()
T.eq(vim.bo[first].filetype, "floaterm", "focused on a terminal")
vim.fn.maparg("<C-q>", "n", false, true).callback()
vim.wait(500)
T.ok(not vim.api.nvim_buf_is_valid(first), "the closed terminal is gone")
T.eq(vim.bo[vim.api.nvim_get_current_buf()].filetype, "floaterm", "focus stays on the remaining terminal")

vim.fn.maparg("<C-q>", "n", false, true).callback()
vim.wait(500)
T.ok(vim.bo[vim.api.nvim_get_current_buf()].filetype ~= "floaterm", "last terminal closed: focus returns to the editor")
