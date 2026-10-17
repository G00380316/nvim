---Where a file or text search looks.
---
---  "smart"   (<C-f>, <C-g>, <leader>l) -- if the file you are in belongs to an
---            open workspace, every open workspace; if it belongs to none (a file
---            opened from elsewhere), the folder it lives in, so you can look
---            around where it actually is.
---  "all"     every open workspace, whatever file you are in.
---  "current" only the workspace marked current, whatever file you are in.
local M = {}

local function inside(root, path)
    return path == root or path:sub(1, #root + 1) == root .. "/"
end

---The folders to search for a scope.
---@param scope "smart"|"all"|"current"
---@return string[] dirs, string title
function M.dirs(scope)
    local workspace = require("workspace")
    local current = vim.fs.normalize(workspace.get())
    local roots = workspace.open_roots()

    if scope == "current" then
        return { current }, workspace.label(current)
    end

    if scope == "smart" then
        local context = vim.fs.normalize(workspace.context())
        local belongs = false
        for _, root in ipairs(roots) do
            if inside(root, context) then belongs = true break end
        end
        -- A file that lives in no open workspace keeps its own folder as the scope.
        if not belongs then return { context }, workspace.label(context) end
    end

    local title = #roots == 1 and workspace.label(roots[1]) or ("all %d workspaces"):format(#roots)
    return roots, title
end

---A row's usual look with its workspace's name on the end, when more than one
---workspace is being searched, so you can tell where a result lives.
local function tagged(dirs)
    if #dirs < 2 then return nil end
    local workspace = require("workspace")
    return function(item, picker)
        local parts = Snacks.picker.format.file(item, picker)
        local ok, path = pcall(Snacks.picker.util.path, item)
        if ok and path then
            path = vim.fs.normalize(path)
            for _, root in ipairs(dirs) do
                if inside(vim.fs.normalize(root), path) then
                    parts[#parts + 1] = { "  " .. workspace.label(root), "Special" }
                    break
                end
            end
        end
        return parts
    end
end

---@param scope "smart"|"all"|"current"
function M.files(scope)
    local dirs, title = M.dirs(scope)
    Snacks.picker.files({ dirs = dirs, cwd = dirs[1], title = "Find File \u{b7} " .. title, format = tagged(dirs) })
end

---@param scope "smart"|"all"|"current"
function M.grep(scope)
    local dirs, title = M.dirs(scope)
    Snacks.picker.grep({ dirs = dirs, cwd = dirs[1], title = "Search Text \u{b7} " .. title, format = tagged(dirs) })
end

---@param scope "smart"|"all"|"current"
function M.grep_word(scope)
    local dirs, title = M.dirs(scope)
    Snacks.picker.grep_word({ dirs = dirs, cwd = dirs[1], title = "Search Word \u{b7} " .. title, format = tagged(dirs) })
end

function M.setup()
    local commands = {
        { "FindFileAll", "files", "all", "Find a file in every open workspace" },
        { "SearchTextAll", "grep", "all", "Search text in every open workspace" },
        { "SearchWordAll", "grep_word", "all", "Search the word under the cursor in every open workspace" },
        { "FindFileCurrent", "files", "current", "Find a file in the current workspace only" },
        { "SearchTextCurrent", "grep", "current", "Search text in the current workspace only" },
        { "SearchWordCurrent", "grep_word", "current", "Search the word under the cursor in the current workspace only" },
    }
    for _, c in ipairs(commands) do
        vim.api.nvim_create_user_command(c[1], function() M[c[2]](c[3]) end, { desc = c[4] })
    end
end

return M
