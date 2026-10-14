local M = {}

-- A shell's working directory changes with `cd`, and Neovim has no way to
-- observe that from the outside. It is sampled from the OS instead and cached:
-- the lookup costs ~100ms, far too slow to run during a statusline redraw.
local cwd_cache = {}
local refresh_timer
local scan_timer

local function terminal_pid(bufnr)
    local ok, job = pcall(function() return vim.b[bufnr].terminal_job_id end)
    if not ok or not job then return nil end
    local pid_ok, pid = pcall(vim.fn.jobpid, job)
    return pid_ok and pid or nil
end

local function terminal_workspace(bufnr)
    local assigned = vim.b[bufnr].floaterm_workspace
    if type(assigned) == "string" and assigned ~= "" then
        return vim.fs.normalize(assigned)
    end

    -- Backfill terminals created before project contexts were enabled. Their
    -- launch cwd is stable even if the shell has since changed directory.
    local launched = vim.fn.getbufvar(bufnr, "floaterm_cwd")
    if type(launched) == "string" and launched ~= "" then
        assigned = require("workspace").find(launched)
    end
    assigned = assigned or require("workspace").get()
    vim.b[bufnr].floaterm_workspace = assigned
    return vim.fs.normalize(assigned)
end

---The buffer the user is actually working in. Terminal actions are often
---triggered from the panel itself, where the current buffer is a shell and
---says nothing about which file is open.
local function editor_buffer()
    local current = vim.api.nvim_get_current_buf()
    if vim.bo[current].buftype == "" and vim.api.nvim_buf_get_name(current) ~= "" then
        return current
    end

    local win = require("ide_layout").find_editor_window()
    if not win then return nil end
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].buftype == "" and vim.api.nvim_buf_get_name(buf) ~= "" then
        return buf
    end
end

---The directory of the file in the editor, if there is one.
local function editor_directory()
    local buf = editor_buffer()
    if not buf then return nil end

    local name = vim.api.nvim_buf_get_name(buf)
    if name == "" then return nil end

    local directory = vim.fs.dirname(vim.fn.fnamemodify(name, ":p"))
    directory = vim.fs.normalize(vim.uv.fs_realpath(directory) or directory)
    return vim.fn.isdirectory(directory) == 1 and directory or nil
end

---Where a new terminal should start.
---
---The project root, and only the project root. Every shell in a context then
---agrees on what "here" means, and a relative path copied from one works in
---the next. This used to drop you in the file's own directory whenever that
---file was from outside the project, which made the answer depend on which
---buffer happened to be focused when you reached for a shell.
---
---`opts.here` is the other thing, asked for by its own key: the directory of
---the file you are looking at, wherever that is.
---
---The terminal belongs to the current project either way -- ownership comes
---from b:floaterm_workspace, set when the buffer is created -- so a shell
---started outside the root still appears in this project's terminal list.
---@param opts? { here?: boolean }
function M.launch_cwd(opts)
    local project = vim.fs.normalize(require("workspace").get())
    if not (opts and opts.here) then return project end
    return editor_directory() or project
end

---Terminal buffers for one project in floaterm's own order, so cycling
---matches its numbering without leaking shells from another project context.
function M.list(project)
    local ok, bufnrs = pcall(vim.fn["floaterm#buflist#gather"])
    if not ok or type(bufnrs) ~= "table" then return {} end
    project = vim.fs.normalize(project or require("workspace").get())
    return vim.tbl_filter(function(bufnr)
        return vim.api.nvim_buf_is_valid(bufnr)
            and terminal_workspace(bufnr) == project
    end, bufnrs)
end

---The terminal you were last in, remembered so that running something goes to
---the shell you were already using rather than another one.
local last_focused

local function live_terminal(bufnr)
    return type(bufnr) == "number"
        and vim.api.nvim_buf_is_valid(bufnr)
        and vim.bo[bufnr].filetype == "floaterm"
        and vim.b[bufnr].terminal_job_id ~= nil
end

---Where a command should be sent: the terminal you are in, else the last one
---you used in this project, else any in this project, else the last one used
---anywhere. nil only when there is no terminal to use.
---@return integer?
function M.target()
    local current = vim.api.nvim_get_current_buf()
    if live_terminal(current) then return current end

    local project = M.list()
    if live_terminal(last_focused) and vim.tbl_contains(project, last_focused) then
        return last_focused
    end
    for _, bufnr in ipairs(project) do
        if live_terminal(bufnr) then return bufnr end
    end
    if live_terminal(last_focused) then return last_focused end
end

local function sample_cwd(bufnr)
    local pid = terminal_pid(bufnr)
    if not pid then return end

    vim.system(
        { "lsof", "-a", "-p", tostring(pid), "-d", "cwd", "-Fn" },
        { text = true },
        function(result)
            if result.code ~= 0 or not result.stdout then return end
            -- -Fn output is one field per line: "p<pid>", "fcwd", "n<path>".
            local path = result.stdout:match("n(/[^\r\n]*)")
            if not path then return end
            vim.schedule(function()
                if cwd_cache[bufnr] ~= path then
                    cwd_cache[bufnr] = path
                    pcall(vim.cmd.redrawstatus)
                end
            end)
        end
    )
end

function M.refresh()
    for _, bufnr in ipairs(M.list()) do
        sample_cwd(bufnr)
    end
end

---Display name for a terminal: its current directory, home-relative.
function M.name(bufnr)
    local path = cwd_cache[bufnr]
    if not path then
        local launched = vim.fn.getbufvar(bufnr, "floaterm_cwd")
        if type(launched) == "string" and launched ~= "" then path = launched end
    end
    if not path then return "terminal" end
    -- The folder's own name; its parent is added only if another terminal
    -- is in a folder called the same.
    local peers = {}
    for _, other in ipairs(M.list()) do
        local p = cwd_cache[other] or vim.fn.getbufvar(other, "floaterm_cwd")
        if type(p) == "string" and p ~= "" then peers[#peers + 1] = p end
    end
    return require("names").label(path, peers)
end

local function terminal_window(bufnr)
    for _, win in ipairs(vim.api.nvim_list_wins()) do
        if vim.api.nvim_win_get_buf(win) == bufnr then return win end
    end
end

local function any_terminal_window()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "floaterm" then return win end
    end
end

---Focus a terminal. Already-visible terminals are focused in place rather than
---being re-displayed somewhere else, so a split panel keeps its layout.
---
---Normal mode, not terminal mode. Arriving at a terminal is usually about
---reading what it said; `opts.insert` is for the callers that know you are
---about to type, which is sending it a command.
---@param bufnr integer
---@param opts? { insert?: boolean }
function M.focus(bufnr, opts)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end

    local win = terminal_window(bufnr)
    if not win then
        win = any_terminal_window()
        if win then
            vim.api.nvim_win_set_buf(win, bufnr)
        else
            pcall(vim.fn["floaterm#show"], 0, bufnr, "")
            win = terminal_window(bufnr)
        end
    end

    if win and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
        if opts and opts.insert then
            vim.schedule(function()
                if vim.bo.filetype == "floaterm" then vim.cmd("startinsert") end
            end)
        end
    end
end

-- ------------------------------------------------------ full screen, app mode

local full_win
local full_origin

---Whether a terminal is currently shown full screen.
function M.full_active()
    return full_win ~= nil and vim.api.nvim_win_is_valid(full_win)
end

---Terminal programs that are applications -- opencode, vim, htop -- need every
---key, and Neovim's own normal-mode keys get in the way: <Tab> switches buffer
---instead of reaching the program. A terminal marked as an app is always in
---terminal mode when you are in it, and <Tab> / <S-Tab> pressed in its normal
---mode still go to the program.
---@param bufnr integer
---@param on? boolean default true
function M.mark_app(bufnr, on)
    if not vim.api.nvim_buf_is_valid(bufnr) then return end
    on = on ~= false
    vim.b[bufnr].terminal_app = on or nil

    local function send_key(sequence)
        return function()
            local job = vim.b[bufnr].terminal_job_id
            if job then vim.fn.chansend(job, sequence) end
            vim.cmd("startinsert")
        end
    end

    -- A program that scrolls with the mouse wheel cannot be scrolled here: the
    -- mouse is off in this config, so the wheel never reaches it. These send the
    -- keys such programs scroll with instead -- opencode's chat takes PageUp and
    -- PageDown, and Home / End for the first and last message.
    local typed_keys = {
        { "<C-Up>", "\27[5~", "Scroll the program up a page (PageUp)" },
        { "<C-Down>", "\27[6~", "Scroll the program down a page (PageDown)" },
        { "<C-PageUp>", "\27[H", "Send Home: the top of what the program shows" },
        { "<C-PageDown>", "\27[F", "Send End: the bottom of what the program shows" },
    }

    if on then
        vim.keymap.set("n", "<Tab>", send_key("\t"), { buffer = bufnr, desc = "Send <Tab> to the program" })
        vim.keymap.set("n", "<S-Tab>", send_key("\27[Z"), { buffer = bufnr, desc = "Send <S-Tab> to the program" })
        for _, key in ipairs(typed_keys) do
            vim.keymap.set("t", key[1], function()
                local job = vim.b[bufnr].terminal_job_id
                if job then vim.fn.chansend(job, key[2]) end
            end, { buffer = bufnr, desc = key[3] })
        end
    else
        pcall(vim.keymap.del, "n", "<Tab>", { buffer = bufnr })
        pcall(vim.keymap.del, "n", "<S-Tab>", { buffer = bufnr })
        for _, key in ipairs(typed_keys) do pcall(vim.keymap.del, "t", key[1], { buffer = bufnr }) end
    end
end

---Toggle app mode on the terminal you are in.
function M.toggle_app()
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype ~= "floaterm" then
        vim.notify("Go to a terminal first", vim.log.levels.INFO, { title = "Terminal" })
        return
    end
    local on = not vim.b[buf].terminal_app
    M.mark_app(buf, on)
    if on then vim.cmd("startinsert") end
    vim.notify(on and "App mode: every key goes to the program" or "App mode off", vim.log.levels.INFO, { title = "Terminal" })
end

local function full_size()
    -- The global statusline is the last row; the command line sits below it.
    return vim.o.columns, math.max(5, vim.o.lines - vim.o.cmdheight - 1)
end

---Show the terminal over the whole editor, or put it back in its panel.
---Running something big -- opencode, a long log -- does not fit in the panel;
---this is the same terminal at full size, and toggling again returns to the
---layout exactly as it was, because the layout was never touched.
---@param bufnr? integer
function M.toggle_full(bufnr)
    if M.full_active() then
        local buf = vim.api.nvim_win_get_buf(full_win)
        -- Asked for a different terminal while one is already full: show that
        -- one, rather than putting the first back.
        if bufnr and bufnr ~= buf and vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_win_set_buf(full_win, bufnr)
            M.mark_app(bufnr, true)
            vim.api.nvim_set_current_win(full_win)
            vim.cmd("startinsert")
            return
        end
        pcall(vim.api.nvim_win_close, full_win, true)
        full_win = nil
        -- Back to where you were: the window the full-screen view was opened
        -- from, so hiding it is not also a trip to the panel.
        local origin = full_origin
        full_origin = nil
        if origin and vim.api.nvim_win_is_valid(origin) and vim.api.nvim_win_get_config(origin).relative == "" then
            vim.api.nvim_set_current_win(origin)
            if vim.bo[vim.api.nvim_win_get_buf(origin)].buftype ~= "terminal" then vim.cmd("stopinsert") end
        else
            local panel = terminal_window(buf)
            if panel then
                vim.api.nvim_set_current_win(panel)
                if vim.b[buf].terminal_app then vim.cmd("startinsert") end
            end
        end
        return
    end

    bufnr = bufnr
    if not bufnr then
        local current = vim.api.nvim_get_current_buf()
        bufnr = vim.bo[current].filetype == "floaterm" and current or M.target()
    end
    if not bufnr then
        vim.notify("No terminal to show full screen", vim.log.levels.WARN, { title = "Terminal" })
        return
    end

    full_origin = vim.api.nvim_get_current_win()
    local width, height = full_size()
    full_win = vim.api.nvim_open_win(bufnr, true, {
        relative = "editor",
        row = 0,
        col = 0,
        width = width,
        height = height,
        style = "minimal",
        border = "none",
        zindex = 80,
    })
    vim.w[full_win].terminal_full = true
    -- Full screen is for an application: it gets every key.
    M.mark_app(bufnr, true)
    vim.cmd("startinsert")
end

---A new terminal running opencode, full screen.
function M.opencode()
    if vim.fn.executable("opencode") == 0 then
        vim.notify("opencode is not installed (brew install anomalyco/tap/opencode)", vim.log.levels.WARN, { title = "Terminal" })
        return
    end
    -- Already running: that is the one to show, not a second.
    for _, buf in ipairs(M.list()) do
        if vim.b[buf].terminal_full_program and vim.b[buf].terminal_job_id then
            if M.full_active() and vim.api.nvim_win_get_buf(full_win) == buf then
                M.toggle_full() -- already on screen: hide it
            else
                M.toggle_full(buf)
            end
            return
        end
    end

    -- From a full-screen terminal, TerminalNew would try to split the float.
    if M.full_active() then M.toggle_full() end
    vim.cmd("TerminalNew")
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype ~= "floaterm" then return end
    M.send("opencode", { focus = false, wait = true })
    M.toggle_full(buf)
    vim.b[buf].terminal_full_program = true
    vim.b[buf].terminal_full_since = vim.uv.hrtime()
end

-- --------------------------------------------------------- closing cleanly

---Every process below `shell_pid`, deepest first.
---@param shell_pid integer
---@return integer[]
local function descendant_pids(shell_pid)
    local result = vim.system({ "ps", "-A", "-o", "pid=,ppid=" }, { text = true }):wait(2000)
    if result.code ~= 0 then return {} end
    local children = {}
    for line in (result.stdout or ""):gmatch("[^\n]+") do
        local pid, ppid = line:match("^%s*(%d+)%s+(%d+)")
        if pid then
            ppid = tonumber(ppid)
            children[ppid] = children[ppid] or {}
            table.insert(children[ppid], tonumber(pid))
        end
    end
    local order, stack = {}, { shell_pid }
    while #stack > 0 do
        local pid = table.remove(stack)
        for _, child in ipairs(children[pid] or {}) do
            table.insert(order, 1, child) -- later finds go first: deepest ends up first
            stack[#stack + 1] = child
        end
    end
    return order
end

local function alive(pid)
    return vim.uv.kill(pid, 0) == 0
end

---Stop everything a terminal started. Closing a terminal hangs up its shell, but
---a program that ignores the hang-up -- opencode does, at times -- carries on
---with nothing to show it on. Ask the programs to quit, wait a moment, then
---make the ones still there stop.
---@param shell_pid? integer
---@param wait_ms? integer how long to give them before forcing it (default 800)
function M.stop_programs(shell_pid, wait_ms)
    if not shell_pid then return end
    local pids = descendant_pids(shell_pid)
    if #pids == 0 then return end

    for _, pid in ipairs(pids) do pcall(vim.uv.kill, pid, "sigterm") end
    vim.wait(wait_ms or 800, function()
        for _, pid in ipairs(pids) do
            if alive(pid) then return false end
        end
        return true
    end, 50)
    for _, pid in ipairs(pids) do
        if alive(pid) then pcall(vim.uv.kill, pid, "sigkill") end
    end
end

---Run a program in a terminal of its own, full screen, and show it again if it
---is already running.
---@param command string what to type
---@param marker string a name that identifies the running program
---@param missing? string message if the program cannot run
local function launch_full(command, marker, missing)
    for _, buf in ipairs(M.list()) do
        if vim.b[buf].terminal_job_id and vim.b[buf].terminal_launched == marker then
            if M.full_active() and vim.api.nvim_win_get_buf(full_win) == buf then
                M.toggle_full() -- already on screen: hide it
            else
                M.toggle_full(buf)
            end
            return
        end
    end

    if M.full_active() then M.toggle_full() end
    vim.cmd("TerminalNew")
    local buf = vim.api.nvim_get_current_buf()
    if vim.bo[buf].filetype ~= "floaterm" then return end
    vim.b[buf].terminal_launched = marker
    M.send(command, { focus = false, wait = true })
    M.toggle_full(buf)
    vim.b[buf].terminal_full_program = true
    vim.b[buf].terminal_full_since = vim.uv.hrtime()
end

---LeetCode in a Neovim of its own. The plugin refuses to start in a Neovim that
---already has files open ("contains listed buffers"); it is meant to be the
---whole editor. So it gets one: a second Neovim, using this same config, in a
---full-screen terminal. Quitting it (its own Exit) returns here, and the
---terminal view can be hidden and brought back like any other.
function M.leetcode()
    -- NVIM_NESTED: that instance must not record its folder as a workspace or
    -- overwrite a project's saved session.
    launch_full("NVIM_NESTED=1 nvim leetcode.nvim", "leetcode")
end

-- ------------------------------------------------------- noticing programs

-- Programs that take the whole screen. Typing `opencode` in any terminal -- not
-- only through the OpenCode action -- puts it in app mode, and the ones in
-- full_apps also go full screen, then back when the program exits.
local app_programs = {
    opencode = true, claude = true, codex = true, nvim = true, vim = true, vi = true,
    htop = true, btop = true, top = true, less = true, man = true, lazygit = true,
    ssh = false, node = false,
}
local full_programs = { opencode = true, ["leetcode.nvim"] = true }

---The names of the programs running under a shell, from one process listing.
---@param shell_pid integer
---@param rows { pid: integer, ppid: integer, names: string[] }[]
---@return table<string, boolean>
local function descendants(shell_pid, rows)
    local children = {}
    for _, row in ipairs(rows) do
        children[row.ppid] = children[row.ppid] or {}
        table.insert(children[row.ppid], row)
    end
    local found, stack = {}, { shell_pid }
    while #stack > 0 do
        local pid = table.remove(stack)
        for _, row in ipairs(children[pid] or {}) do
            for _, name in ipairs(row.names) do found[name] = true end
            stack[#stack + 1] = row.pid
        end
    end
    return found
end

local scanning = false

---Look at what each terminal is running and act on programs that want the screen.
function M.scan_programs()
    if scanning then return end
    local terminals = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "floaterm" and terminal_pid(buf) then
            terminals[#terminals + 1] = buf
        end
    end
    if #terminals == 0 then return end

    scanning = true
    vim.system({ "ps", "-A", "-o", "pid=,ppid=,command=" }, { text = true }, function(result)
        vim.schedule(function()
            scanning = false
            if result.code ~= 0 then return end
            local rows = {}
            for line in (result.stdout or ""):gmatch("[^\n]+") do
                local pid, ppid, command = line:match("^%s*(%d+)%s+(%d+)%s+(.*)$")
                if pid then
                    -- The program is the first word, or the second when the first
                    -- is an interpreter (node /path/to/opencode).
                    local names = {}
                    for word in command:gmatch("%S+") do
                        names[#names + 1] = vim.fn.fnamemodify(word, ":t")
                        if #names == 2 then break end
                    end
                    rows[#rows + 1] = { pid = tonumber(pid), ppid = tonumber(ppid), names = names }
                end
            end

            for _, buf in ipairs(terminals) do
                if vim.api.nvim_buf_is_valid(buf) then
                    local running = descendants(terminal_pid(buf), rows)
                    local wants_app, wants_full = false, false
                    for name in pairs(running) do
                        if app_programs[name] then wants_app = true end
                        if full_programs[name] then wants_full = true end
                    end

                    if wants_app and not vim.b[buf].terminal_app then
                        M.mark_app(buf, true)
                        vim.b[buf].terminal_app_detected = true
                    elseif not wants_app and vim.b[buf].terminal_app_detected then
                        M.mark_app(buf, false)
                        vim.b[buf].terminal_app_detected = nil
                    end

                    local showing = M.full_active() and vim.api.nvim_win_get_buf(full_win) == buf
                    if wants_full then
                        -- The full-screen view and the program are one thing: from
                        -- here until it exits, leaving it quits the view too.
                        vim.b[buf].terminal_full_program = true
                        vim.b[buf].terminal_full_seen = true
                    end
                    if wants_full and not showing and not vim.b[buf].terminal_auto_full_done then
                        -- Once per run: if you put it back, it stays back.
                        vim.b[buf].terminal_auto_full_done = true
                        M.toggle_full(buf)
                    elseif not wants_full then
                        vim.b[buf].terminal_auto_full_done = nil
                        -- The program quit: back to the normal layout, however
                        -- the full-screen view was opened.
                        -- Only once it has been seen running (or has had a few
                        -- seconds to start): a program still starting up is not
                        -- one that has quit.
                        local started = vim.b[buf].terminal_full_seen
                            or (vim.uv.hrtime() - (vim.b[buf].terminal_full_since or 0)) > 6e9
                        if vim.b[buf].terminal_full_program and started then
                            vim.b[buf].terminal_full_program = nil
                            vim.b[buf].terminal_full_seen = nil
                            if showing then M.toggle_full() end
                        end
                    end
                end
            end
        end)
    end)
end

---Run a command line in this project's terminal panel, opening one if there
---is none.
---
---The shell down there is the same interactive zsh you would type into, so
---everything defined in ~/.zshrc -- functions, aliases -- is available.
---jobstart can never reach those: it execs a program, and a shell function is
---not one. Output also lands where output belongs instead of being discarded
---by a detached job, and a program that reads stdin still works.
---
---By default you are taken to the terminal in insert mode, so a program that
---stops to ask something -- a prompt, a password, input() -- can be answered
---without pressing i first. With `focus = false` the panel is shown but you stay
---in the window and mode you were in: right for running a file or its tests,
---where you want to watch the output and keep editing.
---@param command string
---@param opts? { focus?: boolean }
---@return boolean sent
function M.send(command, opts)
    opts = opts or {}
    local origin = vim.api.nvim_get_current_win()

    -- The terminal you are in, else the one you used last: a new shell is only
    -- made when there is none to use.
    local bufnr = M.target()

    local fresh = not bufnr
    if not bufnr then
        vim.cmd("TerminalNew")
        bufnr = vim.api.nvim_get_current_buf()
        if vim.bo[bufnr].filetype ~= "floaterm" then bufnr = M.list()[1] end
    end

    local job = bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].terminal_job_id
    if not job then
        vim.notify("No terminal available to run this in", vim.log.levels.ERROR)
        return false
    end

    if opts.focus == false then
        -- Shown if it is not already, then handed straight back. A terminal that
        -- was just created has also been entered; leaving it cancels the insert
        -- that creating one asks for.
        if not terminal_window(bufnr) then M.focus(bufnr) end
        if vim.api.nvim_win_is_valid(origin) then pcall(vim.api.nvim_set_current_win, origin) end
        if vim.fn.mode():sub(1, 1) == "t" then vim.cmd("stopinsert") end
    else
        M.focus(bufnr, { insert = true })
    end

    -- A shell that is still starting up swallows or garbles what arrives before
    -- its first prompt (the first run after opening a terminal failed that way),
    -- so wait for the prompt to be drawn.
    if fresh or opts.wait then
        vim.wait(3000, function()
            if not vim.api.nvim_buf_is_valid(bufnr) then return true end
            for _, l in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
                if l:match("%S") then return true end
            end
            return false
        end, 20)
        vim.wait(150)
    end

    -- ^U first: anything already typed on the line (a stray key, a half-written
    -- command) would otherwise be glued onto the front of this one.
    vim.fn.chansend(job, "\21" .. command .. "\n")

    -- A terminal follows new output only while its cursor is on the last line.
    -- Scrolled up to read something, the command's output would arrive out of
    -- sight; jump to the end so it is visible straight away.
    for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
        pcall(vim.api.nvim_win_set_cursor, win, { vim.api.nvim_buf_line_count(bufnr), 0 })
    end
    return true
end

function M.cycle(direction)
    local bufnrs = M.list()
    if #bufnrs == 0 then
        vim.notify("No terminals open", vim.log.levels.INFO)
        return
    end

    local current = vim.api.nvim_get_current_buf()
    local in_full = M.full_active() and vim.api.nvim_get_current_win() == full_win
    local index = 0
    for i, bufnr in ipairs(bufnrs) do
        if bufnr == current then
            index = i
            break
        end
    end

    local target
    if index == 0 then
        target = direction > 0 and bufnrs[1] or bufnrs[#bufnrs]
    else
        target = bufnrs[(index - 1 + direction) % #bufnrs + 1]
    end

    -- Full screen is one window that shows one terminal at a time: the others
    -- stay behind it like buffers, and zn / zp swap which one is on top.
    if in_full then
        vim.api.nvim_win_set_buf(full_win, target)
        M.mark_app(target, true)
        return
    end
    M.focus(target)
end

-- ---------------------------------------------------------- zooming a split

local zoom ---@type { win: integer, other: integer? }?

---Whether the panel's split is currently collapsed to one terminal.
function M.zoom_active()
    return zoom ~= nil and vim.api.nvim_win_is_valid(zoom.win)
end

---The panel's terminal windows (not the full-screen float).
local function panel_windows()
    local wins = {}
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.api.nvim_win_get_config(win).relative == "" and vim.bo[buf].filetype == "floaterm" then
            wins[#wins + 1] = win
        end
    end
    return wins
end

---Make the terminal you are in take the whole panel, and put the split back.
---The other terminals are not closed: they stay behind it like buffers, and
---`zn` / `zp` swap which one fills the panel. Zooming again restores the split.
function M.toggle_zoom()
    if M.zoom_active() then
        local win = zoom.win
        local other = zoom.other
        zoom = nil
        local current = vim.api.nvim_win_get_buf(win)
        -- The split's other half: the terminal that was beside it, if it is
        -- still there and not the one on screen; else the next one.
        if not (other and vim.api.nvim_buf_is_valid(other) and other ~= current) then
            other = nil
            for _, buf in ipairs(M.list()) do
                if buf ~= current then other = buf break end
            end
        end
        if not other then return end
        vim.api.nvim_set_current_win(win)
        vim.cmd("rightbelow vsplit")
        vim.api.nvim_win_set_buf(0, other)
        vim.api.nvim_set_current_win(win)
        return
    end

    local wins = panel_windows()
    if #wins < 2 then
        vim.notify("The panel is not split", vim.log.levels.INFO, { title = "Terminal" })
        return
    end

    local here = vim.api.nvim_get_current_win()
    if not vim.tbl_contains(wins, here) then here = wins[1] end
    local other
    for _, win in ipairs(wins) do
        if win ~= here then
            other = other or vim.api.nvim_win_get_buf(win)
            pcall(vim.api.nvim_win_close, win, true)
        end
    end
    zoom = { win = here, other = other }
    vim.api.nvim_set_current_win(here)
end

function M.pick()
    local bufnrs = M.list()
    if #bufnrs == 0 then
        vim.notify("No terminals open", vim.log.levels.INFO)
        return
    end

    M.refresh()
    local current = vim.api.nvim_get_current_buf()

    require("snacks").picker.pick({
        title = "Terminals",
        finder = function()
            local items = {}
            for index, bufnr in ipairs(bufnrs) do
                local name = M.name(bufnr)
                items[#items + 1] = {
                    text = name .. " " .. index,
                    label = name,
                    bufnr = bufnr,
                    index = index,
                    current = bufnr == current,
                }
            end
            return items
        end,
        format = function(item)
            return {
                { item.current and "● " or "  ", "DiagnosticOk" },
                { item.label,                    "Function" },
                { "  #" .. item.index,           "Comment" },
            }
        end,
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            vim.schedule(function() M.focus(item.bufnr) end)
        end,
    })
end

---Statusline fragment: every terminal by path, the focused one highlighted.
function M.tabline()
    local current = vim.api.nvim_get_current_buf()
    local parts = {}

    for _, bufnr in ipairs(M.list()) do
        local group = bufnr == current and "TerminalTabActive" or "TerminalTabInactive"
        local icon = bufnr == current and " " or " "
        parts[#parts + 1] = string.format("%%#%s#%s%s%%*", group, icon, M.name(bufnr))
    end

    return table.concat(parts, " ")
end

---When a terminal goes away, take over its slot with the next one instead of
---collapsing the panel -- the split layout is meant to survive one of its
---halves exiting.
local function replace_closed(bufnr, win)
    -- Prefer a terminal that is not already on screen; promoting one that is
    -- visible in the other half would just show the same shell twice, so a
    -- split half whose sibling survives is simply allowed to collapse.
    local successor
    local project = vim.api.nvim_buf_is_valid(bufnr)
        and terminal_workspace(bufnr)
        or require("workspace").get()
    for _, candidate in ipairs(M.list(project)) do
        if candidate ~= bufnr
            and vim.api.nvim_buf_is_valid(candidate)
            and not terminal_window(candidate)
        then
            successor = candidate
            break
        end
    end

    if successor then
        if win and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_set_buf(win, successor)
        else
            -- floaterm tore the panel down first; bring it back with the survivor.
            M.focus(successor)
        end
    elseif win
        and vim.api.nvim_win_is_valid(win)
        and #vim.api.nvim_tabpage_list_wins(0) > 1
    then
        -- No terminal left to promote: collapse the slot instead of leaving an
        -- empty window sitting where the shell used to be.
        pcall(vim.api.nvim_win_close, win, true)
    end

    if vim.api.nvim_buf_is_valid(bufnr) then
        pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    end
    cwd_cache[bufnr] = nil
    return successor
end

---Close a terminal on purpose (the close key). If another terminal exists it
---takes the slot and the focus, so you stay in the terminal section; with
---none left, returns false and the caller decides where focus goes.
---@param bufnr integer
---@param opts? { insert?: boolean } insert: re-enter terminal mode in the next one
---@return boolean stayed
function M.close(bufnr, opts)
    opts = opts or {}
    local win = terminal_window(bufnr)
    local job = vim.b[bufnr].terminal_job_id
    M.stop_programs(terminal_pid(bufnr))
    if job then pcall(vim.fn.jobstop, job) end

    local successor = replace_closed(bufnr, win)
    if successor and vim.api.nvim_buf_is_valid(successor) then
        M.focus(successor, { insert = opts.insert })
        return true
    end

    -- No spare terminal to promote, but a sibling may be on screen (the panel
    -- was split): that half is the terminal section now.
    local sibling = any_terminal_window()
    if sibling then
        vim.api.nvim_set_current_win(sibling)
        if opts.insert then vim.cmd("startinsert") end
        return true
    end
    return false
end

---The terminal to copy from. Usually the current buffer, but the command and
---the action menu both run from the editor -- there "this terminal" can only
---mean the one on screen, so fall back to that instead of refusing.
local function source_terminal()
    local current = vim.api.nvim_get_current_buf()
    if vim.bo[current].buftype == "terminal" then return current end

    local win = any_terminal_window()
    if win then return vim.api.nvim_win_get_buf(win) end

    return M.list()[1]
end

---A real path under the project root, never an invented `terminal://` URI.
---That single choice is what makes the copy behave like any other file: `:w`
---writes it, Ctrl-C closes it, and buffer cycling -- which is scoped to the
---project by name -- can actually reach it again.
local function output_path(project)
    local taken = {}
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        taken[vim.api.nvim_buf_get_name(buf)] = true
    end

    for index = 1, 99 do
        local path = index == 1
            and (project .. "/terminal-output.txt")
            or string.format("%s/terminal-output-%d.txt", project, index)
        if vim.fn.filereadable(path) == 0 and not taken[path] then return path end
    end
    return string.format("%s/terminal-output-%d.txt", project, vim.uv.hrtime())
end

---Reuse the buffer from the last copy, but only while it still holds exactly
---what was copied into it. Once you have typed in it, the next copy gets its
---own buffer rather than silently discarding your edits.
local function reusable_output(source)
    local buf = vim.b[source].terminal_output_buf
    if type(buf) ~= "number" or not vim.api.nvim_buf_is_valid(buf) then return nil end
    if vim.b[buf].terminal_output_tick ~= vim.api.nvim_buf_get_changedtick(buf) then
        return nil
    end
    return buf
end

---Copy a terminal's output into an ordinary, saveable buffer.
---
---A `:terminal` buffer is not editable: in terminal-normal mode you can move,
---visually select and yank, but `i`/`a` re-enter *terminal* mode, which hands
---the keys to the shell and snaps the cursor to its prompt. That is Neovim's
---design, not something a mapping can change -- so to actually edit output,
---take a copy of it somewhere editing works.
---
---The terminal itself is only ever read from. Nothing here writes to the
---terminal buffer or touches its job, so a copy cannot disturb the shell.
---
---opts.first/opts.last narrow the copy to a line range (a visual selection);
---opts.cursor is a position in the terminal to land on in the copy.
function M.edit(opts)
    opts = opts or {}
    local source = source_terminal()
    if not source then
        vim.notify("No terminal to copy from", vim.log.levels.WARN)
        return
    end

    local total = vim.api.nvim_buf_line_count(source)
    local first = math.max(1, math.min(opts.first or 1, total))
    local last = math.max(first, math.min(opts.last or total, total))

    local lines = vim.api.nvim_buf_get_lines(source, first - 1, last, false)
    -- A terminal pads its screen to the window height; that padding is not output.
    while #lines > 0 and lines[#lines]:match("^%s*$") do
        table.remove(lines)
    end
    if #lines == 0 then
        vim.notify("Terminal has no output to copy", vim.log.levels.INFO)
        return
    end

    -- Land in the editor zone, creating it when the frame has none. The old
    -- fallback was "whatever window is current", which put the copy inside the
    -- terminal panel and pushed the live shell off screen.
    local ide = require("ide_layout")
    local win = ide.find_editor_window() or ide.ensure_editor_window()
    if not win or not vim.api.nvim_win_is_valid(win) then
        vim.notify("No editor window to open the terminal output in", vim.log.levels.WARN)
        return
    end

    local buf = reusable_output(source)
    if not buf then
        buf = vim.api.nvim_create_buf(true, false)
        local project = vim.fs.normalize(require("workspace").get())
        pcall(vim.api.nvim_buf_set_name, buf, output_path(project))
        vim.bo[buf].swapfile = false
        vim.b[source].terminal_output_buf = buf
    end

    -- The copy borrows the editor pane, so remember what it displaced: closing
    -- it puts that buffer back in place rather than closing the pane and
    -- letting the terminal panel expand into the gap (see close_current).
    -- Skipped when the copy is already on display, or it would record itself
    -- as its own predecessor.
    local displaced = vim.api.nvim_win_get_buf(win)
    vim.b[buf].terminal_edit = true
    if displaced ~= buf then
        vim.b[buf].terminal_edit_previous_buf = displaced
    end

    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- Remembered so the next copy can tell "untouched" from "edited".
    vim.b[buf].terminal_output_tick = vim.api.nvim_buf_get_changedtick(buf)

    vim.api.nvim_win_set_buf(win, buf)
    vim.api.nvim_set_current_win(win)

    -- Land where the cursor was in the terminal, so the copy opens on the part
    -- you were looking at rather than at the bottom. Without a window to ask --
    -- the terminal is hidden -- the end is as good a place as any.
    local cursor = opts.cursor
    if not cursor then
        local terminal = terminal_window(source)
        if terminal then cursor = vim.api.nvim_win_get_cursor(terminal) end
    end
    local row = cursor and (cursor[1] - (first - 1)) or #lines
    row = math.max(1, math.min(row, #lines))
    local col = math.max(0, math.min(cursor and cursor[2] or 0, #(lines[row] or "")))
    vim.api.nvim_win_set_cursor(win, { row, col })
end

function M.setup()
    -- Wrapped rather than passed straight through: a user command hands its
    -- callback a table of command arguments, which M.edit would read as its
    -- own options.
    vim.api.nvim_create_user_command("TerminalEdit", function(args)
        M.edit(args.range > 0 and { first = args.line1, last = args.line2 } or {})
    end, {
        range = true,
        desc = "Copy terminal output into an editable, saveable buffer",
    })

    vim.api.nvim_set_hl(0, "TerminalTabActive", { link = "Function", default = true })
    vim.api.nvim_set_hl(0, "TerminalTabInactive", { link = "Comment", default = true })

    local group = vim.api.nvim_create_augroup("TerminalPanel", { clear = true })

    vim.api.nvim_create_autocmd("TermClose", {
        group = group,
        callback = function(args)
            -- Already gone: the close key removed it and handled the hand-over.
            if not vim.api.nvim_buf_is_valid(args.buf) then return end
            if vim.bo[args.buf].filetype ~= "floaterm" then return end
            -- Captured synchronously: floaterm closes the panel itself before
            -- the scheduled follow-up runs, losing the slot we want to reuse.
            local win = terminal_window(args.buf)
            -- If you were in it -- typed `exit` -- you stay in the terminal
            -- section: the next terminal takes the slot and the focus, in the
            -- mode you were in. A terminal closing elsewhere never takes focus.
            local focused = vim.api.nvim_get_current_buf() == args.buf
            local typing = vim.fn.mode() == "t"
            vim.schedule(function()
                local successor = replace_closed(args.buf, win)
                if focused and successor and vim.api.nvim_buf_is_valid(successor) then
                    M.focus(successor, { insert = typing })
                end
            end)
        end,
        desc = "Hand a closed terminal's slot to the next terminal",
    })

    -- An app terminal is always typed into: arriving in it enters terminal
    -- mode, and a full-screen one follows the window when it is resized.
    vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
        group = group,
        callback = function(args)
            if vim.bo[args.buf].buftype == "terminal" and vim.b[args.buf].terminal_app then
                vim.schedule(function()
                    if vim.api.nvim_get_current_buf() == args.buf and vim.fn.mode() ~= "t" then
                        vim.cmd("startinsert")
                    end
                end)
            end
        end,
        desc = "Keep app terminals in terminal mode",
    })
    vim.api.nvim_create_autocmd("VimResized", {
        group = group,
        callback = function()
            if M.full_active() then
                local width, height = full_size()
                pcall(vim.api.nvim_win_set_config, full_win, {
                    relative = "editor", row = 0, col = 0, width = width, height = height,
                })
            end
        end,
        desc = "Keep the full-screen terminal full screen",
    })
    -- Quitting Neovim hangs every shell up; programs that ignore that must not
    -- be left running with no terminal.
    vim.api.nvim_create_autocmd("VimLeavePre", {
        group = group,
        callback = function()
            for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "floaterm" then
                    pcall(M.stop_programs, terminal_pid(buf), 600)
                end
            end
        end,
        desc = "Stop what the terminals started when Neovim quits",
    })
    vim.api.nvim_create_user_command("TerminalFull", function() M.toggle_full() end, {
        desc = "Show the terminal full screen, or back in its panel",
    })
    vim.api.nvim_create_user_command("TerminalZoom", M.toggle_zoom, {
        desc = "Make the terminal you are in fill the panel, or restore the split",
    })
    vim.api.nvim_create_user_command("TerminalApp", M.toggle_app, {
        desc = "Toggle app mode: every key, <Tab> included, goes to the program",
    })
    vim.api.nvim_create_user_command("LeetCode", M.leetcode, {
        desc = "Open LeetCode in its own Neovim, full screen",
    })
    vim.api.nvim_create_user_command("OpenCode", M.opencode, {
        desc = "Open opencode in a new full-screen terminal",
    })

    -- Sample on the events that change which terminal you are looking at, and
    -- poll slowly while one is on screen so a `cd` is reflected without
    -- needing an explicit refresh.
    vim.api.nvim_create_autocmd({ "BufEnter", "TermEnter", "TermLeave", "WinEnter" }, {
        group = group,
        callback = function(args)
            if vim.bo[args.buf].filetype == "floaterm" then
                last_focused = args.buf
                M.refresh()
            end
        end,
        desc = "Track the working directory and last-used terminal",
    })

    if refresh_timer then refresh_timer:stop() end
    refresh_timer = vim.uv.new_timer()
    refresh_timer:start(2000, 2000, vim.schedule_wrap(function()
        if any_terminal_window() then M.refresh() end
    end))

    if scan_timer then scan_timer:stop() end
    scan_timer = vim.uv.new_timer()
    scan_timer:start(1000, 700, vim.schedule_wrap(M.scan_programs))
end

return M
