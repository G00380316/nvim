-- A direction that leads nowhere (only the explorer, or the edge) goes to the next allowed window.
vim.cmd("edit " .. T.file("a.txt", "x\n"))
vim.cmd("FocusTree")
vim.wait(500)
vim.cmd("FocusTerminal")
vim.wait(800)

local function kind(w) return vim.bo[vim.api.nvim_win_get_buf(w)].filetype end
local oil, terminal, editor
for _, w in ipairs(vim.api.nvim_list_wins()) do
    local ft = kind(w)
    if ft == "oil" then oil = w elseif ft == "floaterm" then terminal = w elseif not editor then editor = w end
end
T.ok(oil and terminal and editor, "layout has explorer, editor and terminal")

local function press(lhs, from)
    vim.api.nvim_set_current_win(from)
    vim.fn.maparg(lhs, "n", false, true).callback()
    return vim.api.nvim_get_current_win()
end

T.eq(press("<C-h>", editor), terminal, "<C-h> from the editor: explorer skipped, on to the terminal")
T.eq(press("<C-l>", editor), terminal, "<C-l> at the right edge: on to the terminal")
T.eq(press("<C-k>", terminal), editor, "<C-k> from the terminal goes up to the editor")
for _, lhs in ipairs({ "<C-h>", "<C-j>", "<C-k>", "<C-l>" }) do
    T.ok(press(lhs, editor) ~= oil and press(lhs, terminal) ~= oil, lhs .. " never lands in the explorer")
end
