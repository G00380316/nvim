-- Sending a command scrolls a terminal that was scrolled up back to the end.
vim.cmd("edit " .. T.file("a.py", "print(1)\n"))
local terminals = require("terminals")
vim.cmd("TerminalNew")
vim.wait(800)
local buf = terminals.list()[1]
for i = 1, 60 do vim.fn.chansend(vim.b[buf].terminal_job_id, "echo line" .. i .. "\n") end
vim.wait(1500)
local win = vim.fn.win_findbuf(buf)[1]
vim.api.nvim_win_set_cursor(win, { 1, 0 })
T.eq(vim.api.nvim_win_get_cursor(win)[1], 1, "scrolled to the top")

vim.cmd("wincmd k")
terminals.send("echo AFTER", { focus = false })
vim.wait(1000)
local last = vim.api.nvim_buf_line_count(buf)
T.ok(vim.api.nvim_win_get_cursor(win)[1] >= last - 3, "cursor back at the end (" .. vim.api.nvim_win_get_cursor(win)[1] .. " of " .. last .. ")")
