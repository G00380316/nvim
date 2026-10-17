-- The folder the explorer is in is first in the folder list.
local root = vim.env.TEST_DIR .. "/home"
T.file("home/aaa/x.txt", "x\n")
T.file("home/zzz/deep/y.txt", "y\n")
vim.cmd("edit " .. T.file("home/zzz/deep/main.txt", "m\n"))
vim.cmd("FocusTree")
vim.wait(500)
local oil = require("oil")
oil.open(root .. "/zzz/deep")
vim.wait(700)
T.eq(require("folder_picker").explorer_dir(), vim.fs.normalize(vim.fn.resolve(root .. "/zzz/deep")), "the explorer's folder is known")

local chosen
require("folder_picker").pick({ root = root, title = "Test", confirm = function(path) chosen = path end })
local picker
vim.wait(3000, function()
    picker = Snacks.picker.get({ source = "folders" })[1]
    return picker and #picker:items() >= 3
end, 50)
T.ok(picker, "the list opened")
local items = picker:items()
T.ok(items[1].current, "the first row is the explorer's folder")
T.eq(vim.fn.resolve(items[1].abs), vim.fn.resolve(root .. "/zzz/deep"), "and it is the right one")
local count = 0
for _, item in ipairs(items) do
    if item.abs == items[1].abs or vim.fn.resolve(root .. "/" .. (item.file or "")) == vim.fn.resolve(items[1].abs) then count = count + 1 end
end
T.eq(count, 1, "it is not listed twice")

picker.opts.confirm(picker, items[1])
vim.wait(500, function() return chosen ~= nil end, 50)
T.eq(vim.fn.resolve(chosen), vim.fn.resolve(root .. "/zzz/deep"), "choosing it gives that folder")
