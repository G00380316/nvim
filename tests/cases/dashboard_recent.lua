-- workspace.recent returns most-recent first, which the dashboard relies on
-- when it drops the first entry (the workspace Neovim just opened into).
local ws = require("workspace")
local a, b, c = T.file("a/x"), T.file("b/x"), T.file("c/x")
for _, d in ipairs({ "a", "b", "c" }) do
    ws.set(vim.env.TEST_DIR .. "/" .. d, { exact = true })
end
local recent = ws.recent(3)
T.eq(#recent, 3, "three workspaces remembered")
T.eq(vim.fn.fnamemodify(recent[1], ":t"), "c", "most recent first")
T.eq(vim.fn.fnamemodify(recent[3], ":t"), "a", "oldest last")
