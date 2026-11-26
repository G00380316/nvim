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
