-- Jumping the explorer to a folder opens it in the same explorer window.
local root = vim.env.TEST_DIR .. "/proj"
T.file("proj/src/deep/inner/a.txt", "x\n")
T.file("proj/docs/b.txt", "y\n")
vim.cmd("edit " .. T.file("proj/main.txt", "m\n"))
require("workspace").set(root, { exact = true })
vim.cmd("FocusTree")
vim.wait(500)
local oil_win = vim.api.nvim_get_current_win()
T.eq(vim.bo.filetype, "oil", "in the explorer")
local gf = vim.fn.maparg("gf", "n", false, true)
T.ok(gf.buffer == 1 and gf.callback, "gf is bound in the explorer")

vim.cmd("FolderJump")
local picker
vim.wait(3000, function()
    picker = Snacks.picker.get({ source = "folders" })[1]
    return picker and #picker:items() >= 3
end, 50)
T.ok(picker, "the folder search opened")

local target
for _, item in ipairs(picker:items()) do
    if item.file == "src/deep/inner" then target = item end
end
T.ok(target, "a nested folder is listed")
picker.opts.confirm(picker, target)
vim.wait(1500, function()
    return (require("oil").get_current_dir(vim.api.nvim_win_get_buf(oil_win)) or ""):find("inner", 1, true) ~= nil
end, 50)
local dir = require("oil").get_current_dir(vim.api.nvim_win_get_buf(oil_win))
T.ok(dir and dir:find("src/deep/inner", 1, true), "that folder is open in the same explorer window (" .. tostring(dir) .. ")")
T.eq(#vim.tbl_filter(function(w) return vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "oil" end, vim.api.nvim_tabpage_list_wins(0)), 1, "still one explorer")
