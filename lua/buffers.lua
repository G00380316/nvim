local M = {}

local excluded_filetypes = {
    alpha = true,
    dashboard = true,
    oil = true,
    snacks_dashboard = true,
}

-- These run per buffer on every tabline redraw, and resolving a path is a
-- syscall. Names change far less often than the bufferline repaints.
local resolved_paths = {}
local buffer_workspaces = {}

local function resolve(name)
    local cached = resolved_paths[name]
    if cached then return cached end
    local path = vim.fs.normalize(vim.uv.fs_realpath(name) or vim.fn.fnamemodify(name, ":p"))
    resolved_paths[name] = path
    return path
end

function M.forget(name)
    if name then
        buffer_workspaces[resolved_paths[name] or name] = nil
        resolved_paths[name] = nil
    else
        resolved_paths, buffer_workspaces = {}, {}
    end
end

---An unnamed buffer holding nothing worth keeping.
---
---`modified` cannot answer this on its own. A buffer you typed in and then
---cleared out still reports modified forever, so the old "unnamed and not
---modified" test let empty buffers pile up permanently -- while a scratch
---note with real text in it looked exactly the same to every other check.
function M.is_blank(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return false end
    if vim.api.nvim_buf_get_name(buf) ~= "" then return false end

    -- Anything this long is not "empty" by any reading; skip scanning it.
    if vim.api.nvim_buf_line_count(buf) > 500 then return false end
    for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if line:match("%S") then return false end
    end
    return true
end

---Buffers the editor keymaps are allowed to land on.
---
---An unnamed buffer counts when it actually holds something. Testing
---`modified` instead used to strand a scratch note restored from a session
---(content, but not modified) outside every buffer keymap.
function M.is_editor(buf)
    return buf
        and vim.api.nvim_buf_is_valid(buf)
        and vim.bo[buf].buflisted
        and vim.bo[buf].buftype == ""
        and not excluded_filetypes[vim.bo[buf].filetype]
        and (vim.api.nvim_buf_get_name(buf) ~= "" or not M.is_blank(buf))
end

---Which project a buffer came from.
---
---Navigation is not scoped to one project any more, so this exists to *say*
---where a buffer lives rather than to decide whether you may reach it.
function M.workspace_of(buf)
    if not buf or not vim.api.nvim_buf_is_valid(buf) then return nil end

    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
        -- An untagged scratch buffer belongs wherever you made it; claim it
        -- now so it does not keep reporting a different project each time the
        -- workspace changes.
        local tag = vim.b[buf].workspace_root
        if tag == nil then
            tag = vim.fs.normalize(require("workspace").get())
            vim.b[buf].workspace_root = tag
        end
        return vim.fs.normalize(tag)
    end

    local path = resolve(name)
    local cached = buffer_workspaces[path]
    if cached ~= nil then return cached or nil end

    local root = require("workspace").find(path)
    buffer_workspaces[path] = root and vim.fs.normalize(root) or false
    return buffer_workspaces[path] or nil
end

---The project name to print beside a buffer, and whether it is the one you
---are currently working in.
function M.workspace_label(buf)
    local root = M.workspace_of(buf)
    if not root then return nil, false end
    local workspace = require("workspace")
    return workspace.label(root), root == vim.fs.normalize(workspace.get())
end

function M.belongs_to_workspace(buf, project)
    if not M.is_editor(buf) then return false end

    project = vim.fs.normalize(project or require("workspace").get())
    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then
        -- workspace_of owns the adoption of untagged scratch buffers, so a
        -- buffer made before this project existed is never stranded outside
        -- every project at once.
        return M.workspace_of(buf) == project
    end

    -- Path, not workspace_of: a nested marker (a vendored repo with its own
    -- .git) gives a file a root of its own, and it still belongs to the
    -- project it sits inside.
    name = resolve(name)
    return name == project or name:sub(1, #project + 1) == project .. "/"
end

---Every editor buffer, whichever project it came from.
---
---Navigation used to stop at the current project's boundary, which meant a
---buffer could sit in the bufferline with no key able to reach it. Crossing
---the boundary is the cheaper of the two fixes: nothing is hidden, and the
---picker labels each buffer with the project it belongs to.
function M.list()
    local buffers = {}
    for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        if M.is_editor(info.bufnr) then buffers[#buffers + 1] = info.bufnr end
    end
    return buffers
end

function M.cycle(direction)
    pcall(vim.cmd, "EditorFocus")

    local buffers = M.list()
    local count = #buffers
    if count == 0 then
        return
    end

    local current = vim.api.nvim_get_current_buf()
    local current_index

    for index, buf in ipairs(buffers) do
        if buf == current then
            current_index = index
            break
        end
    end

    local target
    if current_index == nil then
        target = direction > 0 and buffers[1] or buffers[count]
    else
        target = buffers[((current_index - 1 + direction) % count) + 1]
    end

    local ok, err = pcall(vim.api.nvim_win_set_buf, 0, target)
    if not ok then
        -- Schedule the notification so it is outside the autocmd call stack.
        vim.schedule(function()
            vim.notify(
                tostring(err),
                vim.log.levels.WARN,
                { title = "Buffer switch failed" }
            )
        end)
    end
end

---What to show once `current` is closed.
---
---Closing a buffer should not tip you into another project, so the most
---recent one from this project wins; anything else is only a fallback, which
---still beats dropping you on the dashboard.
function M.replacement(current)
    local candidates = vim.tbl_filter(function(info)
        return info.bufnr ~= current and M.is_editor(info.bufnr)
    end, vim.fn.getbufinfo({ buflisted = 1 }))
    table.sort(candidates, function(a, b) return a.lastused > b.lastused end)

    for _, info in ipairs(candidates) do
        if M.belongs_to_workspace(info.bufnr) then return info.bufnr end
    end
    return candidates[1] and candidates[1].bufnr or nil
end

---Delete the unnamed buffers that hold nothing, wherever they came from.
---
---The per-buffer autocmds only fire for buffers you visit, so anything left
---behind by a session restore or a plugin would otherwise sit in the
---bufferline forever. Never touches a buffer that is on screen, current, or
---has any text in it.
function M.sweep()
    local current = vim.api.nvim_get_current_buf()
    local removed = 0

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= current
            and vim.api.nvim_buf_is_valid(buf)
            and vim.bo[buf].buflisted
            and vim.bo[buf].buftype == ""
            and #vim.fn.win_findbuf(buf) == 0
            and M.is_blank(buf)
        then
            if pcall(vim.api.nvim_buf_delete, buf, { force = true }) then
                removed = removed + 1
            end
        end
    end

    return removed
end

return M
