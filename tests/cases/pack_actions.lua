-- The plugin commands exist, list what is installed, and spot unused plugins.
for _, c in ipairs({ "PackUpdate", "PackUpdateNow", "PackStatus", "PackRestore", "PackUpdateOne", "PackList", "PackClean", "PackLockfile", "ParsersUpdate" }) do
    T.eq(vim.fn.exists(":" .. c), 2, c .. " exists")
end
local installed = #vim.pack.get(nil, { info = false })
T.ok(installed > 10, "plugins are installed (" .. installed .. ")")
T.eq(type(require("pack_actions").unused()), "table", "unused plugins can be listed")

local found = false
for _, item in ipairs(require("palette").items({})) do
    if item.group == "Plugin" and item.label == "Update plugins" then found = true end
end
T.ok(found, "plugin actions are in the palette")

-- Status runs offline without error.
T.eq(pcall(vim.cmd, "PackStatus"), true, "PackStatus opens")
