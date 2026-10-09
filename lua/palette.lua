local M = {}

-- One searchable list of everything this config can do, so the question is
-- "what do I type", not "which selector holds it".
--
-- It owns no actions. It is assembled, in the order they should rank, from
-- what already exists:
--
--   1. the curated guide (<leader>k) -- the keys worth knowing;
--   2. every row of every action selector, flattened -- build, test, stage a
--      hunk, open the SSH launcher, without first opening that selector;
--   3. project management, which is commands rather than keys;
--   4. every other :command that takes no arguments, for the long tail.
--
-- Running a row goes through the code that already runs it (the guide's
-- activate, the selectors' run_action), so picking something here behaves
-- exactly as picking it from its own list does.

local project_actions = {
    { "Name this project", "Give the current project a name, or clear it", "WorkspaceAlias" },
    { "Close this project", "Close its tab, splits and terminals; keep it listed", "WorkspaceClose" },
    { "Forget this project", "Remove it from the project list; the folder stays", "WorkspaceForget" },
    { "Show project folder", "Print where the current project lives", "WorkspaceRoot" },
    -- Takes an optional file, so the scan for argument-free commands skips it.
    { "Import a document as a note", "A PDF, Word file, web page or image becomes Markdown", "NoteImport", "Notes" },
    { "Show note hints", "The Markdown cheat sheet beside the note", "MarkdownHints", "Notes" },
    { "Mobile device hub", "Boot, run and watch simulators and emulators", "MobileDevices", "Tools" },
}

-- Where the palette was opened decides what comes first. Opened from the
-- explorer, the file and project actions lead; from a terminal, the terminal
-- ones; in a note, the note-taking ones. Everything else stays below, in its
-- usual order, so nothing is hidden -- only moved. A row ranks by the first of
-- its group or label to match; earlier entries rank higher.
local relevance = {
    oil = {
        groups = { "File", "Project", "Search", "Buffers" },
        labels = { "xplorer", "Extract", "Reveal", "default app", "Recent", "folder", "project", "workspace" },
    },
    terminal = {
        groups = { "Terminal", "Run" },
        labels = { "terminal", "shell" },
    },
    notebook = {
        groups = { "Notebook", "Markdown", "Run" },
        labels = { "notebook", "cell", "kernel" },
    },
    markdown = {
        groups = { "Markdown", "Notes", "Edit" },
        labels = { "note", "checkbox", "hint", "import", "surround" },
    },
    quickfix = {
        groups = { "Search", "Problems" },
        labels = { "result", "quickfix", "problem" },
    },
    code = {
        groups = { "Code", "Edit", "Run", "Git", "Debug" },
        labels = {},
    },
}

---What the palette was opened from, as a key of `relevance`.
local function context_kind(context)
    local win = context and context.win
    if not (win and vim.api.nvim_win_is_valid(win)) then return nil end

    local ok, layout = pcall(require, "ide_layout")
    local panel = ok and layout.panel_kind(win) or nil
    if panel == "oil" then return "oil" end
    if panel == "terminal" then return "terminal" end
    if panel == "quickfix" then return "quickfix" end
    if panel then return nil end

    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_name(buf):match("%.ipynb$") then return "notebook" end
    local filetype = vim.bo[buf].filetype
    if filetype == "markdown" or filetype == "text" then return "markdown" end
    if filetype == "" or filetype == "snacks_dashboard" then return nil end
    return "code"
end

---Move the rows that matter here to the top, keeping the rest in order.
local function rank_for(items, context)
    local rules = relevance[context_kind(context) or ""]
    if not rules then return items end

    local function score(item)
        local best = math.huge
        for i, group in ipairs(rules.groups) do
            if item.group == group then best = math.min(best, i) end
        end
        for i, needle in ipairs(rules.labels) do
            if item.label:find(needle, 1, true) then best = math.min(best, i + 0.5) end
        end
        return best
    end

    local ranked = {}
    for index, item in ipairs(items) do
        ranked[#ranked + 1] = { item = item, index = index, score = score(item) }
    end
    table.sort(ranked, function(a, b)
        if a.score ~= b.score then return a.score < b.score end
        return a.index < b.index
    end)
    return vim.tbl_map(function(r) return r.item end, ranked)
end

M.context_kind = context_kind
M.rank_for = rank_for

local function build(context)
    local items = {}
    local seen = {}

    -- The guide and a selector sometimes both describe the same thing -- the
    -- debug stepping keys are in each. The first to arrive wins, and the
    -- guide arrives first, which is the one that shows the key.
    local function add(item)
        local id = item.group:lower() .. "|" .. item.label:lower()
        if seen[id] then return end
        seen[id] = true

        item.text = table.concat({ item.group, item.label, item.key or "", item.detail or "" }, " ")
        items[#items + 1] = item
    end

    local menus = require("action_menus")

    for _, row in ipairs(require("workflow_keymaps").items()) do
        -- The selector openers are redundant here: their contents are listed
        -- directly below. The switcher keys only work inside the switcher.
        if row.mode ~= "switcher" and not row.desc:match("selector") then
            add({
                group = row.group,
                label = row.desc,
                key = row.lhs,
                run = function() require("workflow_keymaps").activate(row, context) end,
            })
        end
    end

    local names = vim.tbl_keys(menus.menus)
    table.sort(names)
    for _, name in ipairs(names) do
        local menu = menus.menus[name]
        local group = menu.title:gsub("%s*Actions$", "")
        for _, action in ipairs(menu.actions) do
            add({
                group = group,
                label = action.label,
                detail = action.detail,
                key = menu.lhs,
                run = function() menus.run_action(menu, action, context) end,
            })
        end
    end

    -- A tool with no key of its own is one row here that opens its whole menu,
    -- so browsing what it can do is "Tools", Enter. Its individual actions are
    -- listed above too, for when you already know what you want.
    for _, name in ipairs(names) do
        local menu = menus.menus[name]
        if not menu.lhs then
            add({
                group = "Tools",
                label = menu.title,
                detail = "Browse everything it can do",
                run = function() menus.open(name) end,
            })
        end
    end

    for _, recipe in ipairs(require("recipes").items()) do add(recipe) end

    for _, entry in ipairs(project_actions) do
        menus.covered_commands[entry[3]] = true
        add({
            group = entry[4] or "Project",
            label = entry[1],
            detail = entry[2],
            run = function() vim.cmd(entry[3]) end,
        })
    end

    local commands = {}
    for cmd, definition in pairs(vim.api.nvim_get_commands({ builtin = false })) do
        -- Only the ones that can be run as they stand. A command that wants an
        -- argument would ask for one in the cmdline, which is not a palette.
        if definition.nargs == "0" and not menus.covered_commands[cmd] then
            commands[#commands + 1] = { cmd, definition.definition }
        end
    end
    table.sort(commands, function(a, b) return a[1] < b[1] end)

    for _, entry in ipairs(commands) do
        local command = entry[1]
        local detail = entry[2]
        add({
            group = "Command",
            label = command,
            detail = (detail and detail ~= "" and not detail:match("^[%s:]*$")) and detail or nil,
            key = ":" .. command,
            run = function() vim.cmd(command) end,
        })
    end

    return rank_for(items, context)
end

---Everything the palette would list, for checking and for other tools.
function M.items(context)
    return build(context or {})
end

local function open_picker(context, pattern)
    local Snacks = require("snacks")

    Snacks.picker.pick({
        title = "Command Palette  \u{b7}  type what you want  \u{b7}  Ctrl-Q closes",
        items = build(context),
        pattern = pattern,
        preview = false,
        layout = { preset = "vscode" },
        format = function(item)
            local align = Snacks.picker.util.align
            local row = {
                { align(item.group, 12), "SnacksPickerLabel" },
                { "  " },
                { align(item.label, 40), "SnacksPickerFile" },
            }
            if item.key then
                row[#row + 1] = { "  " }
                row[#row + 1] = { align(item.key, 14), "SnacksPickerKeymapLhs" }
            end
            if item.detail then
                row[#row + 1] = { "  " }
                row[#row + 1] = { item.detail, "SnacksPickerDesc" }
            end
            return row
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end

            vim.schedule(function()
                local ok, err = pcall(item.run)
                if not ok then
                    vim.notify(tostring(err), vim.log.levels.ERROR, { title = "Command Palette" })
                end
            end)
        end,
    })
end

---@param pattern? string search text to start with
function M.open(pattern)
    local context = require("workflow_keymaps").capture_context()
    vim.schedule(function() open_picker(context, pattern) end)
end

return M
