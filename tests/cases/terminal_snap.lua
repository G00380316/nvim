-- A run puts its prompt at the top of the terminal window, keeping earlier output above.
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("TerminalNew")
vim.wait(800)
local terminals = require("terminals")
local buf = terminals.list()[1]
local win = vim.fn.win_findbuf(buf)[1]
-- Plenty of earlier output, then scroll away from the end.
for i = 1, 40 do vim.fn.chansend(vim.b[buf].terminal_job_id, "echo old" .. i .. "\n") end
vim.wait(1500)
vim.api.nvim_win_set_cursor(win, { 1, 0 })

vim.cmd("wincmd k")
terminals.send("echo NEWRUN", { focus = false })
vim.wait(1200)
local top = vim.api.nvim_win_call(win, function() return vim.fn.line("w0") end)
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
local run_line
for i = #lines, 1, -1 do
    if lines[i]:find("echo NEWRUN", 1, true) then run_line = i break end
end
T.ok(run_line, "the command is in the buffer")
local expected = run_line
if lines[run_line - 1] and lines[run_line - 1]:match("^[~/]") then expected = run_line - 1 end
T.eq(top, expected, "the run's prompt is the first line shown")
-- Earlier output is still there, above.
local text = table.concat(lines, "\n")
T.ok(text:find("old1\n", 1, true) or text:find("old1 ", 1, true) or text:find("old1", 1, true), "earlier output is not cleared")
T.ok(run_line > 10, "and it sits above the run")
