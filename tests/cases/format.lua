-- Which formatter a web file gets: Biome when the project has biome.json, else
-- Prettier, the project's own copy first.
local format = require("format")

local root = vim.fn.tempname()
vim.fn.mkdir(root .. "/src", "p")
vim.fn.mkdir(root .. "/node_modules/.bin", "p")
for _, name in ipairs({ "prettier", "biome" }) do
    local f = io.open(root .. "/node_modules/.bin/" .. name, "w")
    f:write("#!/bin/sh\n")
    f:close()
end

local file = root .. "/src/a.tsx"
local command, name = format.command_for(file)
T.eq(name, "prettier", "no biome.json: prettier")
T.ok(command[1]:find("node_modules/.bin/prettier", 1, true) ~= nil, "the project's own prettier")
T.eq(command[2], "--stdin-filepath", "text goes in on stdin")

local f = io.open(root .. "/biome.json", "w")
f:write("{}")
f:close()
command, name = format.command_for(file)
T.eq(name, "biome", "biome.json: biome")
T.eq(command[2], "format", "biome format")
vim.fn.delete(root, "rf")

-- Python goes to Ruff, reading the project's own settings.
if vim.fn.executable("ruff") == 1 then
    local py = vim.fn.tempname() .. ".py"
    vim.fn.writefile({ "x=1" }, py)
    vim.cmd("edit " .. py)
    command, name = format.command_for(py)
    T.eq(name, "ruff", "python: ruff")
    T.eq(command[2], "format", "ruff format")
    vim.cmd("bwipeout!")
end

-- Lua goes to StyLua and shell to shfmt, when they are installed.
local bindir = vim.fn.tempname()
vim.fn.mkdir(bindir, "p")
for _, tool in ipairs({ "stylua", "shfmt" }) do
    local path = bindir .. "/" .. tool
    vim.fn.writefile({ "#!/bin/sh" }, path)
    vim.fn.setfperm(path, "rwxr-xr-x")
end
local saved_path = vim.env.PATH
vim.env.PATH = bindir .. ":" .. saved_path
command, name = format.command_for("/somewhere/x.lua")
T.eq(name, "stylua", "lua: stylua")
T.eq(command[#command], "-", "stylua reads stdin")
command, name = format.command_for("/somewhere/x.sh")
T.eq(name, "shfmt", "shell: shfmt")
vim.env.PATH = saved_path
vim.fn.delete(bindir, "rf")
