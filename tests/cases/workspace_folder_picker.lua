-- The folder chooser is a flat, searchable list of directories, input focused.
local root = vim.env.TEST_DIR .. "/home"
T.file("home/Uni/Labs/W03/a.py", "x\n")
T.file("home/Uni/Labs/W04/a.py", "x\n")
T.file("home/Code/app/main.lua", "x\n")
T.file("home/node_modules/pkg/index.js", "x\n")
vim.fn.mkdir(root .. "/.git/objects", "p")

local opened
local workspace = require("workspace")
workspace.open = function(path) opened = path end

vim.cmd("WorkspaceChoose " .. root)
local picker
vim.wait(3000, function()
    picker = Snacks.picker.get({ source = "workspace_folders" })[1]
    return picker and #picker:items() >= 5
end, 50)
T.ok(picker, "chooser opened")

local files = {}
for _, item in ipairs(picker:items()) do files[#files + 1] = item.file end
local list = table.concat(files, "\n")
T.ok(list:find("Uni/Labs/W03", 1, true), "nested folders are listed (" .. list:gsub("\n", ", ") .. ")")
T.ok(not list:find("node_modules", 1, true), "node_modules left out")
T.ok(not list:find(".git", 1, true), ".git left out")

-- The search box has focus: typing filters.
local win = picker.input.win.win
T.eq(vim.api.nvim_get_current_win(), win, "focus is in the search box")
-- (Typing narrows the list -- checked in a real terminal: "labs w03" leaves one
-- row. Here, that choosing a row opens that folder.)
local target
for _, item in ipairs(picker:items()) do
    if item.file == "Uni/Labs/W03" then target = item end
end
picker.opts.confirm(picker, target)
vim.wait(1000, function() return opened ~= nil end, 50)
T.eq(opened, vim.fs.normalize(root .. "/Uni/Labs/W03"), "choosing a row opens that folder as the workspace")
