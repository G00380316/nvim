-- :RecentFiles opens a picker listing files from the history.
local f = T.file("proj/seen.txt", "x\n")
vim.cmd("edit " .. f)
vim.cmd("write")
vim.cmd("enew")
vim.cmd("RecentFiles")
vim.wait(1000)
local picker = Snacks.picker.get({ source = "recent" })[1]
T.ok(picker ~= nil, "recent picker opened")
if picker then picker:close() end
