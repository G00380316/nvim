---oil watches folders with filesystem events, which some places never send
---(iCloud Drive, network and external disks) and which are easy to miss when a
---file is moved in from Finder or another terminal. So the folders on screen
---are also looked at: when focus comes back to Neovim, and every couple of
---seconds while it is in front, a folder whose modification time or entry count
---changed is listed again. `:OilRefresh` does it by hand.
local M = {}

local oil_folder_times = {}

local function refresh_visible_oil(force)
    local oil = require("oil")
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "oil" and not vim.bo[buf].modified then
            local directory = oil.get_current_dir(buf)
            local stat = directory and vim.uv.fs_stat(directory)
            if force and not directory then
                -- A folder on a server has nothing to look at cheaply; a manual refresh lists it again.
                pcall(vim.api.nvim_win_call, win, function() require("oil.actions").refresh.callback() end)
            elseif stat then
                -- The entry count is part of the stamp because some places
                -- (iCloud, network disks) add files without touching the
                -- folder's modification time.
                local count = 0
                local handle = vim.uv.fs_scandir(directory)
                while handle and vim.uv.fs_scandir_next(handle) do count = count + 1 end
                local stamp = ("%d.%d.%d"):format(stat.mtime.sec, stat.mtime.nsec, count)
                if force or (oil_folder_times[directory] and oil_folder_times[directory] ~= stamp) then
                    pcall(vim.api.nvim_win_call, win, function()
                        require("oil.actions").refresh.callback()
                    end)
                end
                oil_folder_times[directory] = stamp
            end
        end
    end
end

function M.setup()
    local group = vim.api.nvim_create_augroup("OilFolderChanges", { clear = true })
    local timer = vim.uv.new_timer()
    local focused = true
    timer:start(2000, 2000, vim.schedule_wrap(function()
        -- Not while typing: insert, replace and command-line modes are left alone.
        if focused and not vim.fn.mode():match("^[iRc]") then refresh_visible_oil(false) end
    end))
    vim.api.nvim_create_user_command("OilRefresh", function() refresh_visible_oil(true) end, {
        desc = "List the folders shown in the explorer again",
    })
    vim.api.nvim_create_autocmd("FocusGained", {
        group = group,
        callback = function()
            focused = true
            vim.schedule(function() refresh_visible_oil(true) end)
        end,
    })
    vim.api.nvim_create_autocmd("FocusLost", { group = group, callback = function() focused = false end })
end

return M
