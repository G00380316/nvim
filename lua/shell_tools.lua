---Small shell chores from ~/.zshrc, reachable from the palette so they need no
---keys and no trip to a terminal of your own. Each one runs in the project's
---terminal panel, so zsh functions and aliases are still available.
local M = {}

local function terminal_send(command)
    return require("terminals").send(command, { focus = true })
end

local function project_root()
    return require("terminals").launch_cwd()
end

---The file the command should act on: the one under the cursor in Oil, else
---the current buffer's.
local function target_file()
    local ok, oil = pcall(require, "oil")
    if ok and vim.bo.filetype == "oil" then
        local entry = oil.get_cursor_entry()
        local dir = oil.get_current_dir()
        if entry and dir and entry.type == "file" then return dir .. entry.name end
        return nil
    end
    local name = vim.api.nvim_buf_get_name(0)
    return name ~= "" and name or nil
end

local function prompt(label, callback)
    vim.ui.input({ prompt = label .. ": " }, function(value)
        value = value and vim.trim(value) or ""
        if value ~= "" then callback(value) end
    end)
end

local extractors = {
    { "%.tar%.bz2$", "tar xvjf" },
    { "%.tbz2?$", "tar xvjf" },
    { "%.tar%.gz$", "tar xvzf" },
    { "%.tgz$", "tar xvzf" },
    { "%.tar%.xz$", "tar xvJf" },
    { "%.tar$", "tar xvf" },
    { "%.zip$", "unzip" },
    { "%.gz$", "gunzip -k" },
    { "%.7z$", "7z x" },
    { "%.rar$", "unrar x" },
}

function M.extract()
    local file = target_file()
    if not file then
        vim.notify("No file to extract", vim.log.levels.WARN, { title = "Extract" })
        return
    end
    for _, e in ipairs(extractors) do
        if file:lower():match(e[1]) then
            terminal_send(("(cd %s && %s %s)"):format(
                vim.fn.shellescape(vim.fn.fnamemodify(file, ":h")),
                e[2],
                vim.fn.shellescape(vim.fn.fnamemodify(file, ":t"))
            ))
            return
        end
    end
    vim.notify("Unsupported archive: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.WARN, { title = "Extract" })
end

function M.python_env()
    terminal_send(("cd %s && python3 -m venv .venv && source .venv/bin/activate"):format(
        vim.fn.shellescape(project_root())
    ))
end

function M.pip_install()
    prompt("pip install", function(pkg) terminal_send("python3 -m pip install " .. pkg) end)
end

function M.pipx_install()
    prompt("pipx install", function(pkg) terminal_send("pipx install " .. pkg) end)
end

function M.port()
    prompt("Port", function(port)
        if not port:match("^%d+$") then
            vim.notify("Not a port number: " .. port, vim.log.levels.WARN, { title = "Port" })
            return
        end
        terminal_send("lsof -i :" .. port)
    end)
end

function M.cheat()
    prompt("Cheat sheet (e.g. python/lambda)", function(query)
        terminal_send("~/.config/scripts/cht.sh " .. vim.fn.shellescape(query))
    end)
end

function M.setup()
    local cmds = {
        { "PythonEnv", M.python_env, "Create and activate a .venv in the project (zsh: setup python)" },
        { "PipInstall", M.pip_install, "pip install a package (asks which)" },
        { "PipxInstall", M.pipx_install, "pipx install a tool (asks which)" },
        { "Extract", M.extract, "Extract the archive under the cursor or in this buffer" },
        { "PortCheck", M.port, "Show what is listening on a port (asks which)" },
        { "CheatSheet", M.cheat, "Look something up on cht.sh (asks what)" },
    }
    for _, c in ipairs(cmds) do
        vim.api.nvim_create_user_command(c[1], c[2], { nargs = 0, desc = c[3] })
    end
end

return M
