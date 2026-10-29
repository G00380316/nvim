local M = {}

-- ssh-launcher puts each session in a terminal of its own, usually in its own
-- tab. Leaving that tab hides the session without ending it; this brings you
-- back from anywhere, to a session in a tab or a window, and into typing.

---Every ssh-launcher terminal that is showing somewhere.
---@return { buf: integer, win: integer, title: string }[]
local function sessions()
    local found = {}
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].buftype == "terminal" and vim.b[buf].ssh_launcher then
            found[#found + 1] = {
                buf = buf,
                win = win,
                title = vim.b[buf].ssh_launcher_title or vim.api.nvim_buf_get_name(buf),
            }
        end
    end
    return found
end

local function go(session)
    if not vim.api.nvim_win_is_valid(session.win) then return end
    vim.api.nvim_set_current_win(session.win)
    vim.cmd("startinsert")
end

function M.jump()
    local list = sessions()
    if #list == 0 then
        vim.notify("No ssh session is open (connect from the palette: SSH Actions)", vim.log.levels.INFO, { title = "SSH" })
        return
    end
    -- Already in one, with another to go to: the next, so repeating cycles.
    local current = vim.api.nvim_get_current_win()
    if #list == 1 then
        if list[1].win ~= current then go(list[1]) end
        return
    end
    vim.ui.select(list, {
        prompt = "SSH session",
        format_item = function(session)
            local tab = vim.api.nvim_tabpage_get_number(vim.api.nvim_win_get_tabpage(session.win))
            return ("%s  (tab %d)"):format(session.title, tab)
        end,
    }, function(choice)
        if choice then go(choice) end
    end)
end

function M.setup()
    vim.api.nvim_create_user_command("SshJump", M.jump, { desc = "Go to an open ssh session" })
end

return M
