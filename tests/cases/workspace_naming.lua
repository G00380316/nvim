-- One word for the thing: "Workspace". The switcher is in the palette.
local palette = require("palette")
local found_switch, project_group = false, {}
for _, item in ipairs(palette.items({})) do
    if item.group == "Workspace" and item.label == "Switch workspace" then found_switch = true end
    if item.group == "Project" then project_group[#project_group + 1] = item.label end
end
T.ok(found_switch, "Switch workspace is in the palette")
T.eq(project_group, {}, "no palette rows are left in a \"Project\" group")
T.eq(vim.fn.exists(":WorkspaceSwitch"), 2, "the switcher is a command")
T.ok(not require("action_menus").menus.session.actions[1].detail:find("project", 1, true), "session menu says workspace")
