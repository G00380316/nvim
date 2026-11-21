---Editable workspace results: quicker.nvim's quickfix, a ripgrep search into
---it (:WorkspaceResults), and the replace-in-buffer popup.
local M = {}

function M.setup()
    local ide_layout = require("ide_layout")

    local function find_window(filetype)
        for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == filetype then return win end
        end
    end

    local quicker = require("quicker")

    local function close_quicker_results()
        if not quicker.is_open() then return end

        -- Quickfix can temporarily become the last window during startup. Create
        -- a safe editor landing pane before closing it so Ctrl-Q never triggers
        -- E444 and never falls through to quitting Neovim.
        if #vim.api.nvim_tabpage_list_wins(0) == 1 then
            local editor = ide_layout.ensure_editor_window()
            ide_layout.open_filler({ win = editor })
        end
        quicker.close()
    end

    quicker.setup({
        edit = {
            enabled = true,
            autosave = "unmodified",
        },
        keys = {
            {
                ">",
                function()
                    quicker.expand({ before = 2, after = 2, add_to_existing = true })
                end,
                desc = "Expand quickfix context",
            },
            {
                "<",
                function() quicker.collapse() end,
                desc = "Collapse quickfix context",
            },
        },
        on_qf = function(buf)
            vim.keymap.set("n", "q", "<Nop>", {
                buffer = buf,
                silent = true,
                desc = "Disabled: use Ctrl-Q to close",
            })
            vim.keymap.set("n", "<C-c>", close_quicker_results, {
                buffer = buf,
                silent = true,
                desc = "Close editable results",
            })
            vim.keymap.set("n", "<C-q>", close_quicker_results, {
                buffer = buf,
                silent = true,
                desc = "Close editable results",
            })
        end,
    })

    local function open_project_results(query)
        query = vim.trim(query or "")
        if query == "" then return end

        local root = require("workspace").get()
        vim.system({
            "rg",
            "--vimgrep",
            "--smart-case",
            "--hidden",
            "--glob",
            "!.git",
            query,
            ".",
        }, { cwd = root, text = true }, function(result)
            vim.schedule(function()
                if result.code == 1 then
                    vim.notify("No matches for: " .. query, vim.log.levels.INFO)
                    return
                end
                if result.code ~= 0 then
                    local message = vim.trim(result.stderr or "")
                    vim.notify(message ~= "" and message or "Workspace search failed", vim.log.levels.ERROR)
                    return
                end

                vim.fn.setqflist({}, "r", {
                    title = "Search: " .. query,
                    lines = vim.split(result.stdout or "", "\n", { trimempty = true }),
                    efm = "%f:%l:%c:%m",
                })
                if quicker.is_open() then
                    quicker.refresh()
                    local results_win = find_window("qf")
                    if results_win then vim.api.nvim_set_current_win(results_win) end
                else
                    if not pcall(quicker.open, { focus = true }) then pcall(vim.cmd, "copen") end
                end
            end)
        end)
    end

    vim.api.nvim_create_user_command("WorkspaceResults", function(opts)
        if opts.args ~= "" then
            open_project_results(opts.args)
            return
        end
        vim.ui.input({
            prompt = "Workspace search: ",
            default = vim.fn.expand("<cword>"),
        }, open_project_results)
    end, {
        nargs = "*",
        desc = "Search the workspace into an editable quickfix buffer",
    })

    vim.keymap.set({ "n", "x" }, "<leader>s", function()
        require("rip-substitute").sub()
    end, { desc = "Replace in buffer or selection" })

    -- Palette commands, not keys: occasional enough to search for.
    vim.api.nvim_create_user_command("ResultsFocus", function()
        if quicker.is_open() then
            local results_win = find_window("qf")
            if results_win then vim.api.nvim_set_current_win(results_win) end
            return
        end
        -- quicker can fail to open (an option error from the list's own settings);
        -- the plain quickfix window is the fallback, and still takes focus.
        if not pcall(quicker.open, { focus = true }) then pcall(vim.cmd, "copen") end
    end, { desc = "Open or focus the editable workspace results" })

end

return M
