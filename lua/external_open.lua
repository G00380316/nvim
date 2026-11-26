---Opening files from outside: Finder's "Open With", `nvim-open` in a shell, a
---launcher app. They reach this running Neovim through its server socket, so a
---file lands in the editor of the instance you already have instead of
---starting another one. A file's project becomes the workspace first, the same
---as when it is picked from the workspace list; a folder opens as a workspace.
local M = {}

---@param paths string[]
function M.open(paths)
    local workspace = require("workspace")
    local ide_layout = require("ide_layout")
    local first_file

    for _, path in ipairs(paths) do
        path = vim.fn.fnamemodify(path, ":p"):gsub("(.)/$", "%1")
        if vim.fn.isdirectory(path) == 1 then
            workspace.open(path)
        elseif vim.fn.filereadable(path) == 1 or vim.fn.filewritable(vim.fs.dirname(path)) == 2 then
            local root = workspace.find(vim.fs.dirname(path))
            if root and root ~= workspace.get() then workspace.open(root) end
            local editor = ide_layout.ensure_editor_window()
            if editor then vim.api.nvim_set_current_win(editor) end
            vim.cmd("edit " .. vim.fn.fnameescape(path))
            first_file = first_file or path
        else
            vim.notify("Cannot open " .. path, vim.log.levels.WARN, { title = "Open" })
        end
    end
    vim.cmd("redraw!")
end

---Open the paths listed (one per line) in a file, then remove the file. This is
---how the launcher script hands paths over: nothing needs quoting that way.
---@param list_file string
function M.open_list(list_file)
    local ok, lines = pcall(vim.fn.readfile, list_file)
    pcall(vim.fn.delete, list_file)
    if not ok then return end
    M.open(vim.tbl_filter(function(line) return line ~= "" end, lines))
end

return M
