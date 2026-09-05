local M = {}

-- This is deliberately a short, opinionated list. <leader>K still exposes
-- every mapping when something uncommon needs to be looked up.
local entries = {
    { "Project", "<leader>p", "n", "Switch project and preserve its open panes" },
    { "Project", "<leader>w", "n", "Choose any folder as the workspace" },
    { "Project", "<C-e>", "n/i/x", "Open or focus the Oil project tree" },
    { "Project", "<C-f>", "n/i/x", "Find a file in the current project" },
    { "Project", "<C-g>", "n/i/x", "Search text across the current project" },
    { "Project", "<leader>l", "n/x", "Search the word or visual selection" },

    { "Search", "/", "n", "Search within the current buffer" },
    { "Search", "<leader>s", "n/x", "Replace in the buffer or selection" },
    { "Search", "<leader>sq", "n", "Search into editable project results" },
    { "Search", "<leader>st", "n", "Open or focus editable project results" },
    { "Search", "<leader>c", "n", "Clear the active search" },

    { "Buffers", "<C-b>", "n/i/x", "Choose an open editor buffer" },
    { "Buffers", "<Tab>", "n", "Next editor buffer" },
    { "Buffers", "<S-Tab>", "n", "Previous editor buffer" },
    { "Buffers", "<C-q>", "n/i/x/t", "Close the current buffer, pane, panel, or terminal", "close_current" },

    { "Panes", "zv", "n", "Split the editor vertically" },
    { "Panes", "zh", "n", "Split the editor horizontally" },
    { "Panes", "<C-Left>", "n", "Shrink editor width" },
    { "Panes", "<C-Right>", "n", "Grow editor width" },
    { "Panes", "<C-Down>", "n", "Shrink editor height" },
    { "Panes", "<C-Up>", "n", "Grow editor height" },
    { "Panes", "z=", "n", "Equalize editor panes" },

    { "Code", "s", "n/x/o", "Flash to a visible location" },
    { "Code", "gd", "n", "Go to definition" },
    { "Code", "gr", "n", "Find references" },
    { "Code", "gi", "n", "Go to implementation" },
    { "Code", "<C-Space>", "n/x", "Code action or refactor selection" },
    { "Code", "<leader>dd", "n", "Show diagnostics for this buffer" },
    { "Code", "<leader>dw", "n", "Show diagnostics for the project" },

    { "Terminal", "<C-t>", "n/i/x/t", "Open terminal or return to the editor", "terminal_or_editor" },
    { "Terminal", "<C-v> → i", "t", "Jump through output, then edit at the cursor", "terminal_normal" },
    { "Terminal", "<C-g>", "t", "Copy terminal output into an editable buffer", "terminal_edit" },
    { "Terminal", "<leader>t", "n", "Open terminal action selector" },

    { "Git", "zg", "n", "Open Git action selector" },

    { "Debug", "zd", "n", "Open debug action selector" },
    { "Debug", "<F5>", "n", "Start or continue debugging" },
    { "Debug", "<F9>", "n", "Toggle breakpoint" },
    { "Debug", "<F10>", "n", "Step over" },
    { "Debug", "<F11>", "n", "Step into" },
    { "Debug", "<F12>", "n", "Step out" },

    { "Tools", "zl", "n", "Open LeetCode action selector" },
    { "Tools", "zs", "n", "Open live-server action selector" },
    { "Tools", "<leader>x", "n/x", "Open Xcode action selector" },

    { "Daily", "<C-s>", "n/i/x", "Save and format" },
    { "Daily", "<leader>qn", "n", "Open quick notes" },
    { "Daily", "zmm", "n", "Open or focus the mobile device hub" },
    { "Daily", "<C-\\>", "any", "Open this command guide from any mode" },
    { "Daily", "<leader>k", "n", "Show this workflow guide" },
    { "Daily", "<leader>K", "n", "Search every active keymap" },
}

function M.items()
    local items = {}
    for _, entry in ipairs(entries) do
        local group, lhs, mode, desc, action = unpack(entry)
        items[#items + 1] = {
            text = table.concat({ group, lhs, mode, desc }, " "),
            group = group,
            lhs = lhs,
            mode = mode,
            desc = desc,
            action = action,
        }
    end
    return items
end

local function valid_origin(context)
    return context
        and vim.api.nvim_win_is_valid(context.win)
        and vim.api.nvim_buf_is_valid(context.buf)
        and vim.api.nvim_win_get_buf(context.win) == context.buf
end

local function return_to_origin(context)
    if not valid_origin(context) then return false end
    vim.api.nvim_set_current_win(context.win)
    return true
end

local function open_picker(context)
    local Snacks = require("snacks")
    Snacks.picker.pick({
        title = "My Neovim Commands  ·  Ctrl-Q closes",
        items = M.items(),
        preview = false,
        layout = { preset = "vscode" },
        format = function(item)
            local align = Snacks.picker.util.align
            return {
                { align(item.group, 10), "SnacksPickerLabel" },
                { "  " },
                { align(item.lhs, 24), "SnacksPickerKeymapLhs" },
                { "  " },
                { align(item.mode, 6), "SnacksPickerKeymapMode" },
                { "  " },
                { item.desc, "SnacksPickerDesc" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end

            vim.schedule(function()
                local from_terminal = valid_origin(context)
                    and vim.bo[context.buf].buftype == "terminal"

                if item.action == "terminal_normal" then
                    if not from_terminal then
                        vim.notify("Terminal-normal mode is only available from a terminal", vim.log.levels.INFO)
                        return
                    end
                    return_to_origin(context)
                    if vim.api.nvim_get_mode().mode:sub(1, 1) == "t" then vim.cmd("stopinsert") end
                    return
                end

                if item.action == "terminal_edit" then
                    if not from_terminal then
                        vim.notify("Open the command guide from a terminal to edit its output", vim.log.levels.INFO)
                        return
                    end
                    return_to_origin(context)
                    require("terminals").edit()
                    return
                end

                if item.action == "terminal_or_editor" and from_terminal then
                    pcall(vim.cmd, "EditorFocus")
                    return
                end

                if item.action == "close_current" then
                    return_to_origin(context)
                    vim.api.nvim_feedkeys(vim.keycode("<C-q>"), "m", false)
                    return
                end

                -- A command chosen from terminal, Oil, or a tool panel should
                -- act on the editor rather than that special-purpose buffer.
                pcall(vim.cmd, "EditorFocus")
                vim.api.nvim_feedkeys(vim.keycode(item.lhs), "m", false)
            end)
        end,
    })
end

function M.open()
    local mode = vim.api.nvim_get_mode().mode
    local context = {
        mode = mode,
        win = vim.api.nvim_get_current_win(),
        buf = vim.api.nvim_get_current_buf(),
    }
    if mode:sub(1, 1) == "t" or mode:sub(1, 1) == "i" then
        vim.cmd("stopinsert")
    elseif mode:match("[vV\22]") then
        vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
    end

    -- Deferring avoids opening the picker inside the mode-changing mapping's
    -- own callback, especially from a terminal buffer.
    vim.schedule(function() open_picker(context) end)
end

return M
