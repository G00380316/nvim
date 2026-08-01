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

---Terminal buffers in floaterm's own order, so cycling matches its numbering.
function M.list()
    local ok, bufnrs = pcall(vim.fn["floaterm#buflist#gather"])
    if not ok or type(bufnrs) ~= "table" then return {} end
    return vim.tbl_filter(vim.api.nvim_buf_is_valid, bufnrs)
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
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
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
    for _, candidate in ipairs(M.list()) do
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

function M.setup()
    vim.api.nvim_set_hl(0, "TerminalTabActive", { link = "Function", default = true })
    vim.api.nvim_set_hl(0, "TerminalTabInactive", { link = "Comment", default = true })

    vim.api.nvim_create_autocmd("TermClose", {
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
