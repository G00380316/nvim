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
    "Package.swift",
}

local marker_names = {}
for _, name in ipairs(markers) do marker_names[name] = true end

-- An Xcode project or workspace is a bundle named after the project itself, so
-- it cannot be listed by name with the rest. Without it a Swift file's root
-- came out as whichever Sources/ subdirectory it happened to sit in.
local function is_marker(name)
    return marker_names[name] == true
        or name:match("%.xcodeproj$") ~= nil
        or name:match("%.xcworkspace$") ~= nil
end

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

-- Aliases sit beside the history and mean exactly one thing: what a project is
-- called on screen. The directory keeps its own name, so nothing on disk moves
-- and a renamed project is still the same path in every list.
local alias_file = vim.fn.stdpath("state") .. "/workspace-aliases.json"
local aliases = {}
local labels = {}
local labels_signature

local function load_aliases()
    labels = {}
    aliases = {}
    if vim.fn.filereadable(alias_file) ~= 1 then return end

    local ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(alias_file), "\n"))
    if not ok or type(decoded) ~= "table" then return end

    for path, alias in pairs(decoded) do
        if type(path) == "string" and type(alias) == "string" and alias ~= "" then
            local directory = normalize(path)
            if directory then aliases[directory] = alias end
        end
    end
end

local function save_aliases()
    vim.fn.mkdir(vim.fn.fnamemodify(alias_file, ":h"), "p")
    -- An empty Lua table encodes as a JSON array, which would not read back as
    -- the map this is, so the object form is written out explicitly.
    local encoded = next(aliases) and vim.json.encode(aliases) or "{}"
    pcall(vim.fn.writefile, { encoded }, alias_file)
end

load_aliases()

---Where to start. From a directory that is no project -- the home folder --
---that is the folder you used last, and exactly that one: history holds the
---folders as they were chosen, and searching upward from one for a project
---marker can land on a parent you never opened (an iCloud folder with a
---Makefile somewhere above your project, say).
---@return string path
---@return boolean exact
local function startup_workspace(path)
    local directory = normalize(path)
    if directory and excluded_history_roots[directory] and history[1] then
        return history[1], true
    end
    return path, false
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
    return vim.fs.root(dir, is_marker) or dir
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

---What a project is called on screen: the alias you gave it, otherwise the
---directory's own name.
---
---Memoised, because this is asked once per row of every buffer and project
---list, and answering it properly means resolving the path.
function M.label(path)
    path = path or M.get()

    -- A new project in the history can make an old name ambiguous, so the
    -- memo is only good for as long as the history is the same.
    local signature = table.concat(history, "\n")
    if signature ~= labels_signature then
        labels, labels_signature = {}, signature
    end

    local cached = labels[path]
    if cached then return cached end

    local directory = normalize(path)
    local label = directory and aliases[directory]
    if not label then
        -- Only unnamed projects can clash: a named one shows its alias.
        local peers = {}
        for _, dir in ipairs(history) do
            if not aliases[normalize(dir) or dir] then peers[#peers + 1] = dir end
        end
        label = require("names").label(directory or path, peers)
    end
    labels[path] = label
    return label
end

-- Answered per buffer and only re-answered when that buffer's file, or the
-- workspace itself, has actually moved. This is read on every statusline
-- redraw, and resolving a path properly costs a few syscalls.
local contexts = {}

---The buffer a project-scoped question is really about.
---
---Asked from the terminal or the sidebar, the current buffer is a shell or a
---directory listing and says nothing about what is being worked on.
local function subject_buffer()
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == "" then
        return buf
    end

    local ok, layout = pcall(require, "ide_layout")
    local win = ok and layout.find_editor_window() or nil
    buf = win and vim.api.nvim_win_get_buf(win) or nil
    if buf and vim.bo[buf].buftype == "" then return buf end
end

---Where a project-scoped action should look right now.
---
---The workspace, normally. But a file opened from outside it -- a dependency's
---source, a note, another checkout -- has no relationship to that root, and a
---search scoped there cannot see the file on screen, never mind its
---neighbours. For those the file's own project answers instead.
---
---Nothing is switched. This is read per action, so it follows the buffer you
---are in and lets go the moment you return to one of the project's own files:
---no state to restore, and the workspace, its tab, its terminals and its
---sidebar all stay where they were.
function M.context(bufnr)
    local root = vim.fs.normalize(M.get())
    local buf = bufnr or subject_buffer()
    if not buf then return root end

    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then return root end

    local cached = contexts[buf]
    if cached and cached.name == name and cached.root == root then
        return cached.context
    end

    local context = root
    local directory = normalize(name)

    if directory and directory ~= root and directory:sub(1, #root + 1) ~= root .. "/" then
        local found = M.find(directory)
        -- A file under a marker-less directory below $HOME would otherwise
        -- resolve to $HOME itself, and searching there is not a search.
        context = (found and not excluded_history_roots[found]) and found or directory
    end

    contexts[buf] = { name = name, root = root, context = context }
    return context
end

---Whether the workspace is what a project-scoped action would act on, or
---whether the buffer you are in has taken the scope somewhere else.
function M.visiting()
    local context = M.context()
    return context ~= vim.fs.normalize(M.get()) and context or nil
end

function M.alias(path)
    local directory = normalize(path or M.get())
    return directory and aliases[directory] or nil
end

---Name a project, or clear its name by passing nothing.
function M.set_alias(path, alias)
    local directory = normalize(path or M.get())
    if not directory then
        vim.notify("No such directory: " .. tostring(path), vim.log.levels.ERROR)
        return false
    end

    alias = alias and vim.trim(alias) or ""
    local previous = M.label(directory)

    -- Merge what other Neovim instances have named before writing, the same
    -- way the history does.
    load_aliases()
    aliases[directory] = alias ~= "" and alias or nil
    save_aliases()
    labels = {}

    if alias ~= "" then
        vim.notify(previous .. " is now " .. alias)
    else
        vim.notify(previous .. " goes back to " .. vim.fs.basename(directory))
    end
    return true
end

---Drop a project from the list you switch between.
---
---The directory is not touched -- this is the list forgetting it, not a
---delete. A project with a live tab is refused: every tab re-asserts its own
---workspace when you enter it, so forgetting one would silently undo itself.
function M.forget(path)
    local directory = normalize(path)
    if not directory then
        vim.notify("No such directory: " .. tostring(path), vim.log.levels.ERROR)
        return false
    end

    if context_tab(directory) then
        vim.notify(
            "Close this project's tab before forgetting it: " .. M.label(directory),
            vim.log.levels.WARN
        )
        return false
    end

    load_history()
    local kept = vim.tbl_filter(function(item) return item ~= directory end, history)
    if #kept == #history then
        vim.notify("Not in the project list: " .. M.label(directory), vim.log.levels.WARN)
        return false
    end

    local name = M.label(directory)
    history = kept
    vim.fn.mkdir(vim.fn.fnamemodify(history_file, ":h"), "p")
    pcall(vim.fn.writefile, { vim.json.encode(history) }, history_file)

    load_aliases()
    if aliases[directory] then
        aliases[directory] = nil
        save_aliases()
        labels = {}
    end

    vim.notify("Forgot project: " .. name)
    return true
end

---The project to land on when the only open one is closed: the most recently
---used other project in the list, which is where you were before this one.
local function successor_of(directory)
    load_history()
    for _, path in ipairs(history) do
        if path ~= directory and vim.fn.isdirectory(path) == 1 then return path end
    end
end

---Close a project's live context: the tab that holds its windows, its splits
---and its terminals.
---
---It stays in the list -- this is putting it away, not forgetting it. Its
---buffers stay loaded too, and reachable, which is how everything else in this
---config treats a buffer; closing a project is about the layout it owns.
---
---Closing the only open project opens the next one first, so there is always
---somewhere to land. Neovim cannot close its last tab, and a refusal there
---would just be the picker declining to do what its key says.
---
---Refused while any of its buffers has unsaved changes, and when there is no
---other project to land on.
function M.close(path)
    local directory = normalize(path or M.get())
    local tab = directory and context_tab(directory)
    if not tab then
        vim.notify("That project has nothing open: " .. M.label(directory), vim.log.levels.WARN)
        return false
    end

    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].modified then
            vim.notify(
                "Unsaved changes in " .. vim.fs.basename(vim.api.nvim_buf_get_name(buf)),
                vim.log.levels.WARN
            )
            return false
        end
    end

    local name = M.label(directory)
    local landed

    if #vim.api.nvim_list_tabpages() == 1 then
        local successor = successor_of(directory)
        if not successor then
            vim.notify(
                "No other project to open. Add one with <leader>w before closing " .. name .. ".",
                vim.log.levels.WARN
            )
            return false
        end

        if not M.open(successor, { exact = true, silent = true }) then return false end
        landed = M.label(successor)
    end

    -- Looked up again: opening the next project may have renumbered the tabs.
    tab = context_tab(directory)
    if not tab then return true end

    local ok, err = pcall(vim.cmd, vim.api.nvim_tabpage_get_number(tab) .. "tabclose")
    if not ok then
        vim.notify("Could not close " .. name .. ": " .. tostring(err), vim.log.levels.ERROR)
        return false
    end

    context_tabs[directory] = nil
    vim.notify(landed and ("Closed project: " .. name .. "  \u{203a}  " .. landed) or ("Closed project: " .. name))
    return true
end

function M.name()
    return M.label(M.get())
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
    -- Both files are re-read here, so a project list drawn now reflects what
    -- other Neovim instances have opened and named since this one started.
    load_history()
    load_aliases()
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
        vim.notify("Workspace: " .. M.label(root))
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

    require("ide_layout").open_filler({ win = vim.api.nvim_get_current_win() })

    return true
end

---Make where you are the workspace.
---
---The file you are editing, when there is one: its project, found by the usual
---markers. With no file open -- the editor is on the dashboard or a blank
---buffer -- the directory the explorer is showing, exactly as shown, since
---having navigated there is the only statement of intent there is. Standing in
---the explorer itself means the same thing.
function M.from_here()
    local function explorer_directory(buf)
        local loaded, oil = pcall(require, "oil")
        if not loaded then return nil end

        local ok, directory = pcall(oil.get_current_dir, buf)
        return ok and type(directory) == "string" and directory ~= "" and directory or nil
    end

    local buf = vim.api.nvim_get_current_buf()

    if vim.bo[buf].filetype == "oil" then
        local directory = explorer_directory(buf)
        if directory then return M.set(directory, { exact = true }) end
    end

    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].buftype == "" and name ~= "" then
        return M.set(name)
    end

    local sidebar = require("ide_layout").find_sidebar()
    local directory = sidebar and explorer_directory(vim.api.nvim_win_get_buf(sidebar))
    if directory then return M.set(directory, { exact = true }) end

    vim.notify("No file is open and the explorer is not showing a folder", vim.log.levels.WARN)
end

---Where a start with `name` open begins.
---
---A file: the project it belongs to, found by the usual markers. Nothing open:
---the folder used last, exactly -- it was recorded as chosen, and searching
---upward from it again would be a second guess at something already decided.
---@param name string the first buffer's name, "" for none
---@return string path
---@return boolean exact
local function initial_workspace(name)
    if name ~= "" then return startup_workspace(name) end
    if history[1] then return history[1], true end
    return vim.fn.getcwd(), false
end

function M.setup()
    local start, exact = initial_workspace(vim.api.nvim_buf_get_name(0))
    M.set(start, { silent = true, exact = exact })

    local workspace_group = vim.api.nvim_create_augroup("WorkspaceRoot", { clear = true })

    vim.api.nvim_create_autocmd("VimEnter", {
        group = workspace_group,
        callback = function()
            local target = vim.api.nvim_buf_get_name(0)

            -- Nothing was opened, so setup() has already chosen; do it again
            -- only to apply it to the window that now exists, and as chosen.
            if target == "" and root then
                M.set(root, { silent = true, exact = true })
                return
            end

            local start, exact = initial_workspace(target)
            M.set(start, { silent = true, exact = exact })
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

    vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
        group = workspace_group,
        callback = function(args) contexts[args.buf] = nil end,
        desc = "Forget the search context of a buffer that is gone",
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

    vim.api.nvim_create_user_command("WorkspaceAlias", function(args)
        if args.args ~= "" then
            M.set_alias(nil, args.args)
            return
        end

        vim.ui.input({
            prompt = "Name for " .. M.label() .. " (empty to clear): ",
            default = M.alias() or "",
        }, function(value)
            if value then M.set_alias(nil, value) end
        end)
    end, {
        nargs = "?",
        desc = "Name the current project, or clear its name",
    })

    vim.api.nvim_create_user_command("WorkspaceClose", function(args)
        M.close(args.args ~= "" and args.args or M.get())
    end, {
        nargs = "?",
        complete = "dir",
        desc = "Close a project's tab, keeping it in the list",
    })

    vim.api.nvim_create_user_command("WorkspaceForget", function(args)
        M.forget(args.args ~= "" and args.args or M.get())
    end, {
        nargs = "?",
        complete = "dir",
        desc = "Drop a project from the list you switch between",
    })
end

return M
