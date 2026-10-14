-- A project's open files and cursor are saved and come back.
local root = vim.env.TEST_DIR .. "/proj"
local a = T.file("proj/a.lua", "one\ntwo\nthree\n")
local b = T.file("proj/b.lua", "x\ny\nz\n")
local workspace = require("workspace")
workspace.set(root, { exact = true })
vim.cmd("edit " .. a)
vim.api.nvim_win_set_cursor(0, { 2, 1 })
vim.cmd("edit " .. b)
vim.api.nvim_win_set_cursor(0, { 3, 0 })
vim.wait(200)

local sessions = require("sessions")
sessions.save()
local saved = sessions.for_root(workspace.get())
T.ok(saved, "a session was saved")
T.eq(#saved.files, 2, "both files are in it")
T.eq(vim.fn.resolve(saved.current), vim.fn.resolve(b), "the file you were in is marked")

-- Close everything, then restore.
vim.cmd("silent! %bwipeout!")
vim.wait(100)
sessions.restore(saved)
vim.wait(1500, function() return vim.fn.bufnr(a) > 0 and vim.fn.bufnr(b) > 0 end, 50)
T.ok(vim.fn.bufnr(a) > 0 and vim.fn.bufnr(b) > 0, "both files are open again")
T.eq(vim.fn.resolve(vim.api.nvim_buf_get_name(0)), vim.fn.resolve(b), "back in the file you were in")
T.eq(vim.api.nvim_win_get_cursor(0), { 3, 0 }, "with the cursor where it was")
