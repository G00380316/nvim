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
---The folder the explorer is showing now, if there is an explorer.
---@return string?
function M.explorer_dir()
    local ok, oil = pcall(require, "oil")
    if not ok then return nil end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == "oil" then
            local dir = oil.get_current_dir(buf)
            if dir then return (vim.fs.normalize(dir):gsub("/$", "")) end
        end
    end
end

function M.pick(opts)
    local root = opts.root or vim.fn.expand("~")
    local inner = folder_finder(root)

    -- The folder you are in comes first, so choosing it again, or somewhere beside
    -- it, is the shortest list. (Typing a search ranks by match, as usual.)
    local current = opts.first ~= false and (opts.first or M.explorer_dir()) or nil
    if type(current) ~= "string" then current = nil end
    if current and vim.fn.isdirectory(current) ~= 1 then current = nil end

    -- /tmp and /private/tmp are one place on macOS; comparing without a syscall
    -- per folder (this runs for every folder found, in a background thread).
    local function same_place(a, b)
        return a:gsub("^/private", "") == b:gsub("^/private", "")
    end

    local function absolute(item)
        return item.abs or vim.fs.normalize(root .. "/" .. item.file)
    end

    Snacks.picker.pick({
        title = opts.title .. "  \u{b7}  type to search  \u{b7}  Enter chooses  \u{b7}  Ctrl-Q closes",
        source = "folders",
        finder = function(finder_opts, ctx)
            local run = inner(finder_opts, ctx)
            return function(cb)
                if current then
                    cb({ text = current, file = current, abs = current, current = true })
                end
                return run(function(item)
                    -- The same folder, listed again by the search, is not repeated.
                    if current and same_place(vim.fs.normalize(root .. "/" .. item.file), current) then return end
                    return cb(item)
                end)
            end
        end,
        format = function(item)
            local home = vim.fn.expand("~")
            local full = absolute(item)
            local parent = vim.fn.fnamemodify(full, ":h"):gsub("^" .. vim.pesc(home), "~")
            local row = {
                { "󰉋  ", "Directory" },
                { vim.fn.fnamemodify(full, ":t"), "SnacksPickerFile" },
                { "  " },
                { parent, "SnacksPickerDesc" },
            }
            if item.current then
                row[#row + 1] = { "  \u{b7} where the explorer is", "DiagnosticOk" }
            end
            return row
        end,
        preview = false,
        layout = { preset = "vscode" },
        -- The search box is where typing goes, always.
        focus = "input",
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            local path = absolute(item)
            vim.schedule(function() opts.confirm(path) end)
        end,
    })
end

---Search folders and open the one you pick in the explorer: the same explorer
---window, not a new one. From anywhere; it brings the explorer up if it is not
---showing. The search covers your whole home folder -- other projects, nested
---folders, iCloud Drive -- not only the project you are in; the workspace is
---not changed by going there.
---@param root? string where to search (default: home)
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
        root = root or vim.fn.expand("~"),
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
