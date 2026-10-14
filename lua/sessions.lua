---A saved session per project: which files were open, which one you were in, and
---where the cursor was in each. It is written as you work, so there is always a
---current one -- including after Neovim is closed without ceremony -- and one
---action (or the dashboard's `r`) brings it back. Terminals and window layout
---are not saved; the layout rebuilds itself around the files.
local M = {}

local dir = vim.fn.stdpath("state") .. "/sessions"
local restoring = false
local save_timer

local function file_for(root)
    -- A path as a filename: slashes would be directories.
    return dir .. "/" .. (root:gsub("[/\\ :]", "%%")) .. ".json"
end

local function read(path)
    if vim.fn.filereadable(path) ~= 1 then return nil end
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"))
    return ok and type(data) == "table" and data or nil
end

---The files open in this workspace, as they are now.
local function snapshot()
    local workspace = require("workspace")
    local root = workspace.get()
    if not root or root == "" then return nil end

    local buffers = require("buffers")
    local editor_win = require("ide_layout").find_editor_window()
    local current_buf = editor_win and vim.api.nvim_win_get_buf(editor_win) or nil

    local files, current = {}, nil
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf)
            and vim.bo[buf].buflisted
            and vim.bo[buf].buftype == ""
            and buffers.is_editor(buf)
            and buffers.belongs_to_workspace(buf, root)
        then
            local path = vim.api.nvim_buf_get_name(buf)
            if path ~= "" and vim.fn.filereadable(path) == 1 then
                local line, col = 1, 0
                if buf == current_buf and editor_win then
                    line, col = unpack(vim.api.nvim_win_get_cursor(editor_win))
                else
                    local mark = vim.api.nvim_buf_get_mark(buf, '"')
                    if mark[1] > 0 then line, col = mark[1], mark[2] end
                end
                files[#files + 1] = { path = path, line = line, col = col }
                if buf == current_buf then current = path end
            end
        end
    end
    if #files == 0 then return nil end
    return { root = root, saved = os.time(), current = current or files[1].path, files = files }
end

---Write the current project's session.
function M.save()
    if restoring then return end
    local data = snapshot()
    if not data then return end
    vim.fn.mkdir(dir, "p")
    pcall(vim.fn.writefile, { vim.json.encode(data) }, file_for(data.root))
end

---Save a moment after things settle, however many events come at once.
local function save_soon()
    if restoring then return end
    if save_timer then save_timer:stop() else save_timer = vim.uv.new_timer() end
    save_timer:start(800, 0, vim.schedule_wrap(M.save))
end

---Every saved session, newest first.
---@return { root: string, saved: integer, current: string, files: table[] }[]
function M.all()
    local sessions = {}
    for _, path in ipairs(vim.fn.glob(dir .. "/*.json", false, true)) do
        local data = read(path)
        if data and data.root and vim.fn.isdirectory(data.root) == 1 then sessions[#sessions + 1] = data end
    end
    table.sort(sessions, function(a, b) return (a.saved or 0) > (b.saved or 0) end)
    return sessions
end

---The session of a project, if one was saved.
function M.for_root(root)
    return root and read(file_for(root)) or nil
end

---Bring a session back: the project, then its files with the one you were in on
---top. With no argument: this project's, else the most recent anywhere.
---@param data? table a session from `all()` / `for_root()`
function M.restore(data)
    data = data or M.for_root(require("workspace").get()) or M.all()[1]
    if not data then
        vim.notify("No saved session yet", vim.log.levels.INFO, { title = "Session" })
        return
    end

    restoring = true
    local ok = require("workspace").open(data.root, { exact = true })
    if not ok then
        restoring = false
        return
    end

    -- After the project's own layout has settled.
    vim.defer_fn(function()
        local opened = 0
        local current_buf
        for _, file in ipairs(data.files) do
            if vim.fn.filereadable(file.path) == 1 then
                local buf = vim.fn.bufadd(file.path)
                vim.bo[buf].buflisted = true
                vim.fn.bufload(buf)
                pcall(vim.api.nvim_buf_set_mark, buf, '"', file.line or 1, file.col or 0, {})
                if file.path == data.current then current_buf = buf end
                opened = opened + 1
            end
        end

        pcall(vim.cmd, "EditorFocus")
        if current_buf then
            vim.cmd("buffer " .. current_buf)
            local file
            for _, f in ipairs(data.files) do if f.path == data.current then file = f end end
            if file then pcall(vim.api.nvim_win_set_cursor, 0, { file.line or 1, file.col or 0 }) end
        end
        restoring = false
        vim.notify(
            ("Restored %d file%s in %s"):format(opened, opened == 1 and "" or "s", require("workspace").label(data.root)),
            vim.log.levels.INFO,
            { title = "Session" }
        )
    end, 400)
end

---Choose which project's session to bring back.
function M.pick()
    local sessions = M.all()
    if #sessions == 0 then
        vim.notify("No saved sessions yet", vim.log.levels.INFO, { title = "Session" })
        return
    end
    local workspace = require("workspace")
    vim.ui.select(sessions, {
        prompt = "Restore which session?",
        format_item = function(session)
            local when = os.date("%d %b %H:%M", session.saved)
            return ("%s  ·  %d file%s  ·  %s"):format(
                workspace.label(session.root), #session.files, #session.files == 1 and "" or "s", when)
        end,
    }, function(choice)
        if choice then M.restore(choice) end
    end)
end

---Throw away this project's saved session.
function M.forget()
    local root = require("workspace").get()
    local path = root and file_for(root)
    if path and vim.fn.filereadable(path) == 1 then
        vim.fn.delete(path)
        vim.notify("Forgot this project's session", vim.log.levels.INFO, { title = "Session" })
    else
        vim.notify("This project has no saved session", vim.log.levels.INFO, { title = "Session" })
    end
end

function M.setup()
    -- A Neovim started inside a terminal for one purpose (LeetCode) is not a project.
    if vim.env.NVIM_NESTED then return end
    local group = vim.api.nvim_create_augroup("Sessions", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "BufDelete", "WinLeave" }, {
        group = group,
        callback = save_soon,
        desc = "Keep the project's session up to date",
    })
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function() M.save() end,
        desc = "Save the session on the way out",
    })

    local commands = {
        { "SessionRestore", function() M.restore() end, "Reopen the files of this project's last session (or the last one anywhere)" },
        { "SessionPick", M.pick, "Choose which project's session to reopen" },
        { "SessionSave", M.save, "Save the session now" },
        { "SessionForget", M.forget, "Delete this project's saved session" },
    }
    for _, c in ipairs(commands) do
        vim.api.nvim_create_user_command(c[1], c[2], { nargs = 0, desc = c[3] })
    end
end

return M
