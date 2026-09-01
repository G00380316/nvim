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
local switching_context = false
local context_tabs = {}
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
    path = vim.uv.fs_realpath(path) or path
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

local function tab_workspace(tab)
    local ok, value = pcall(vim.api.nvim_tabpage_get_var, tab, "workspace_root")
    return ok and type(value) == "string" and value ~= "" and value or nil
end

local function assign_tab_workspace(tab, path)
    local previous = tab_workspace(tab)
    if previous and previous ~= path and context_tabs[previous] == tab then
        context_tabs[previous] = nil
    end
    pcall(vim.api.nvim_tabpage_set_var, tab, "workspace_root", path)
    context_tabs[path] = tab
end

local function context_tab(path)
    local remembered = context_tabs[path]
    if remembered
        and vim.api.nvim_tabpage_is_valid(remembered)
        and tab_workspace(remembered) == path
    then
        return remembered
    end

    for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
        if tab_workspace(tab) == path then
            context_tabs[path] = tab
            return tab
        end
    end
end

function M.find(path)
    local dir = normalize(path)
    if not dir then return nil end
    return vim.fs.root(dir, markers) or dir
end

function M.get()
    return root or vim.fn.getcwd()
end

function M.context_tab(path)
    local directory = normalize(path)
    return directory and context_tab(directory) or nil
end

function M.is_open(path)
    return M.context_tab(path) ~= nil
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
    assign_tab_workspace(vim.api.nvim_get_current_tabpage(), root)
    if not vim.b.workspace_root then vim.b.workspace_root = root end
    set_current_directory(root)
    remember(root)

    if not opts.preserve_oil then
        for _, oil_win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.bo[vim.api.nvim_win_get_buf(oil_win)].filetype == "oil" then
                vim.api.nvim_win_call(oil_win, function()
                    require("oil").open(root)
                end)
            end
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

-- Open a directory as a live project context. Each project owns a Neovim tab,
-- so its buffers, splits, sidebar directory and running terminal windows stay
-- exactly where they were while another project is active.
function M.open(path, opts)
    opts = opts or {}

    local directory = normalize(path)
    if not directory or vim.fn.isdirectory(directory) ~= 1 then
        vim.notify("Workspace directory does not exist: " .. tostring(path), vim.log.levels.ERROR)
        return false
    end

    if directory == root then return true end

    local current_tab = vim.api.nvim_get_current_tabpage()
    if root then
        assign_tab_workspace(current_tab, root)
    end

    local target_tab = context_tab(directory)
    local restoring = target_tab ~= nil

    switching_context = true
    local switched, switch_error
    if target_tab then
        switched, switch_error = pcall(vim.api.nvim_set_current_tabpage, target_tab)
    else
        switched, switch_error = pcall(vim.cmd, "tabnew")
    end
    switching_context = false

    if not switched then
        vim.notify("Could not open project context: " .. tostring(switch_error), vim.log.levels.ERROR)
        return false
    end

    if not M.set(directory, {
        exact = opts.exact ~= false,
        silent = opts.silent,
        preserve_oil = restoring,
    }) then
        return false
    end

    if restoring then
        -- A tabpage remembers its focused window, so do not force the editor:
        -- returning to a terminal or sidebar is part of the saved context.
        return true
    end

    require("editor_filler").open({ win = vim.api.nvim_get_current_win() })

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
        desc = "Initialize the first live project context",
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

    vim.api.nvim_create_autocmd("BufAdd", {
        group = workspace_group,
        callback = function(args)
            if root and vim.api.nvim_buf_is_valid(args.buf) and not vim.b[args.buf].workspace_root then
                vim.b[args.buf].workspace_root = root
            end
        end,
        desc = "Associate new unnamed buffers with their project context",
    })

    vim.api.nvim_create_autocmd("TabEnter", {
        group = workspace_group,
        callback = function()
            if switching_context then return end

            local tab = vim.api.nvim_get_current_tabpage()
            local project = tab_workspace(tab)
            if not project then
                if root then assign_tab_workspace(tab, root) end
                return
            end

            context_tabs[project] = tab
            if project ~= root or vim.fs.normalize(vim.fn.getcwd()) ~= project then
                M.set(project, {
                    exact = true,
                    silent = true,
                    preserve_oil = true,
                })
            end
        end,
        desc = "Activate the project context owned by this tab",
    })

    vim.api.nvim_create_autocmd("TabClosed", {
        group = workspace_group,
        callback = function()
            vim.schedule(function()
                for project, tab in pairs(context_tabs) do
                    if not vim.api.nvim_tabpage_is_valid(tab) then context_tabs[project] = nil end
                end
            end)
        end,
        desc = "Forget project contexts whose tabs were closed",
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
