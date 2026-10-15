-- The explorer is never entered in insert mode, stray text does not block it, and <BS> is plain.
vim.cmd("edit " .. T.file("proj/a.txt", "x\n"))
vim.cmd("FocusTree")
vim.wait(500)
local oil_buf = vim.api.nvim_get_current_buf()
T.eq(vim.bo[oil_buf].filetype, "oil", "in the explorer")

-- Insert mode on arrival is ended.
vim.cmd("wincmd l")
vim.cmd("startinsert")
vim.wait(100)
vim.cmd("FocusTree")
vim.wait(300)
T.ok(vim.fn.mode():sub(1, 1) ~= "i", "the explorer is not left in insert mode (mode " .. vim.fn.mode() .. ")")

-- Stray text leaves the buffer modified; switching the folder still works.
vim.api.nvim_buf_set_lines(oil_buf, -1, -1, false, { "ge" })
T.eq(vim.bo[oil_buf].modified, true, "the explorer buffer is modified by stray text")
local other = T.file("other/b.txt", "y\n")
local ok = pcall(function() require("workspace").set(vim.fn.fnamemodify(other, ":h"), { exact = true }) end)
T.ok(ok, "switching the workspace does not fail on a modified explorer")

-- <BS> is no longer a command in normal mode.
local global_bs
for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
    if m.lhs == "<BS>" then global_bs = m end
end
T.eq(global_bs, nil, "<BS> has no global mapping in normal mode")
