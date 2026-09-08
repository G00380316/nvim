local M = {}

-- A shell's working directory changes with `cd`, and Neovim has no way to
-- observe that from the outside. It is sampled from the OS instead and cached:
-- the lookup costs ~100ms, far too slow to run during a statusline redraw.
local cwd_cache = {}
local refresh_timer

local function terminal_pid(bufnr)
    local ok, job = pcall(function() return vim.b[bufnr].terminal_job_id end)
    if not ok or not job then return nil end
    local pid_ok, pid = pcall(vim.fn.jobpid, job)
    return pid_ok and pid or nil
end

local function terminal_workspace(bufnr)
    local assigned = vim.b[bufnr].floaterm_workspace
    if type(assigned) == "string" and assigned ~= "" then
        return vim.fs.normalize(assigned)
    end

    -- Backfill terminals created before project contexts were enabled. Their
    -- launch cwd is stable even if the shell has since changed directory.
    local launched = vim.fn.getbufvar(bufnr, "floaterm_cwd")
    if type(launched) == "string" and launched ~= "" then
        assigned = require("workspace").find(launched)
    end
    assigned = assigned or require("workspace").get()
    vim.b[bufnr].floaterm_workspace = assigned
    return vim.fs.normalize(assigned)
end

---The buffer the user is actually working in. Terminal actions are often
---triggered from the panel itself, where the current buffer is a shell and
---says nothing about which file is open.
local function editor_buffer()
    local current = vim.api.nvim_get_current_buf()
    if vim.bo[current].buftype == "" and vim.api.nvim_buf_get_name(current) ~= "" then
        return current
    end

    local win = require("ide_layout").find_editor_window()
    if not win then return nil end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
        return buf
    end
end

---Where a new terminal should start.
---
---The project root, normally, so every shell in a context agrees on what
---"here" means. But a file opened from outside the project -- a dotfile, a
---dependency's source, a note from elsewhere -- has no relationship to that
---root, and a shell standing there cannot so much as `ls` the thing on
---screen. For those, the file's own directory is the useful answer.
---
---The terminal still *belongs* to the current project either way: ownership
---comes from b:floaterm_workspace, set when the buffer is created, so a shell
---launched outside the root still appears in this project's terminal list.
function M.launch_cwd()
    local project = vim.fs.normalize(require("workspace").get())

    local buf = editor_buffer()
    if not buf then return project end

    local directory = vim.fs.dirname(vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ":p"))
    directory = vim.fs.normalize(vim.uv.fs_realpath(directory) or directory)
    if vim.fn.isdirectory(directory) ~= 1 then return project end

    if directory == project or directory:sub(1, #project + 1) == project .. "/" then
        return project
    end
    return directory
end

---Terminal buffers for one project in floaterm's own order, so cycling
---matches its numbering without leaking shells from another project context.
function M.list(project)
    local ok, bufnrs = pcall(vim.fn["floaterm#buflist#gather"])
    if not ok or type(bufnrs) ~= "table" then return {} end
    project = vim.fs.normalize(project or require("workspace").get())
    return vim.tbl_filter(function(bufnr)
        return vim.api.nvim_buf_is_valid(bufnr)
            and terminal_workspace(bufnr) == project
    end, bufnrs)
end

local function sample_cwd(bufnr)
    local pid = terminal_pid(bufnr)
    if not pid then return end

    vim.system(
        { "lsof", "-a", "-p", tostring(pid), "-d", "cwd", "-Fn" },
        { text = true },
        function(result)
            if result.code ~= 0 or not result.stdout then return end
            -- -Fn output is one field per line: "p<pid>", "fcwd", "n<path>".
            local path = result.stdout:match("n(/[^\r\n]*)")
            if not path then return end
            vim.schedule(function()
                if cwd_cache[bufnr] ~= path then
                    cwd_cache[bufnr] = path
                    pcall(vim.cmd.redrawstatus)
                end
            end)
        end
    )
end

function M.refresh()
    for _, bufnr in ipairs(M.list()) do
        sample_cwd(bufnr)
    end
end

---Display name for a terminal: its current directory, home-relative.
function M.name(bufnr)
    local path = cwd_cache[bufnr]
    if not path then
        local launched = vim.fn.getbufvar(bufnr, "floaterm_cwd")
        if type(launched) == "string" and launched ~= "" then path = launched end
    end
    if not path then return "terminal" end
    return vim.fn.fnamemodify(path, ":~")
end

local function terminal_window(bufnr)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == bufnr then return win end
    end
end

local function any_terminal_window()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "floaterm" then return win end
    end
end

---Focus a terminal. Already-visible terminals are focused in place rather than
---being re-displayed somewhere else, so a split panel keeps its layout.
function M.focus(bufnr)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end

    local win = terminal_window(bufnr)
    if not win then
        win = any_terminal_window()
        if win then
            vim.api.nvim_win_set_buf(win, bufnr)
        else
            pcall(vim.fn["floaterm#show"], 0, bufnr, "")
            win = terminal_window(bufnr)
        end
    end

    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        vim.cmd("startinsert")
    end
end

function M.cycle(direction)
    local bufnrs = M.list()
    if #bufnrs == 0 then
        vim.notify("No terminals open", vim.log.levels.INFO)
        return
    end

    local current = vim.api.nvim_get_current_buf()
    local index = 0
    for i, bufnr in ipairs(bufnrs) do
        if bufnr == current then
            index = i
            break
        end
    end

    local target
    if index == 0 then
        target = direction > 0 and bufnrs[1] or bufnrs[#bufnrs]
    else
        target = bufnrs[(index - 1 + direction) % #bufnrs + 1]
    end
    M.focus(target)
end

function M.pick()
    local bufnrs = M.list()
    if #bufnrs == 0 then
        vim.notify("No terminals open", vim.log.levels.INFO)
        return
    end

    M.refresh()
    local current = vim.api.nvim_get_current_buf()

    require("snacks").picker.pick({
        title = "Terminals",
        finder = function()
            local items = {}
            for index, bufnr in ipairs(bufnrs) do
                local name = M.name(bufnr)
                items[#items + 1] = {
                    text = name .. " " .. index,
                    label = name,
                    bufnr = bufnr,
                    index = index,
                    current = bufnr == current,
                }
            end
            return items
        end,
        format = function(item)
            return {
                { item.current and "● " or "  ", "DiagnosticOk" },
                { item.label,                    "Function" },
                { "  #" .. item.index,           "Comment" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            vim.schedule(function() M.focus(item.bufnr) end)
        end,
    })
end

---Statusline fragment: every terminal by path, the focused one highlighted.
function M.tabline()
    local current = vim.api.nvim_get_current_buf()
    local parts = {}

    for _, bufnr in ipairs(M.list()) do
        local group = bufnr == current and "TerminalTabActive" or "TerminalTabInactive"
        local icon = bufnr == current and " " or " "
        parts[#parts + 1] = string.format("%%#%s#%s%s%%*", group, icon, M.name(bufnr))
    end

    return table.concat(parts, " ")
end

---When a terminal goes away, take over its slot with the next one instead of
---collapsing the panel -- the split layout is meant to survive one of its
---halves exiting.
local function replace_closed(bufnr, win)
    -- Prefer a terminal that is not already on screen; promoting one that is
    -- visible in the other half would just show the same shell twice, so a
    -- split half whose sibling survives is simply allowed to collapse.
    local successor
    local project = vim.api.nvim_buf_is_valid(bufnr)
        and terminal_workspace(bufnr)
        or require("workspace").get()
    for _, candidate in ipairs(M.list(project)) do
        if candidate ~= bufnr
            and vim.api.nvim_buf_is_valid(candidate)
            and not terminal_window(candidate)
        then
            successor = candidate
            break
        end
    end

    if successor then
        if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_buf(win, successor)
        else
            -- floaterm tore the panel down first; bring it back with the survivor.
            M.focus(successor)
        end
    elseif win
        and vim.api.nvim_win_is_valid(win)
        and #vim.api.nvim_tabpage_list_wins(0) > 1
    then
        -- No terminal left to promote: collapse the slot instead of leaving an
        -- empty window sitting where the shell used to be.
        pcall(vim.api.nvim_win_close, win, true)
    end

    if vim.api.nvim_buf_is_valid(bufnr) then
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
    cwd_cache[bufnr] = nil
end

---The terminal to copy from. Usually the current buffer, but the command and
---the action menu both run from the editor -- there "this terminal" can only
---mean the one on screen, so fall back to that instead of refusing.
local function source_terminal()
    local current = vim.api.nvim_get_current_buf()
    if vim.bo[current].buftype == "terminal" then return current end

    local win = any_terminal_window()
    if win then return vim.api.nvim_win_get_buf(win) end

    return M.list()[1]
end

---A real path under the project root, never an invented `terminal://` URI.
---That single choice is what makes the copy behave like any other file: `:w`
---writes it, Ctrl-C closes it, and buffer cycling -- which is scoped to the
---project by name -- can actually reach it again.
local function output_path(project)
    local taken = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        taken[vim.api.nvim_buf_get_name(buf)] = true
    end

    for index = 1, 99 do
        local path = index == 1
            and (project .. "/terminal-output.txt")
            or string.format("%s/terminal-output-%d.txt", project, index)
        if vim.fn.filereadable(path) == 0 and not taken[path] then return path end
    end
    return string.format("%s/terminal-output-%d.txt", project, vim.uv.hrtime())
end

---Reuse the buffer from the last copy, but only while it still holds exactly
---what was copied into it. Once you have typed in it, the next copy gets its
---own buffer rather than silently discarding your edits.
local function reusable_output(source)
    local buf = vim.b[source].terminal_output_buf
    if type(buf) ~= "number" or not vim.api.nvim_buf_is_valid(buf) then return nil end
    if vim.b[buf].terminal_output_tick ~= vim.api.nvim_buf_get_changedtick(buf) then
        return nil
    end
    return buf
end

---Copy a terminal's output into an ordinary, saveable buffer.
---
---A `:terminal` buffer is not editable: in terminal-normal mode you can move,
---visually select and yank, but `i`/`a` re-enter *terminal* mode, which hands
---the keys to the shell and snaps the cursor to its prompt. That is Neovim's
---design, not something a mapping can change -- so to actually edit output,
---take a copy of it somewhere editing works.
---
---The terminal itself is only ever read from. Nothing here writes to the
---terminal buffer or touches its job, so a copy cannot disturb the shell.
---
---opts.first/opts.last narrow the copy to a line range (a visual selection);
---opts.cursor is a position in the terminal to land on in the copy.
function M.edit(opts)
    opts = opts or {}
    local source = source_terminal()
    if not source then
        vim.notify("No terminal to copy from", vim.log.levels.WARN)
        return
    end

    local total = vim.api.nvim_buf_line_count(source)
    local first = math.max(1, math.min(opts.first or 1, total))
    local last = math.max(first, math.min(opts.last or total, total))

    local lines = vim.api.nvim_buf_get_lines(source, first - 1, last, false)
    -- A terminal pads its screen to the window height; that padding is not output.
    while #lines > 0 and lines[#lines]:match("^%s*$") do
        table.remove(lines)
    end
    if #lines == 0 then
        vim.notify("Terminal has no output to copy", vim.log.levels.INFO)
        return
    end

    -- Land in the editor zone, creating it when the frame has none. The old
    -- fallback was "whatever window is current", which put the copy inside the
    -- terminal panel and pushed the live shell off screen.
    local ide = require("ide_layout")
    local win = ide.find_editor_window() or ide.ensure_editor_window()
    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.notify("No editor window to open the terminal output in", vim.log.levels.WARN)
        return
    end

    local buf = reusable_output(source)
    if not buf then
        buf = vim.api.nvim_create_buf(true, false)
        local project = vim.fs.normalize(require("workspace").get())
        pcall(vim.api.nvim_buf_set_name, buf, output_path(project))
        vim.bo[buf].swapfile = false
        vim.b[source].terminal_output_buf = buf
    end

    -- The copy borrows the editor pane, so remember what it displaced: closing
    -- it puts that buffer back in place rather than closing the pane and
    -- letting the terminal panel expand into the gap (see close_current).
    -- Skipped when the copy is already on display, or it would record itself
    -- as its own predecessor.
    local displaced = vim.api.nvim_win_get_buf(win)
    vim.b[buf].terminal_edit = true
    if displaced ~= buf then
        vim.b[buf].terminal_edit_previous_buf = displaced
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- Remembered so the next copy can tell "untouched" from "edited".
    vim.b[buf].terminal_output_tick = vim.api.nvim_buf_get_changedtick(buf)

    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_set_current_win(win)

    local cursor = opts.cursor
    local row = cursor and (cursor[1] - (first - 1)) or #lines
    row = math.max(1, math.min(row, #lines))
    local col = math.max(0, math.min(cursor and cursor[2] or 0, #(lines[row] or "")))
    vim.api.nvim_win_set_cursor(win, { row, col })
end

function M.setup()
    -- Wrapped rather than passed straight through: a user command hands its
    -- callback a table of command arguments, which M.edit would read as its
    -- own options.
    vim.api.nvim_create_user_command("TerminalEdit", function(args)
        M.edit(args.range > 0 and { first = args.line1, last = args.line2 } or {})
    end, {
        range = true,
        desc = "Copy terminal output into an editable, saveable buffer",
    })

    vim.api.nvim_set_hl(0, "TerminalTabActive", { link = "Function", default = true })
    vim.api.nvim_set_hl(0, "TerminalTabInactive", { link = "Comment", default = true })

    local group = vim.api.nvim_create_augroup("TerminalPanel", { clear = true })

    vim.api.nvim_create_autocmd("TermClose", {
        group = group,
        callback = function(args)
            if vim.bo[args.buf].filetype ~= "floaterm" then return end
            -- Captured synchronously: floaterm closes the panel itself before
            -- the scheduled follow-up runs, losing the slot we want to reuse.
            local win = terminal_window(args.buf)
            vim.schedule(function() replace_closed(args.buf, win) end)
        end,
        desc = "Hand a closed terminal's slot to the next terminal",
    })

    -- Sample on the events that change which terminal you are looking at, and
    -- poll slowly while one is on screen so a `cd` is reflected without
    -- needing an explicit refresh.
    vim.api.nvim_create_autocmd({ "BufEnter", "TermEnter", "TermLeave", "WinEnter" }, {
        group = group,
        callback = function(args)
            if vim.bo[args.buf].filetype == "floaterm" then M.refresh() end
        end,
        desc = "Track the working directory of terminals",
    })

    if refresh_timer then refresh_timer:stop() end
    refresh_timer = vim.uv.new_timer()
    refresh_timer:start(2000, 2000, vim.schedule_wrap(function()
        if any_terminal_window() then M.refresh() end
    end))
end

return M
