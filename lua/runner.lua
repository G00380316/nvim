---Running a file through the zsh `run` / `runtest` functions (or, where the shell
---has none, a plain command for the language), from wherever the
---file is: the buffer you are in, the entry under the cursor in the explorer, or
---a file picked in a picker -- with arguments if you want to give some.
local M = {}

M.runners = {
    run = {
        label = "run",
        extensions = {
            bash = true, c = true, cc = true, cjs = true, cpp = true, cts = true,
            cxx = true, go = true, htm = true, html = true, java = true,
            js = true, jsx = true, lua = true, m = true, markdown = true,
            md = true, mjs = true, mm = true, mts = true, php = true, py = true,
            rb = true, rs = true, sh = true, sql = true, swift = true,
            tex = true, ts = true, tsx = true, typ = true, zip = true, zsh = true,
            -- archives and data files `run` unpacks or prints
            tar = true, tgz = true, tbz2 = true, txz = true, gz = true, bz2 = true, xz = true,
            json = true, csv = true, yaml = true, yml = true, toml = true, xml = true, plist = true,
            db = true, sqlite = true, sqlite3 = true, ["7z"] = true, rar = true, dmg = true,
            kt = true, kts = true, pl = true, r = true, jl = true, zig = true, hs = true, dart = true,
            docx = true, pdf = true,
        },
        names = {
            Containerfile = true,
            ["requirements.txt"] = true,
            ["package.json"] = true,
            ["docker-compose.yml"] = true,
            ["docker-compose.yaml"] = true,
            ["compose.yml"] = true,
            ["compose.yaml"] = true,
            ["Cargo.toml"] = true,
            ["go.mod"] = true,
            ["Package.swift"] = true,
            Brewfile = true,
            ["CMakeLists.txt"] = true,
            Dockerfile = true,
            GNUmakefile = true,
            Makefile = true,
            makefile = true,
        },
    },
    runtest = {
        label = "test",
        extensions = {
            bash = true, cjs = true, cts = true, go = true, java = true,
            js = true, jsx = true, lua = true, mjs = true, mts = true,
            php = true, py = true, rs = true, sh = true, swift = true,
            ts = true, tsx = true, zsh = true, rb = true, dart = true, kt = true,
        },
        names = {},
    },
}

-- What to type when the shell has no `run` / `runtest` function (no ~/.zshrc, a
-- server, a fresh machine). `f` is the quoted file name and `a` the arguments
-- as typed, already prefixed with a space. Compiled languages build into a
-- scratch binary, so nothing lands beside the source.
local scratch = [["${TMPDIR:-/tmp}/nvim_run_$$"]]
local function compiled(compiler)
    return function(f, a)
        return ("%s %s -o %s && %s%s; rm -f %s"):format(compiler, f, scratch, scratch, a, scratch)
    end
end
local function interpreter(program)
    return function(f, a) return ("%s %s%s"):format(program, f, a) end
end

M.fallbacks = {
    run = {
        extensions = {
            py = interpreter("python3"), js = interpreter("node"), mjs = interpreter("node"),
            cjs = interpreter("node"), ts = interpreter("npx --yes tsx"), tsx = interpreter("npx --yes tsx"),
            mts = interpreter("npx --yes tsx"), cts = interpreter("npx --yes tsx"),
            lua = interpreter("nvim -l"), sh = interpreter("sh"), bash = interpreter("bash"),
            zsh = interpreter("zsh"), rb = interpreter("ruby"), php = interpreter("php"),
            pl = interpreter("perl"), r = interpreter("Rscript"), jl = interpreter("julia"),
            hs = interpreter("runghc"), swift = interpreter("swift"), java = interpreter("java"),
            go = interpreter("go run"), dart = interpreter("dart run"), kts = interpreter("kotlin"),
            sql = interpreter("sqlite3 :memory: <"),
            c = compiled("cc"), cc = compiled("c++"), cpp = compiled("c++"), cxx = compiled("c++"),
            rs = compiled("rustc"), zig = interpreter("zig run"),
            html = interpreter("open"), htm = interpreter("open"), pdf = interpreter("open"),
            md = interpreter("open"), markdown = interpreter("open"), docx = interpreter("open"),
        },
        names = {
            Makefile = "make", makefile = "make", GNUmakefile = "make",
            ["Cargo.toml"] = "cargo run", ["go.mod"] = "go run .", ["package.json"] = "npm start",
            ["Package.swift"] = "swift run", Brewfile = "brew bundle",
            ["docker-compose.yml"] = "docker compose up", ["docker-compose.yaml"] = "docker compose up",
            ["compose.yml"] = "docker compose up", ["compose.yaml"] = "docker compose up",
            Dockerfile = "docker build .", Containerfile = "docker build .",
            ["requirements.txt"] = "python3 -m pip install -r requirements.txt",
            ["CMakeLists.txt"] = "cmake -S . -B build && cmake --build build",
        },
    },
    runtest = {
        extensions = {
            py = interpreter("python3 -m pytest"), go = function(_, a) return "go test ./..." .. a end,
            rs = function(_, a) return "cargo test" .. a end,
            js = function(_, a) return "npm test --" .. a end, jsx = function(_, a) return "npm test --" .. a end,
            ts = function(_, a) return "npm test --" .. a end, tsx = function(_, a) return "npm test --" .. a end,
            mjs = function(_, a) return "npm test --" .. a end, cjs = function(_, a) return "npm test --" .. a end,
            rb = interpreter("rspec"), php = interpreter("phpunit"),
            swift = function(_, a) return "swift test" .. a end, dart = interpreter("dart test"),
            java = function(_, a) return "mvn test" .. a end,
        },
        names = {},
    },
}

---The command to type for `name` on this file when the shell function is
---missing, or nil when there is nothing sensible to fall back to.
local function fallback_command(name, basename, extension, args)
    local table_ = M.fallbacks[name]
    local suffix = (args and args ~= "") and (" " .. args) or ""
    local named = table_.names[basename]
    if named then return named .. suffix end
    local build = table_.extensions[extension]
    if build then return build(vim.fn.shellescape(basename), suffix) end
end

-- The arguments last given for each file, offered again next time.
local last_args = {}

---The file an action should act on, in order: the entry under the cursor when
---in the explorer; otherwise the file in the editor (the sidebar and terminal
---are not what is being worked on).
---@return string? path, integer? buf
local function resolve()
    local current = vim.api.nvim_get_current_buf()
    if vim.bo[current].filetype == "oil" then
        local ok, oil = pcall(require, "oil")
        local entry = ok and oil.get_cursor_entry()
        local dir = ok and oil.get_current_dir()
        if entry and dir and entry.type == "file" then return dir .. entry.name end
        return nil
    end

    local buf = current
    if not require("buffers").is_editor(buf) then
        local win = require("ide_layout").find_editor_window()
        buf = win and vim.api.nvim_win_get_buf(win) or buf
    end
    local path = vim.api.nvim_buf_get_name(buf)
    if path == "" then return nil end
    return path, buf
end

local function send(name, path, args)
    local runner = M.runners[name]
    local basename = vim.fn.fnamemodify(path, ":t")
    local extension = vim.fn.fnamemodify(path, ":e"):lower()

    if not (runner.names[basename] or runner.extensions[extension]) then
        local kind = extension ~= "" and ("." .. extension) or basename
        vim.notify(("%s: nothing is defined for %s files"):format(name, kind), vim.log.levels.WARN, { title = name })
        return
    end

    -- A subshell, so a build artefact lands beside its source without the
    -- terminal you were using changing directory underneath you. The arguments
    -- are the shell's to read, as typed: quotes, globs and variables work.
    local call = ("%s %s%s"):format(name, vim.fn.shellescape(basename), (args and args ~= "") and (" " .. args) or "")
    -- Your own function when the shell has one; otherwise a plain command.
    local fallback = fallback_command(name, basename, extension, args)
    if fallback then
        call = ("if type %s >/dev/null 2>&1; then %s; else %s; fi"):format(name, call, fallback)
    end
    local command = ("(cd %s && %s)"):format(vim.fn.shellescape(vim.fn.fnamemodify(path, ":p:h")), call)
    -- Output shows in the panel and you stay where you are; <C-t> goes down for
    -- a program that wants input.
    require("terminals").send(command, { focus = false })
end

---Run or test a file.
---@param name "run"|"runtest"
---@param opts? { path?: string, ask?: boolean, args?: string }
function M.run(name, opts)
    opts = opts or {}
    local runner = M.runners[name]
    local path, buf = opts.path, nil
    if not path then path, buf = resolve() end
    if not path then
        vim.notify("No file to " .. runner.label, vim.log.levels.WARN, { title = name })
        return
    end

    if buf and vim.bo[buf].modified then
        vim.api.nvim_buf_call(buf, function() vim.cmd("silent! write") end)
    end

    if not opts.ask then
        send(name, path, opts.args)
        return
    end

    vim.ui.input({
        prompt = ("%s %s with arguments: "):format(runner.label, vim.fn.fnamemodify(path, ":t")),
        default = last_args[path] or "",
    }, function(args)
        if args == nil then return end -- cancelled
        last_args[path] = args
        send(name, path, args)
    end)
end

return M
