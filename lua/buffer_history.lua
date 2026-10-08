local M = {}

-- Back and forward through the buffers you have been in, the way a browser does
-- through pages.
--
-- The cursor jumplist is the wrong thing to hang this on. It records every
-- search hit, `G`, `%` and jump inside a file, per window, so "back" lands on a
-- line you passed through three searches ago in whatever buffer that was. What
-- is wanted is coarser: the buffer you were in before this one.
--
-- One history per tab, which here means per project: going back in one project
-- never lands in another's files. Going back and then opening something new
-- drops what was ahead, as a browser's Forward does.

local limit = 100

---@class buffer_history.State
---@field list integer[] buffers in the order they were visited
---@field index integer where in `list` you are now
---@type table<integer, buffer_history.State> keyed by tabpage handle
local states = {}

local navigating = false

local function layout()
    return require("ide_layout")
end

local function state_for(tab)
    local state = states[tab]
    if not state then
        state = { list = {}, index = 0 }
        states[tab] = state
    end
    return state
end

---Only buffers you can actually be editing: not terminals, the explorer, the
---dashboard or a plugin's window.
local function trackable(buf)
    return buf and vim.api.nvim_buf_is_valid(buf) and require("buffers").is_editor(buf)
end

---Note that the editor window has just shown `buf`.
function M.visit(buf)
    if navigating or not trackable(buf) then return end

    local win = vim.api.nvim_get_current_win()
    if not layout().is_editor_window(win) then return end

    local state = state_for(vim.api.nvim_get_current_tabpage())
    if state.list[state.index] == buf then return end

    -- Anything ahead of here is gone: a new visit starts a new branch.
    for i = #state.list, state.index + 1, -1 do state.list[i] = nil end
    state.list[#state.list + 1] = buf

    while #state.list > limit do table.remove(state.list, 1) end
    state.index = #state.list
end

---Move `count` steps through the history, skipping buffers that are gone, are
---not editable now, or are the one already on screen.
---@param direction 1|-1
---@param count integer
local function step(direction, count)
    local state = states[vim.api.nvim_get_current_tabpage()]
    if not state or #state.list == 0 then return end

    local win = layout().find_editor_window()
    if not win then return end
    local current = vim.api.nvim_win_get_buf(win)

    local index, target = state.index, nil
    for _ = 1, count do
        local found
        local probe = index + direction
        while probe >= 1 and probe <= #state.list do
            local candidate = state.list[probe]
            if trackable(candidate) and candidate ~= (target or current) then
                found = probe
                break
            end
            probe = probe + direction
        end
        if not found then break end
        index, target = found, state.list[found]
    end

    if not target then
        vim.notify(direction < 0 and "No earlier buffer" or "No later buffer", vim.log.levels.INFO,
            { title = "Buffers" })
        return
    end

    state.index = index
    navigating = true
    local ok, err = pcall(function()
        vim.api.nvim_set_current_win(win)
        vim.cmd("buffer " .. target)
    end)
    navigating = false

    if not ok then vim.notify(tostring(err), vim.log.levels.ERROR, { title = "Buffers" }) end
end

function M.back(count) step(-1, count or 1) end
function M.forward(count) step(1, count or 1) end

---The history, for tools and tests: names, with the current position marked.
function M.describe()
    local state = states[vim.api.nvim_get_current_tabpage()]
    if not state then return {} end
    local out = {}
    for i, buf in ipairs(state.list) do
        local name = vim.api.nvim_buf_is_valid(buf) and vim.fs.basename(vim.api.nvim_buf_get_name(buf)) or "(gone)"
        out[#out + 1] = (i == state.index and "*" or "") .. name
    end
    return out
end

function M.setup()
    local group = vim.api.nvim_create_augroup("BufferHistory", { clear = true })

    vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        callback = function(args) M.visit(args.buf) end,
        desc = "Record the editor buffers visited, for [ and ]",
    })

    vim.api.nvim_create_autocmd("TabClosed", {
        group = group,
        callback = function()
            vim.schedule(function()
                local live = {}
                for _, tab in ipairs(vim.api.nvim_list_tabpages()) do live[tab] = true end
                for tab in pairs(states) do
                    if not live[tab] then states[tab] = nil end
                end
            end)
        end,
        desc = "Forget the buffer history of a project that was closed",
    })
end

return M
