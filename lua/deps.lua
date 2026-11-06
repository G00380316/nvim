---The programs this configuration leans on, and the means to fetch whichever
---are missing on this machine: Homebrew on a Mac, the system's package manager
---on Linux (apt, dnf, pacman, zypper, apk), then Homebrew-on-Linux, npm, pipx,
---cargo or go for the tools that only come that way.
---
---The names follow ~/Documents/Github/Mac_Install/install.sh, which stays the
---full setup for a Mac; this is the part Neovim itself can do on any machine, at
---the moment something needs it:
---  * a language server's file is opened and its program is not there
---  * a feature is used (export to PDF, lazygit, opencode, a notebook ...)
---  * once after start, for the few tools every picker and parser leans on
---Each time it asks first, shows the command it will run, and runs it in the
---terminal panel so a password prompt (sudo) can be answered there.
---
---:Deps lists everything and what is missing; :DepsInstall [name] installs.
---vim.g.deps_auto_install = true skips the question.
local M = {}

local uv = vim.uv
local sysname_is_mac = uv.os_uname().sysname == "Darwin"
-- `M._platform` and `M._exists` are for the tests: pretend to be another machine.
local function mac_now()
    if M._platform then return M._platform == "mac" end
    return sysname_is_mac
end

local state_file = vim.fn.stdpath("state") .. "/deps.json"
local python_host = vim.fn.expand("~/.local/share/nvim/python-host")

-- ------------------------------------------------------------------ the list

local function entry(spec) return spec end

---Fields: exe (or exes: any one will do), name, why, essential, and how to get
---it -- brew / cask, a native package per manager (or `native` for all of
---them), npm, pipx, cargo, go -- or `manual` text when there is no package.
M.entries = {
    -- What pickers, parsers and the git views lean on.
    entry({ exe = "git", name = "git", why = "source control", essential = true,
        brew = "git", native = "git" }),
    entry({ exe = "rg", name = "ripgrep", why = "searching text in files", essential = true,
        brew = "ripgrep", native = "ripgrep" }),
    entry({ exes = { "fd", "fdfind" }, name = "fd", why = "finding files", essential = true,
        brew = "fd", apt = "fd-find", dnf = "fd-find", pacman = "fd", zypper = "fd", apk = "fd" }),
    entry({ exe = "tree-sitter", name = "tree-sitter CLI", why = "building syntax parsers", essential = true,
        brew = "tree-sitter-cli", pacman = "tree-sitter-cli", npm = "tree-sitter-cli", cargo = "tree-sitter-cli" }),
    entry({ exes = { "cc", "gcc", "clang" }, name = "a C compiler", why = "building syntax parsers", essential = true,
        brew = "gcc", apt = "build-essential", dnf = "gcc", pacman = "gcc", zypper = "gcc", apk = "build-base" }),
    entry({ exe = "node", name = "Node.js", why = "several language servers and Copilot", essential = true,
        brew = "node", apt = "nodejs npm", dnf = "nodejs npm", pacman = "nodejs npm", zypper = "nodejs npm", apk = "nodejs npm" }),

    -- Package managers other entries come through.
    entry({ exe = "python3", name = "Python 3", why = "notebooks and scripts",
        brew = "python", apt = "python3 python3-venv python3-pip", dnf = "python3 python3-pip",
        pacman = "python python-pip", zypper = "python3 python3-pip", apk = "python3 py3-pip" }),
    entry({ exe = "pipx", name = "pipx", why = "installing Python command line tools",
        brew = "pipx", apt = "pipx", dnf = "pipx", pacman = "python-pipx", zypper = "python3-pipx", apk = "pipx" }),
    entry({ exe = "cargo", name = "Rust (cargo)", why = "installing tools written in Rust",
        brew = "rust", apt = "cargo", dnf = "cargo", pacman = "rust", zypper = "cargo", apk = "cargo" }),
    entry({ exe = "go", name = "Go", why = "installing tools written in Go",
        brew = "go", apt = "golang", dnf = "golang", pacman = "go", zypper = "go", apk = "go" }),

    -- Features.
    entry({ exe = "magick", name = "ImageMagick", why = "pictures in notes and notebooks",
        brew = "imagemagick", native = "imagemagick" }),
    entry({ exe = "pandoc", name = "pandoc", why = "exporting and importing notes", brew = "pandoc", native = "pandoc" }),
    entry({ exe = "xelatex", name = "XeLaTeX", why = "saving a note as a PDF",
        cask = "mactex-no-gui", apt = "texlive-xetex", dnf = "texlive-xetex",
        pacman = "texlive-bin texlive-latexextra texlive-fontsrecommended", zypper = "texlive-xetex" }),
    entry({ exe = "tesseract", name = "Tesseract", why = "reading the text in imported pictures",
        brew = "tesseract", apt = "tesseract-ocr", dnf = "tesseract", pacman = "tesseract tesseract-data-eng",
        zypper = "tesseract-ocr", apk = "tesseract-ocr" }),
    entry({ exe = "mpv", name = "mpv", why = "playing video and audio files", brew = "mpv", native = "mpv" }),
    entry({ exe = "lazygit", name = "lazygit", why = "the git screen",
        brew = "lazygit", dnf = "lazygit", pacman = "lazygit", zypper = "lazygit", apk = "lazygit",
        go = "github.com/jesseduffield/lazygit@latest" }),
    entry({ exe = "opencode", name = "opencode", why = "the opencode terminal",
        brew = "anomalyco/tap/opencode", npm = "opencode-ai" }),
    entry({ exe = "jupytext", name = "jupytext", why = "opening notebooks as Markdown", pipx = "jupytext" }),
    entry({ exe = "sourcekit-lsp", name = "the Swift toolchain", why = "Swift, and C family files in Xcode projects",
        manual = sysname_is_mac and "Run: xcode-select --install" or "Install the Swift toolchain from https://swift.org/install" }),

    -- Language servers (the ones lsp.lua turns on).
    entry({ exe = "lua-language-server", lsp = "lua_ls", name = "lua-language-server", why = "Lua",
        brew = "lua-language-server", pacman = "lua-language-server", apk = "lua-language-server" }),
    entry({ exe = "typescript-language-server", lsp = "ts_ls", name = "typescript-language-server", why = "TypeScript and JavaScript",
        brew = "typescript-language-server", npm = "typescript-language-server typescript" }),
    entry({ exe = "bash-language-server", lsp = "bashls", name = "bash-language-server", why = "shell scripts",
        brew = "bash-language-server", pacman = "bash-language-server", npm = "bash-language-server" }),
    entry({ exe = "vscode-css-language-server", lsp = "cssls", name = "vscode-langservers-extracted", why = "CSS, HTML and JSON",
        npm = "vscode-langservers-extracted" }),
    entry({ exe = "cssmodules-language-server", lsp = "cssmodules_ls", name = "cssmodules-language-server", why = "CSS Modules",
        npm = "cssmodules-language-server" }),
    entry({ exe = "texlab", lsp = "texlab", name = "texlab", why = "LaTeX", brew = "texlab", pacman = "texlab", cargo = "texlab" }),
    entry({ exe = "markdown-oxide", lsp = "markdown_oxide", name = "markdown-oxide", why = "Markdown notes",
        brew = "markdown-oxide", cargo = "markdown-oxide" }),
    entry({ exe = "oxlint", lsp = "oxlint", name = "oxlint", why = "linting JavaScript and TypeScript", npm = "oxlint" }),
    entry({ exe = "devsense-php-ls", lsp = "phptools", name = "devsense-php-ls", why = "PHP", npm = "devsense-php-ls" }),
    entry({ exe = "ruff", lsp = "ruff", name = "ruff", why = "linting Python",
        brew = "ruff", pacman = "ruff", apk = "ruff", pipx = "ruff" }),
    entry({ exe = "superhtml", lsp = "superhtml", name = "superhtml", why = "HTML", brew = "superhtml",
        manual = "Build it from https://github.com/kristoff-it/superhtml" }),
    entry({ exe = "tailwindcss-language-server", lsp = "tailwindcss", name = "tailwindcss-language-server", why = "Tailwind CSS",
        npm = "@tailwindcss/language-server" }),
    entry({ exe = "tinymist", lsp = "tinymist", name = "tinymist", why = "Typst", brew = "tinymist", pacman = "tinymist",
        manual = "Download it from https://github.com/Myriad-Dreamin/tinymist/releases" }),
    entry({ exe = "clangd", lsp = "clangd", name = "clangd", why = "C and C++",
        brew = "llvm", apt = "clangd", dnf = "clang-tools-extra", pacman = "clang", zypper = "clang-tools", apk = "clang-extra-tools" }),
    entry({ exe = "ty", lsp = "ty", name = "ty", why = "checking Python types", brew = "ty", pipx = "ty" }),
    entry({ exe = "sqruff", lsp = "sqruff", name = "sqruff", why = "SQL", brew = "sqruff", cargo = "sqruff", pipx = "sqruff" }),
    entry({ exe = "docker-language-server", lsp = "docker_language_server", name = "docker-language-server", why = "Dockerfiles",
        brew = "docker-language-server", go = "github.com/docker/docker-language-server/cmd/docker-language-server@latest" }),
    entry({ exe = "yaml-language-server", lsp = "yamlls", name = "yaml-language-server", why = "YAML",
        brew = "yaml-language-server", npm = "yaml-language-server" }),
    entry({ exe = "copilot-language-server", lsp = "copilot", name = "copilot-language-server", why = "GitHub Copilot suggestions",
        npm = "@github/copilot-language-server" }),
}

---Not a program but a place: the Python Neovim's notebook support runs in.
M.python_host = python_host

local function by_exe(exe)
    for _, item in ipairs(M.entries) do
        if item.exe == exe or (item.exes and vim.tbl_contains(item.exes, exe)) then return item end
    end
end

-- ----------------------------------------------------------------- the system

---Show a file in the system file manager: selected in Finder on a Mac, its
---folder elsewhere.
function M.reveal(path)
    if mac_now() then
        vim.system({ "open", "-R", path }, { detach = true })
    else
        vim.ui.open(vim.fn.isdirectory(path) == 1 and path or vim.fs.dirname(path))
    end
end

-- Where tools installed by npm, pipx, cargo, go and Homebrew end up. Neovim
-- started from a Dock icon or a bare shell may not have them on PATH.
function M.extend_path()
    local home = vim.env.HOME or ""
    local extra = {
        "/opt/homebrew/bin", "/opt/homebrew/opt/llvm/bin", "/usr/local/bin",
        "/home/linuxbrew/.linuxbrew/bin", home .. "/.linuxbrew/bin",
        home .. "/.local/bin", home .. "/.cargo/bin", home .. "/go/bin", home .. "/.npm-global/bin",
    }
    local have = {}
    for part in (vim.env.PATH or ""):gmatch("[^:]+") do have[part] = true end
    for _, dir in ipairs(extra) do
        if not have[dir] and vim.fn.isdirectory(dir) == 1 then
            vim.env.PATH = (vim.env.PATH or "") .. ":" .. dir
            have[dir] = true
        end
    end
end

local function exists(exe)
    if M._exists then return M._exists(exe) end
    return vim.fn.executable(exe) == 1
end

---Is this entry's program here?
function M.available(item)
    if item.exes then
        for _, exe in ipairs(item.exes) do if exists(exe) then return true end end
        return false
    end
    return exists(item.exe)
end

local native_managers = {
    { "apt-get", "apt", "sudo apt-get install -y " },
    { "dnf", "dnf", "sudo dnf install -y " },
    { "pacman", "pacman", "sudo pacman -S --needed --noconfirm " },
    { "zypper", "zypper", "sudo zypper --non-interactive install " },
    { "apk", "apk", "sudo apk add " },
}

local function is_root() return uv.getuid and uv.getuid() == 0 end

---The package manager of this machine for system packages.
function M.native_manager()
    if mac_now() then return nil end
    for _, manager in ipairs(native_managers) do
        if exists(manager[1]) then return manager end
    end
end

---A writable place for `npm install -g`; the system prefix often is not.
local function npm_command(packages)
    if exists("npm") then
        local prefix = vim.trim(vim.fn.system({ "npm", "config", "get", "prefix" }))
        if vim.v.shell_error == 0 and prefix ~= "" and uv.fs_access(prefix, "W") == false then
            return "npm install -g --prefix ~/.local " .. packages
        end
        return "npm install -g " .. packages
    end
    -- npm arrives with this very run; on Linux its system prefix is root's.
    return (mac_now() and "npm install -g " or "npm install -g --prefix ~/.local ") .. packages
end

---How to get this entry here: a list of shell commands, the manager used, and
---what the programs it needs first are. Nil and a reason when there is no way.
---@return string[]|nil commands, string via, string|nil reason
function M.plan(item, seen)
    seen = seen or {}
    if seen[item] then return nil, "", "a loop of requirements" end
    seen[item] = true

    local prerequisites = { npm = "node", pipx = "pipx", cargo = "cargo", go = "go" }
    local function with_prerequisite(tool, commands, via)
        local prereq_exe = prerequisites[tool]
        if exists(tool) then return commands, via end
        local prereq = by_exe(prereq_exe)
        local before = prereq and M.plan(prereq, seen)
        if not before then return nil, "", prereq_exe .. " is needed first and cannot be installed here" end
        return vim.list_extend(vim.deepcopy(before), commands), via
    end

    local native = M.native_manager()
    local candidates = {}
    local function add(kind, build) candidates[#candidates + 1] = { kind = kind, build = build } end

    local function native_command()
        if not native then return nil end
        local package = item[native[2]] or item.native
        return package and (native[3] .. package) or nil
    end
    local function brew_command()
        if not exists("brew") then return nil end
        if item.brew then return "brew install " .. item.brew end
        if item.cask then return "brew install --cask " .. item.cask end
    end

    if mac_now() then
        add("brew", brew_command)
    else
        add(native and native[2] or "system", native_command)
        add("brew", brew_command)
    end
    add("npm", function() return item.npm and { "npm", npm_command } end)
    add("pipx", function() return item.pipx and { "pipx", function(p) return "pipx install " .. p end } end)
    add("cargo", function() return item.cargo and { "cargo", function(p) return "cargo install " .. p end } end)
    add("go", function() return item.go and { "go", function(p) return "go install " .. p end } end)

    for _, candidate in ipairs(candidates) do
        local built = candidate.build()
        if type(built) == "string" then
            if is_root() then built = built:gsub("^sudo ", "") end
            return { built }, candidate.kind
        elseif type(built) == "table" then
            local tool = built[1]
            local commands, via = with_prerequisite(tool, { built[2](item[tool]) }, tool)
            if commands then return commands, via end
        end
    end

    if item.manual then return nil, "", item.manual end
    -- Nothing on this machine: Homebrew would do it, if it were here.
    if (item.brew or item.cask) and not exists("brew") then
        return nil, "", "no package manager found for it here (Homebrew would provide it: https://brew.sh)"
    end
    return nil, "", "no known way to install it on this machine"
end

-- ----------------------------------------------------------------- remembered

local function load_state()
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(state_file), "\n"))
    return ok and type(data) == "table" and data or { never = {} }
end

local function save_state(data)
    vim.fn.mkdir(vim.fn.fnamemodify(state_file, ":h"), "p")
    pcall(vim.fn.writefile, { vim.json.encode(data) }, state_file)
end

local function declined(item)
    local data = vim.fn.filereadable(state_file) == 1 and load_state() or { never = {} }
    return data.never and data.never[item.name] == true
end

local function decline_forever(item)
    local data = vim.fn.filereadable(state_file) == 1 and load_state() or { never = {} }
    data.never = data.never or {}
    data.never[item.name] = true
    save_state(data)
end

-- -------------------------------------------------------------------- running

local notify = function(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Tools" })
end

local running = {}

---Run shell commands in the terminal panel (so sudo can ask for a password),
---and call `done(ok)` when they finish.
local function run_in_terminal(commands, done)
    local status = vim.fn.tempname()
    local command = ("(%s); printf '%%s' $? > %s"):format(table.concat(commands, " && "), vim.fn.shellescape(status))
    local ok = pcall(function() require("terminals").send(command, { focus = true }) end)
    if not ok then
        notify("Could not open a terminal to install with", vim.log.levels.ERROR)
        return done(false)
    end
    local timer = uv.new_timer()
    local waited = 0
    timer:start(1000, 1000, vim.schedule_wrap(function()
        waited = waited + 1
        local finished = vim.fn.filereadable(status) == 1
        if finished or waited > 3600 then
            timer:stop()
            timer:close()
            local code = finished and vim.trim(table.concat(vim.fn.readfile(status), "")) or "timeout"
            pcall(vim.fn.delete, status)
            done(code == "0")
        end
    end))
end

---Install these entries (one confirmation, one terminal run).
---@param items table[]
---@param opts { reason?: string, after?: fun(ok: boolean) }|nil
function M.install(items, opts)
    opts = opts or {}
    local commands, names, blocked = {}, {}, {}
    local seen = {}
    for _, item in ipairs(items) do
        if not M.available(item) and not running[item.name] then
            local plan, _, reason = M.plan(item)
            if plan then
                names[#names + 1] = item.name
                for _, command in ipairs(plan) do
                    if not seen[command] then
                        seen[command] = true
                        commands[#commands + 1] = command
                    end
                end
            else
                blocked[#blocked + 1] = ("%s: %s"):format(item.name, reason or "cannot be installed here")
            end
        end
    end
    if #blocked > 0 then notify(table.concat(blocked, "\n"), vim.log.levels.WARN) end
    if #commands == 0 then
        if opts.after then opts.after(false) end
        return
    end

    local function go()
        for _, name in ipairs(names) do running[name] = true end
        notify("Installing " .. table.concat(names, ", ") .. " in the terminal ...")
        run_in_terminal(commands, function()
            M.extend_path()
            local failed = {}
            for _, item in ipairs(items) do
                running[item.name] = nil
                if not M.available(item) and vim.tbl_contains(names, item.name) then failed[#failed + 1] = item.name end
            end
            if #failed == 0 then
                notify("Installed " .. table.concat(names, ", "))
            else
                notify("Could not install " .. table.concat(failed, ", ") .. "; the terminal has the details", vim.log.levels.ERROR)
            end
            if opts.after then opts.after(#failed == 0) end
        end)
    end

    if vim.g.deps_auto_install then return go() end
    local text = ("%s\n\n%s%s\n\nInstall now?"):format(
        table.concat(names, ", ") .. (opts.reason and (" -- " .. opts.reason) or ""),
        "$ ", table.concat(commands, "\n$ "))
    local choice = vim.fn.confirm(text, "&Install\n&Not now\n&Never ask again", 2)
    if choice == 1 then
        go()
    else
        if choice == 3 then for _, item in ipairs(items) do decline_forever(item) end end
        if opts.after then opts.after(false) end
    end
end

---Make sure a program is there before something that needs it runs: calls
---`cb(true)` straight away if it is, otherwise offers to install it and calls
---`cb(true)` once it is, or `cb(false)` if not.
---@param exe string
---@param opts { reason?: string }|nil
---@param cb fun(ok: boolean)|nil
function M.ensure(exe, opts, cb)
    cb = cb or function() end
    opts = opts or {}
    local item = by_exe(exe)
    if not item then return cb(exists(exe)) end
    if M.available(item) then return cb(true) end
    if running[item.name] then return cb(false) end
    local plan, _, reason = M.plan(item)
    if not plan then
        notify(("%s is not installed. %s"):format(item.name, reason or ""), vim.log.levels.WARN)
        return cb(false)
    end
    M.install({ item }, { reason = opts.reason or item.why, after = cb })
end

-- ------------------------------------------------------- the notebook Python

function M.python_host_ready()
    return vim.fn.executable(python_host .. "/bin/python") == 1
end

---The venv notebooks run in (see Mac_Install/install.sh), built the same way.
function M.ensure_python_host(cb)
    cb = cb or function() end
    if M.python_host_ready() then return cb(true) end
    local item = { name = "the notebook Python", exe = "python-host" }
    local function build()
        local commands = {
            ("python3 -m venv %s"):format(vim.fn.shellescape(python_host)),
            ("%s/bin/pip install -q --upgrade pynvim jupyter_client ipykernel nbformat cairosvg pnglatex plotly kaleido pyperclip pillow nbconvert"):format(python_host),
            ("%s/bin/python -m ipykernel install --user --name python3 --display-name 'Python 3'"):format(python_host),
            "nvim --headless +UpdateRemotePlugins +qa",
        }
        local function go()
            notify("Setting up the notebook Python in the terminal ...")
            run_in_terminal(commands, function(ok)
                local ready = ok and M.python_host_ready()
                if ready then
                    vim.g.python3_host_prog = python_host .. "/bin/python"
                    notify("Notebook Python ready. Restart Neovim once so cells can run.")
                else
                    notify("Could not set up the notebook Python; the terminal has the details", vim.log.levels.ERROR)
                end
                cb(ready)
            end)
        end
        if vim.g.deps_auto_install then return go() end
        local choice = vim.fn.confirm(
            "Notebook cells run in a Python of their own that is not set up yet.\n\n$ "
                .. table.concat(commands, "\n$ ") .. "\n\nSet it up now?",
            "&Set up\n&Not now\n&Never ask again", 2)
        if choice == 1 then go() else
            if choice == 3 then decline_forever(item) end
            cb(false)
        end
    end
    if declined(item) then return cb(false) end
    M.ensure("python3", { reason = "needed for the notebook Python" }, function(ok)
        if ok then build() else cb(false) end
    end)
end

-- --------------------------------------------------------------- the surface

---Everything with whether it is here.
function M.status()
    local rows = {}
    for _, item in ipairs(M.entries) do
        rows[#rows + 1] = { item = item, ok = M.available(item) }
    end
    return rows
end

local function missing_items(filter)
    local items = {}
    for _, row in ipairs(M.status()) do
        if not row.ok and (not filter or filter(row.item)) then items[#items + 1] = row.item end
    end
    return items
end

function M.pick()
    local rows = M.status()
    local missing = {}
    for _, row in ipairs(rows) do if not row.ok then missing[#missing + 1] = row.item end end
    if #missing == 0 then
        notify("Every tool the configuration uses is installed")
        return
    end
    local choices = { { label = ("Install all %d missing"):format(#missing), all = true } }
    for _, item in ipairs(missing) do
        local _, via, reason = M.plan(item)
        choices[#choices + 1] = {
            label = ("%s -- %s (%s)"):format(item.name, item.why, reason and "manual" or via),
            item = item,
        }
    end
    vim.ui.select(choices, {
        prompt = "Missing tools",
        format_item = function(choice) return choice.label end,
    }, function(choice)
        if not choice then return end
        M.install(choice.all and missing or { choice.item })
    end)
end

-- -------------------------------------------------------------- the triggers

local asked = {}

---A language server's file is open and its program is not there.
local function check_language_servers(buf)
    local filetype = vim.bo[buf].filetype
    if filetype == "" or vim.bo[buf].buftype ~= "" then return end
    for _, item in ipairs(M.entries) do
        if item.lsp and not asked[item.name] and not M.available(item) and not declined(item) then
            local ok, config = pcall(function() return vim.lsp.config[item.lsp] end)
            if ok and config and config.filetypes and vim.tbl_contains(config.filetypes, filetype) then
                asked[item.name] = true
                vim.schedule(function()
                    M.ensure(item.exe, { reason = "the language server for " .. item.why }, function(installed)
                        if installed then
                            vim.lsp.enable(item.lsp, false)
                            vim.lsp.enable(item.lsp, true)
                        end
                    end)
                end)
            end
        end
    end
end

---Once after start, for the tools pickers and parsers lean on.
local function check_essentials()
    local missing = missing_items(function(item) return item.essential and not declined(item) and not asked[item.name] end)
    if #missing == 0 then return end
    for _, item in ipairs(missing) do asked[item.name] = true end
    M.install(missing, { reason = "used by search, syntax highlighting and git" })
end

function M.setup()
    M.extend_path()

    vim.api.nvim_create_user_command("Deps", M.pick, { desc = "List missing tools and install them" })
    vim.api.nvim_create_user_command("DepsInstall", function(args)
        local name = vim.trim(args.args)
        if name == "" then
            local missing = missing_items()
            if #missing == 0 then return notify("Every tool the configuration uses is installed") end
            return M.install(missing)
        end
        local item = by_exe(name)
        if not item then return notify("Unknown tool: " .. name, vim.log.levels.WARN) end
        M.install({ item })
    end, {
        nargs = "?",
        desc = "Install every missing tool, or just the one named",
        complete = function()
            local names = {}
            for _, item in ipairs(M.entries) do names[#names + 1] = item.exe or item.exes[1] end
            return names
        end,
    })

    vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("DepsLanguageServers", { clear = true }),
        callback = function(args)
            if #vim.api.nvim_list_uis() == 0 or vim.env.NVIM_DEPS_QUIET then return end
            check_language_servers(args.buf)
        end,
    })

    -- After the first screen is up and the user has had a moment, not during it.
    if #vim.api.nvim_list_uis() > 0 and not vim.env.NVIM_DEPS_QUIET then
        vim.api.nvim_create_autocmd("VimEnter", {
            once = true,
            callback = function() vim.defer_fn(check_essentials, 4000) end,
        })
    end
end

return M
