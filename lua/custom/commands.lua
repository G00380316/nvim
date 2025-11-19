-- This module defines a function that displays a static menu of custom commands
-- using vim.ui.select, similar to a diagnostics quickfix menu.
local M = {}

-- --- COMMAND DEFINITION TABLE ---
local custom_commands = {
    {
        name = "Save and Quit",
        cmd =
        "lua if vim.fn.mode() == 'i' then vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 'n', true) end; vim.cmd('write'); vim.cmd('quit')",
    },
    {
        name = "Toggle (LiveServer)",
        cmd = "lua vim.cmd('LiveServerToggle')",
    },
    {
        name = "Open (Session Manager)",
        cmd = "lua vim.cmd('SessionManager')",
    },
    {
        name = "Open (Compiler)",
        cmd = "lua vim.cmd('CompilerOpen')",
    },
    {
        name = "Toggle Results (Compiler)",
        cmd = "lua vim.cmd('CompilerToggleResults')",
    },
    {
        name = "Redo last selected option (Compiler)",
        cmd = "lua vim.cmd('CompilerStop'); vim.cmd('CompilerRedo')",
    },
    {
        name = "LSP Hover Info",
        cmd = "lua vim.lsp.buf.hover()",
    },
}

--- Function to display the custom command menu using vim.ui.select.
M.show_custom_command_menu = function()
    local menu_items = {}

    for _, item in ipairs(custom_commands) do
        table.insert(menu_items, {
            display = item.name,
            command_to_run = item.cmd
        })
    end

    vim.ui.select(menu_items, {
        prompt = "Select Command to Run",
        format_item = function(item)
            return item.display
        end,
    }, function(selected_item)
        if selected_item and selected_item.command_to_run then
            vim.cmd(selected_item.command_to_run)
        end
    end)
end

return M
