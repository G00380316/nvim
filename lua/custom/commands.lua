-- This module defines a function that displays a static menu of custom commands
-- using vim.ui.select, similar to a diagnostics quickfix menu.
local M = {}

-- --- COMMAND DEFINITION TABLE ---
-- This table defines the command list. Each item needs a 'name' for display
-- and a 'cmd' which is the actual Vim command string to execute.
local custom_commands = {
    {
        name = "Save and Quit",
        cmd =
        "lua if vim.fn.mode() == 'i' then vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true) end; vim.cmd('write'); vim.cmd('quit')",
    },
    {
        name = "Format Buffer (LSP)",
        cmd = "lua vim.lsp.buf.format()",
    },
    {
        name = "LSP Go to Definition",
        cmd = "lua vim.lsp.buf.definition()",
    },
    {
        name = "Git Blame (Toggle)",
        cmd = "Git Blame",
    },
    {
        name = "Edit Neovim Config",
        cmd = "e $MYVIMRC",
    },
}

--- Function to display the custom command menu using vim.ui.select.
M.show_custom_command_menu = function()
    -- 1. Prepare the items for the UI
    local menu_items = {}
    for _, item in ipairs(custom_commands) do
        -- We insert a table with both the display name and the command to run later.
        table.insert(menu_items, {
            display = string.format("%s", item.name),
            command_to_run = item.cmd
        })
    end

    -- 2. Display the menu
    vim.ui.select(menu_items, {
        prompt = "Select Command to Run",
        -- Use the 'format_item' function to control what the user sees in the menu.
        format_item = function(item)
            return item.display
        end,
    }, function(selected_item)
        -- 3. Handle the selection callback
        if selected_item and selected_item.command_to_run then
            -- Execute the command attached to the selected item
            vim.cmd(selected_item.command_to_run)
            print("Executed: " .. selected_item.command_to_run)
        else
            -- The user hit ESC or cancelled the menu
            print("Command selection cancelled.")
        end
    end)
end

return M
