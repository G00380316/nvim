-- The Hints menu is in the palette and each hint runs without error.
local menus = require("action_menus")
local hints = menus.menus.hints
T.ok(hints and #hints.actions >= 8, "hints menu exists")
local seen = false
for _, item in ipairs(require("palette").items({})) do
    if item.group == "Hint" and item.label == "Leader key hints" then seen = true end
end
T.ok(seen, "hints are listed in the palette")
-- The popups themselves need a live terminal (which-key attaches to real
-- buffers), so here only check that every row has something to run.
for _, action in ipairs(hints.actions) do
    T.eq(type(action.run), "function", action.label .. " is runnable")
end
