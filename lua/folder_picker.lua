---A flat, searchable list of the folders under a root, with the search box
---always focused (no tree to expand). Typing narrows by folder name or any part
---of the path ("labs w03"), so a folder deep in iCloud Drive is a few letters
---away. What choosing one does is up to the caller.
local M = {}

local function folder_finder(root)
    return function(opts, ctx)
        return require("snacks.picker.source.proc").proc(ctx:opts({
            cmd = "fd",
            cwd = root,
            args = {
                "--type", "d", "--hidden", "--follow", "--color", "never", "--max-depth", "9",
                "--exclude", ".git", "--exclude", "node_modules", "--exclude", ".cache",
                "--exclude", ".Trash", "--exclude", ".npm", "--exclude", ".venv", "--exclude", "venv",
                "--exclude", "__pycache__", "--exclude", ".build", "--exclude", "DerivedData",
                "--exclude", "Library/Caches", "--exclude", "Library/Application Support",
                "--exclude", "Library/Containers", "--exclude", "Library/Developer",
                "--exclude", "Library/Group Containers", "--exclude", "Library/Logs",
                "--exclude", "Library/Preferences", "--exclude", "Library/Saved Application State",
                "--exclude", ".local/share", "--exclude", ".rustup", "--exclude", ".cargo",
            },
            transform = function(item)
                -- fd lists directories with a trailing slash.
                local rel = item.text:gsub("/$", "")
                item.file = rel
                item.cwd = root
                item.dir = true
                item.text = rel
            end,
        }), ctx)
    end
end

---@class folder.PickOpts
---@field root? string where to search (default: home)
---@field title string
---@field confirm fun(path: string) what choosing a folder does
---@param opts folder.PickOpts
function M.pick(opts)
    local root = opts.root or vim.fn.expand("~")
    Snacks.picker.pick({
        title = opts.title .. "  \u{b7}  type to search  \u{b7}  Enter chooses  \u{b7}  Ctrl-Q closes",
        source = "folders",
        finder = folder_finder(root),
        format = function(item)
            local home = vim.fn.expand("~")
            local full = vim.fs.normalize(root .. "/" .. item.file)
            local parent = vim.fn.fnamemodify(full, ":h"):gsub("^" .. vim.pesc(home), "~")
            return {
                { "󰉋  ", "Directory" },
                { vim.fn.fnamemodify(full, ":t"), "SnacksPickerFile" },
                { "  " },
                { parent, "SnacksPickerDesc" },
            }
        end,
        preview = false,
        layout = { preset = "vscode" },
        -- The search box is where typing goes, always.
        focus = "input",
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            local path = vim.fs.normalize(root .. "/" .. item.file)
            vim.schedule(function() opts.confirm(path) end)
        end,
    })
end

---Search the project's folders and open the one you pick in the explorer: the
---same explorer window, not a new one. From anywhere; it brings the explorer up
---if it is not showing.
---@param root? string where to search (default: the workspace)
function M.jump_oil(root)
    local origin = vim.api.nvim_get_current_win()
    if vim.bo.filetype ~= "oil" then
        -- FocusTree toggles when already in the explorer, so only from elsewhere.
        pcall(vim.cmd, "FocusTree")
    end
    local win = vim.api.nvim_get_current_win()
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype ~= "oil" then
        vim.notify("The explorer is not available", vim.log.levels.WARN, { title = "Folders" })
        return
    end

    M.pick({
        root = root or require("workspace").get(),
        title = "Jump Explorer to Folder",
        confirm = function(path)
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
            else
                pcall(vim.api.nvim_set_current_win, origin)
            end
            require("oil").open(path)
        end,
    })
end

return M
