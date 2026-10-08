-- An unmodified buffer picks up a change made on disk without asking.
local path = T.file("r.txt", "one\n")
vim.cmd("edit " .. path)
vim.wait(1100) -- mtime has one-second resolution
T.file("r.txt", "two\n")
vim.api.nvim_exec_autocmds("FocusGained", {})
vim.wait(500)
T.eq(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "two" }, "buffer reloaded")
