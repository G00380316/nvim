-- <C-f> and friends search every open workspace when the file is in one, the file's folder when it is in none;
-- the palette has "all" and "current" explicitly.
local a = vim.env.TEST_DIR .. "/wsA"
local b = vim.env.TEST_DIR .. "/wsB"
local outside = vim.fn.tempname() .. "/proj" -- not under any open workspace
T.file("wsA/a.txt", "a\n"); T.file("wsB/b.txt", "b\n"); vim.fn.mkdir(outside, "p"); vim.fn.writefile({ "o" }, outside .. "/o.txt")
vim.fn.mkdir(a .. "/.git", "p"); vim.fn.mkdir(b .. "/.git", "p"); vim.fn.mkdir(outside .. "/.git", "p")

local workspace = require("workspace")
local scope = require("search_scope")
local function real(list)
    local out = {}
    for _, p in ipairs(list) do out[#out + 1] = vim.fn.resolve(p) end
    table.sort(out)
    return out
end

-- Two open workspaces (a tab each); A is current.
workspace.open(a, { exact = true })
workspace.open(b, { exact = true })
workspace.open(a, { exact = true })
vim.wait(300)
local function has(list, path)
    return vim.tbl_contains(real(list), vim.fn.resolve(path))
end
T.ok(has(workspace.open_roots(), a) and has(workspace.open_roots(), b), "both workspaces are open")

-- In a file of workspace B while A is current: smart = both.
vim.cmd("edit " .. b .. "/b.txt")
local dirs = scope.dirs("smart")
T.ok(has(dirs, a) and has(dirs, b), "a file in an open workspace: every open workspace is searched")

-- Explicit scopes.
T.ok(has(scope.dirs("all"), a) and has(scope.dirs("all"), b), "all: both")
T.eq(real(scope.dirs("current")), real({ a }), "current: only the current workspace")

-- A file that lives in no open workspace: its own folder.
vim.cmd("edit " .. outside .. "/o.txt")
T.eq(real(scope.dirs("smart")), real({ outside }), "a file in no open workspace: its own folder")
T.ok(has(scope.dirs("all"), a) and has(scope.dirs("all"), b), "all is still every open workspace from there")
