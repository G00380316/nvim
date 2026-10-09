---Running a file through the zsh `run` / `runtest` functions, from wherever the
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
            tex = true, ts = true, tsx = true, typ = true, zsh = true,
        },
        names = {
            Containerfile = true,
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
            ts = true, tsx = true, zsh = true,
        },
        names = {},
    },
}

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
    local command = ("(cd %s && %s %s%s)"):format(
        vim.fn.shellescape(vim.fn.fnamemodify(path, ":p:h")),
        name,
        vim.fn.shellescape(basename),
        (args and args ~= "") and (" " .. args) or ""
    )
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
