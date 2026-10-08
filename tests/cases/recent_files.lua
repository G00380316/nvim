-- The recent-files commands open a picker listing files from the history.
local f = T.file("proj/seen.txt", "x\n")
vim.cmd("edit " .. f)
vim.cmd("write")
vim.cmd("enew")
vim.cmd("RecentFilesAll")
vim.wait(1000)
local picker = Snacks.picker.get({ source = "recent" })[1]
T.ok(picker ~= nil, "recent picker opened")
if picker then picker:close() end
T.eq(vim.fn.exists(":RecentFiles"), 2, "project command exists")
