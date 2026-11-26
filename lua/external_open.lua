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

---Where the shared Neovim listens; the launcher script looks here.
function M.socket()
    return vim.env.NVIM_LAUNCHER_SOCKET
        or ((vim.env.XDG_STATE_HOME or (vim.env.HOME .. "/.local/state")) .. "/nvim/launcher.sock")
end

---The first Neovim you start by hand listens on the launcher's socket too, so
---Finder and `nvim-open` reuse it rather than starting another. A second one
---finds it taken and stays as it is. Not for a Neovim run inside a Neovim
---terminal, a headless one, or when NVIM_NO_LAUNCHER_SOCKET is set.
function M.setup()
    vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("ExternalOpenSocket", { clear = true }),
        once = true,
        callback = function()
            if #vim.api.nvim_list_uis() == 0 or vim.env.NVIM or vim.env.NVIM_NO_LAUNCHER_SOCKET then return end
            if vim.v.servername ~= "" and vim.v.servername == M.socket() then return end
            local socket = M.socket()
            if vim.uv.fs_stat(socket) then
                local ok, channel = pcall(vim.fn.sockconnect, "pipe", socket, { rpc = true })
                if ok and channel > 0 then
                    pcall(vim.fn.chanclose, channel)
                    return -- another Neovim has it
                end
                vim.uv.fs_unlink(socket)
            end
            vim.fn.mkdir(vim.fs.dirname(socket), "p")
            pcall(vim.fn.serverstart, socket)
        end,
    })
end

return M
