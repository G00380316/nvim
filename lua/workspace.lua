local M = {}

local markers = {
    ".git",
    ".hg",
    ".project",
    "package.json",
    "pyproject.toml",
    "Cargo.toml",
    "go.mod",
    "Makefile",
}

local root
local setting_cwd = false
local history_file = vim.fn.stdpath("state") .. "/workspace-history.json"
local history = {}
local excluded_history_roots = {
    [vim.fs.normalize("/")] = true,
    [vim.fs.normalize(vim.fn.expand("~"))] = true,
}

local function normalize(path)
    if not path or path == "" then return nil end
    path = vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
    if vim.fn.isdirectory(path) ~= 1 then
        path = vim.fs.dirname(path)
    end
    return path and vim.fs.normalize(path) or nil
end

local function load_history()
    if vim.fn.filereadable(history_file) ~= 1 then return end
    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(history_file), "\n"))
    if ok and type(decoded) == "table" then
        local loaded = {}
        local seen = {}
        for _, path in ipairs(decoded) do
            local directory = type(path) == "string" and normalize(path) or nil
            if directory
                and not excluded_history_roots[directory]
                and not seen[directory]
                and vim.fn.isdirectory(directory) == 1
            then
                loaded[#loaded + 1] = directory
                seen[directory] = true
            end
        end
        history = loaded
    end
end

local function remember(path)
    if excluded_history_roots[vim.fs.normalize(path)] then return end

    -- Merge selections made by other Neovim instances before promoting this
    -- workspace to entry one.
    load_history()
    history = vim.tbl_filter(function(item) return item ~= path end, history)
    table.insert(history, 1, path)
    while #history > 20 do table.remove(history) end

    vim.fn.mkdir(vim.fn.fnamemodify(history_file, ":h"), "p")
    pcall(vim.fn.writefile, { vim.json.encode(history) }, history_file)
end

load_history()

local function startup_workspace(path)
    local directory = normalize(path)
    if directory and excluded_history_roots[directory] and history[1] then
        return history[1]
    end
    return path
end

local function set_current_directory(path)
    setting_cwd = true
    local ok, err = pcall(vim.api.nvim_set_current_dir, path)
    setting_cwd = false
    if not ok then error(err) end
end

function M.find(path)
    local dir = normalize(path)
    if not dir then return nil end
    return vim.fs.root(dir, markers) or dir
end

function M.get()
    return root or vim.fn.getcwd()
end

function M.name()
    return vim.fs.basename(M.get())
end

function M.git_root()
    local workspace_root = M.get()
    local marker_root = vim.fs.root(workspace_root, ".git")
    if marker_root then return vim.fs.normalize(marker_root) end

    local result = vim.system({
        "git",
        "-C",
        workspace_root,
        "rev-parse",
        "--show-toplevel",
    }, { text = true }):wait()

    if result.code == 0 and result.stdout then
        local resolved = vim.trim(result.stdout)
        if resolved ~= "" and vim.fn.isdirectory(resolved) == 1 then
            return vim.fs.normalize(resolved)
        end
    end
end

function M.recent(limit)
    load_history()
    local items = vim.list_slice(history, 1, math.min(limit or #history, #history))
    return vim.deepcopy(items)
end

function M.set(path, opts)
    opts = opts or {}
    local next_root = opts.exact and normalize(path) or M.find(path)
    if not next_root or vim.fn.isdirectory(next_root) ~= 1 then
        vim.notify("Workspace directory does not exist: " .. tostring(path), vim.log.levels.ERROR)
        return false
    end

    root = next_root
    vim.g.workspace_root = root
    set_current_directory(root)
    remember(root)

    if vim.g.NvimTreeSetup == 1 then
        local tree = require("nvim-tree.api")
        if tree.tree.is_visible() then
            tree.tree.change_root(root)
        end
    end

    vim.api.nvim_exec_autocmds("User", {
        pattern = "WorkspaceChanged",
        data = { root = root },
    })

    if not opts.silent then
        vim.notify("Workspace: " .. root)
    end
    return true
end

-- Open a directory as the complete editor context. Unlike set(), this does
-- not keep showing a file from the previous workspace in the editor area.
function M.open(path, opts)
    opts = opts or {}

    local directory = normalize(path)
    if not directory or vim.fn.isdirectory(directory) ~= 1 then
        vim.notify("Workspace directory does not exist: " .. tostring(path), vim.log.levels.ERROR)
        return false
    end

    if vim.fn.exists(":GitCloseAll") == 2 then
        pcall(vim.cmd, "GitCloseAll")
    end

    if not M.set(path, {
        exact = opts.exact ~= false,
        silent = opts.silent,
    }) then
        return false
    end

    pcall(vim.cmd, "EditorFocus")
    require("dashboard").open({ win = vim.api.nvim_get_current_win() })

    if vim.g.NvimTreeSetup == 1 then
        require("nvim-tree.api").tree.open({ path = root, focus = false })
    end

    return true
end

function M.from_current_buffer()
    local path = vim.api.nvim_buf_get_name(0)
    if path == "" then
        vim.notify("Current buffer has no workspace", vim.log.levels.WARN)
        return
    end
    M.set(path)
end

function M.setup()
    local initial = vim.api.nvim_buf_get_name(0)
    if initial == "" then
        initial = history[1] or vim.fn.getcwd()
    end
    M.set(startup_workspace(initial), { silent = true })

    local workspace_group = vim.api.nvim_create_augroup("WorkspaceRoot", { clear = true })

    vim.api.nvim_create_autocmd("VimEnter", {
        group = workspace_group,
        callback = function()
            local target = vim.api.nvim_buf_get_name(0)
            if target == "" then target = root or history[1] or vim.fn.getcwd() end
            M.set(startup_workspace(target), { silent = true })
        end,
        once = true,
        desc = "Lock this Neovim instance to one workspace root",
    })

    vim.api.nvim_create_autocmd("DirChanged", {
        group = workspace_group,
        callback = function(args)
            if setting_cwd or not root then return end
            local directory = normalize(args.file)
            if not directory or directory == root then return end

            vim.schedule(function()
                M.set(directory, { exact = true, silent = true })
            end)
        end,
        desc = "Treat every cwd API change as a workspace selection",
    })

    vim.api.nvim_create_user_command("WorkspaceSet", function(args)
        if args.args ~= "" then
            M.set(args.args, { exact = true })
            return
        end
        vim.ui.input({
            prompt = "Workspace directory: ",
            default = M.get() .. "/",
            completion = "dir",
        }, function(value)
            if value then M.set(value, { exact = true }) end
        end)
    end, {
        nargs = "?",
        complete = "dir",
        desc = "Set the workspace root",
    })

    vim.api.nvim_create_user_command("WorkspaceRoot", function()
        vim.notify(M.get())
    end, { desc = "Show the workspace root" })

    vim.api.nvim_create_user_command("WorkspaceOpen", function(args)
        M.open(args.args, { exact = true })
    end, {
        nargs = 1,
        complete = "dir",
        desc = "Open a directory as the complete workspace",
    })
end

return M
