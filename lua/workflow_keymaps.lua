local M = {}

-- This is deliberately a short, opinionated list. <leader>K still exposes
-- every mapping when something uncommon needs to be looked up.
local entries = {
    { "Project", "<leader>p", "n", "Switch project and preserve its open panes" },
    { "Project", "<C-e>", "switcher", "Name the project under the cursor, or clear its name" },
    { "Project", "<C-d>", "switcher", "Close the open project under the cursor; press again to forget it" },
    { "Project", "<leader>w", "n", "Choose any folder as the workspace" },
    { "Project", "zcd", "n", "Use this file's project as the workspace; with no file open, the explorer's folder" },
    { "Project", "<leader>f", "n", "Find a file anywhere under home" },
    { "Project", "<C-e>", "n/i/x", "Open or focus the Oil project tree" },
    { "Project", "<C-f>", "n/i/x", "Find a file in the current project" },
    { "Project", "<C-g>", "n/i/x", "Search text across the current project" },
    { "Project", "<leader>l", "n/x", "Search the word or visual selection" },

    { "Search", "/", "n", "Search within the current buffer" },
    { "Search", "<leader>s", "n/x", "Replace in the buffer or selection" },
    { "Search", "<leader>c", "n", "Clear the active search" },
    { "Search", "<leader>r", "n", "Replace the word under the cursor, interactively" },

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
    { "Code", "g]d", "n", "Jump to the next diagnostic" },
    { "Code", "g[d", "n", "Jump to the previous diagnostic" },
    { "Buffers", "[ / ]", "n", "Back / forward through the buffers you have been in" },

    { "Terminal", "<C-t>", "n/i/x/t", "Open terminal or return to the editor", "terminal_or_editor" },
    { "Terminal", "<C-v> → <C-g>", "t", "Move through output like a buffer, then copy it with the cursor where you were", "terminal_normal" },
    { "Terminal", "<C-g>", "t", "Copy terminal output into an editable, saveable buffer", "terminal_edit" },
    { "Terminal", "<leader>t", "n", "Open terminal action selector (new terminal here lives there)" },
    { "Terminal", "zn / zp", "n", "Focus the next / previous terminal" },

    { "Git", "zg", "n", "Open Git action selector (hunks, blame, LazyGit, Diffview)" },
    { "Git", "g]h", "n", "Jump to the next changed hunk" },
    { "Git", "g[h", "n", "Jump to the previous changed hunk" },

    { "Debug", "zd", "n", "Open debug action selector" },
    { "Debug", "<F5>", "n", "Start or continue debugging" },
    { "Debug", "<F9>", "n", "Toggle breakpoint" },
    { "Debug", "<F10>", "n", "Step over" },
    { "Debug", "<F11>", "n", "Step into" },
    { "Debug", "<F12>", "n", "Step out" },

    { "Tools", "<leader>x", "n/x", "Open Xcode action selector" },

    { "Run", "<leader>e", "n", "Run the current file through the zsh run function" },
    { "Run", "<leader>xr", "n", "Test the current file through the zsh runtest function" },

    { "Markdown", "<leader>i", "n", "Import a PDF, Word file, web page or image as a new note" },
    { "Markdown", "<CR>", "n/x", "Tick or untick the checkbox on this line; a plain bullet becomes one" },
    { "Markdown", "o", "n", "Open a new list item below (O for above)" },
    { "Markdown", "<leader>n", "n", "Run the notebook cell under the cursor (in a .ipynb)" },
    { "Markdown", "<leader>m", "n", "Show or hide the note-taking hints beside the note" },
    { "Markdown", "<leader>M", "n", "Pick from the hints and insert it; j/k, Enter, q to leave" },

    { "Daily", "<leader>?", "n/x", "Search editing recipes: surround a word, change inside a block, swap lines" },
    { "Daily", "S", "x", "Surround the selection: S\" quotes it, S( or Sb brackets it, S* makes it bold" },
    { "Daily", "<C-s>", "n/i/x", "Save and format" },
    { "Daily", "<leader>o", "n", "Save this file and source it" },
    { "Daily", "<leader>h", "n", "Search Neovim's help" },
    { "Daily", "<leader><leader>", "n", "Command palette: search every action by name" },
    { "Daily", "<C-\\>", "any", "Open this command guide from any mode" },
    { "Daily", "<leader>k", "n", "Show this workflow guide" },
    { "Daily", "<leader>K", "n", "Search every active keymap" },
    { "Daily", "<leader>v", "n", "Search Vim's own keys, and what this config took" },
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

---Do what a guide row says, from wherever the guide was opened.
---
---One path for it, so the palette behaves exactly as the guide does: a row
---chosen from a terminal, Oil or a tool panel acts on the editor rather than
---on that special-purpose buffer.
---@param item table a row from M.items()
---@param context table from M.capture_context()
function M.activate(item, context)
    -- These keys exist only inside the project switcher's own window. Feeding
    -- one from here would press it somewhere else entirely.
    if item.mode == "switcher" then
        vim.notify(item.lhs .. " works inside the project switcher (<leader>p)", vim.log.levels.INFO)
        return
    end

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

    -- No longer refused away from a terminal: edit() falls back to the
    -- terminal on screen. Returning to the origin first still matters, so a
    -- split panel copies the half you were in.
    if item.action == "terminal_edit" then
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

    pcall(vim.cmd, "EditorFocus")
    vim.api.nvim_feedkeys(vim.keycode(item.lhs:match("^%S+")), "m", false)
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
            vim.schedule(function() M.activate(item, context) end)
        end,
    })
end

---Note where a guide or palette was opened from, and step out of whatever mode
---that was in, so the picker is not opened inside the mode-changing mapping's
---own callback -- especially from a terminal buffer.
function M.capture_context()
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
    return context
end

function M.open()
    local context = M.capture_context()
    vim.schedule(function() open_picker(context) end)
end

return M
