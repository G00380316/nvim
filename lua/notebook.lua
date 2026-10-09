---Running notebook cells. A .ipynb opens as Markdown (jupytext), with each code
---cell a fenced block; molten-nvim runs a block in a Jupyter kernel and shows
---the output under it. The cell under the cursor is found here, because molten
---itself knows nothing about Markdown fences.
local M = {}

local initialized = {}

---Code cells in a buffer: the lines between the fences, as {first, last}
---(1-based, inclusive), in order.
---@param buf integer
---@return { first: integer, last: integer }[]
function M.cells(buf)
    local cells, open = {}, nil
    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if not open then
            -- ```python, ```{python}, ``` python -- any language fence opens a cell.
            if line:match("^```%s*{?%s*[%w_+-]+") then open = i + 1 end
        elseif line:match("^```%s*$") then
            if i - 1 >= open then cells[#cells + 1] = { first = open, last = i - 1 } end
            open = nil
        end
    end
    return cells
end

---The cell holding `line`, or nil.
function M.cell_at(buf, line)
    for _, cell in ipairs(M.cells(buf)) do
        if line >= cell.first - 1 and line <= cell.last + 1 then return cell end
    end
end

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Notebook" })
end

---Run `action` once the buffer has a kernel, starting the default Python one if
---it has none yet.
local function with_kernel(action)
    local buf = vim.api.nvim_get_current_buf()
    if initialized[buf] then return action() end

    -- MoltenKernelReady, not MoltenInitPost: the latter fires when the kernel
    -- is merely started, and a cell sent then sits "On Hold" for good.
    vim.api.nvim_create_autocmd("User", {
        pattern = "MoltenKernelReady",
        once = true,
        callback = function()
            initialized[buf] = true
            vim.schedule(action)
        end,
    })
    notify("Starting the Python kernel; the cell runs as soon as it is ready")
    local ok, err = pcall(vim.cmd, "MoltenInit python3")
    if not ok then notify("Could not start a kernel: " .. tostring(err), vim.log.levels.ERROR) end
end

local function evaluate(cell)
    local ok, err = pcall(vim.fn.MoltenEvaluateRange, cell.first, cell.last)
    if not ok then notify(tostring(err), vim.log.levels.ERROR) end
end

function M.run_cell()
    local buf = vim.api.nvim_get_current_buf()
    local cell = M.cell_at(buf, vim.api.nvim_win_get_cursor(0)[1])
    if not cell then
        notify("The cursor is not in a code cell", vim.log.levels.WARN)
        return
    end
    with_kernel(function()
        evaluate(cell)
        watch(buf)
    end)
end

local progress_ns = vim.api.nvim_create_namespace("notebook_progress")
local SIGNS = {
    queued = { "…", "DiagnosticHint" },
    running = { "▶", "DiagnosticWarn" },
    done = { "✓", "DiagnosticOk" },
    error = { "✗", "DiagnosticError" },
}

---A mark beside each cell's first line showing where it stands, redrawn as it
---changes. Cells that have not been run have none.
local function refresh_signs(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_clear_namespace(buf, progress_ns, 0, -1)
    local cells = M.cells(buf)
    for index, state in pairs(M.cell_states(buf)) do
        local cell, sign = cells[index], SIGNS[state]
        if cell and sign then
            pcall(vim.api.nvim_buf_set_extmark, buf, progress_ns, cell.first - 1, 0, {
                sign_text = sign[1],
                sign_hl_group = sign[2],
            })
        end
    end
end

local watching = {}

---Follow a run as it goes: every moment, redraw the marks beside the cells and
---the statusline ("running 2/5"), until nothing is left running. With
---`announce`, say so once at the end.
---@param buf integer
---@param announce? boolean
local function watch(buf, announce)
    if watching[buf] then
        watching[buf].announce = watching[buf].announce or announce
        return
    end
    local job = { announce = announce, started = vim.uv.hrtime(), seen = false }
    watching[buf] = job

    local timer = vim.uv.new_timer()
    local function stop()
        watching[buf] = nil
        if not timer:is_closing() then timer:stop(); timer:close() end
    end

    timer:start(200, 300, vim.schedule_wrap(function()
        if not vim.api.nvim_buf_is_valid(buf) then return stop() end
        if (vim.uv.hrtime() - job.started) > 10 * 60 * 1e9 then return stop() end

        refresh_signs(buf)
        vim.cmd("redrawstatus!")

        local text = M.status_text(buf)
        if text ~= "" then job.seen = true end
        if job.seen and text ~= "" and not text:find("running", 1, true) then
            stop()
            if job.announce then
                local level = text:find("✗", 1, true) and vim.log.levels.WARN or vim.log.levels.INFO
                notify(text, level)
            end
        end
    end))
end

M.refresh_signs = refresh_signs

function M.run_all()
    local buf = vim.api.nvim_get_current_buf()
    local cells = M.cells(buf)
    if #cells == 0 then
        notify("No code cells in this notebook", vim.log.levels.WARN)
        return
    end
    with_kernel(function()
        for _, cell in ipairs(cells) do evaluate(cell) end
        watch(buf, true)
    end)
end

function M.run_above()
    local buf = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    with_kernel(function()
        for _, cell in ipairs(M.cells(buf)) do
            if cell.first <= line then evaluate(cell) end
        end
        watch(buf, true)
    end)
end

local function molten(command)
    return function()
        local ok, err = pcall(vim.cmd, command)
        if not ok then notify(tostring(err), vim.log.levels.WARN) end
    end
end

---Write the outputs shown under the cells into the .ipynb file. jupytext has
---already saved the code and text by the time this runs (it updates the
---notebook in place, keeping existing outputs); molten then adds the new ones.
---@param buf? integer
function M.save_outputs(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(buf)
    if not file:match("%.ipynb$") then
        notify("This is not a notebook", vim.log.levels.WARN)
        return
    end
    if not initialized[buf] then return end
    local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
        vim.cmd("MoltenExportOutput! " .. vim.fn.fnameescape(file))
    end)
    if not ok then notify("Could not save outputs: " .. tostring(err), vim.log.levels.WARN) end
end

---Whether the notebook file already holds any cell output.
local function has_saved_outputs(file)
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), "\n"))
    if not (ok and type(data) == "table" and type(data.cells) == "table") then return false end
    for _, cell in ipairs(data.cells) do
        if type(cell.outputs) == "table" and #cell.outputs > 0 then return true end
    end
    return false
end

local imported = {}

---Bring a notebook's saved outputs back under its cells. Showing them takes a
---kernel (molten reads them through one), so this starts the Python kernel for
---a notebook that has any -- one that has none stays quiet until you run a cell.
---@param buf? integer
function M.import_outputs(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(buf)
    if not (file:match("%.ipynb$") and vim.fn.filereadable(file) == 1) then return end
    vim.api.nvim_buf_call(buf, function()
        with_kernel(function()
            local ok, err = pcall(vim.cmd, "MoltenImportOutput " .. vim.fn.fnameescape(file))
            if not ok then notify("Could not load saved outputs: " .. tostring(err), vim.log.levels.WARN) end
        end)
    end)
end

local output_mode = "inline"

---Where results are shown. "inline": text under the cell that stays put as you
---move about -- and the only style that shows every cell's state at a glance,
---which the status indicator reads. "window": a floating window under the cell,
---opened when the cursor is in the cell.
local function apply_output_mode()
    vim.g.molten_virt_text_output = output_mode == "inline"
    vim.g.molten_auto_open_output = output_mode == "window"
end

function M.toggle_output_mode()
    output_mode = output_mode == "window" and "inline" or "window"
    apply_output_mode()
    notify(output_mode == "window"
        and "Results show in a window under the cell while the cursor is in it"
        or "Results show as text under the cell")
end

function M.output_mode() return output_mode end

---Open the notebook as a finished page in the browser, saved outputs and all.
---Writes the notebook first, so what you see includes the latest results.
function M.view_in_browser()
    local buf = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(buf)
    if not file:match("%.ipynb$") then
        notify("This is not a notebook", vim.log.levels.WARN)
        return
    end
    if vim.bo[buf].modified then vim.cmd("silent! write") end

    local host = vim.fn.expand("~/.local/share/nvim/python-host/bin/python")
    local out_dir = vim.fn.stdpath("cache") .. "/notebook-view"
    vim.fn.mkdir(out_dir, "p")
    local html = out_dir .. "/" .. vim.fn.fnamemodify(file, ":t:r") .. ".html"

    -- Outputs are saved into the file a moment after the write; give that time.
    vim.defer_fn(function()
        vim.system(
            { host, "-m", "nbconvert", "--to", "html", "--output-dir", out_dir, file },
            { text = true },
            function(result)
                vim.schedule(function()
                    if result.code ~= 0 then
                        notify("Could not convert the notebook: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
                        return
                    end
                    vim.ui.open(html)
                end)
            end
        )
    end, 800)
end

-- ------------------------------------------------------- run state, markers

---Each code cell's state from the line molten draws under it:
---"done", "running", "error" or "queued"; a cell that has not been run has none.
---@param buf integer
---@return table<integer, string> by cell index
function M.cell_states(buf)
    local states = {}
    local cells = M.cells(buf)
    for _, mark in ipairs(vim.api.nvim_buf_get_extmarks(buf, -1, 0, -1, { details = true })) do
        local lines = mark[4].virt_lines
        local first = lines and lines[1] and lines[1][1] and lines[1][1][1]
        if first and first:find("Out%[") then
            local row = mark[2] + 1
            for index, cell in ipairs(cells) do
                if row >= cell.first and row <= cell.last + 1 then
                    local state = "running"
                    if first:find("Done", 1, true) then state = "done"
                    elseif first:find("Error", 1, true) or first:find("✗", 1, true) then state = "error"
                    elseif first:find("On Hold", 1, true) then state = "queued" end
                    states[index] = state
                end
            end
        end
    end
    return states
end

---One line for the statusline: how far a run has got, and when it is finished.
---Empty for a notebook nothing has been run in.
---@param buf? integer
---@return string
function M.status_text(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local total = #M.cells(buf)
    if total == 0 then return "" end

    local counts = { done = 0, running = 0, error = 0, queued = 0 }
    for _, state in pairs(M.cell_states(buf)) do counts[state] = counts[state] + 1 end
    local ran = counts.done + counts.error
    if ran + counts.running + counts.queued == 0 then return "" end

    if counts.running + counts.queued > 0 then
        return ("󰑮 running %d/%d"):format(ran, total)
    elseif counts.error > 0 then
        return ("✗ %d error%s · %d/%d cells ran"):format(counts.error, counts.error == 1 and "" or "s", ran, total)
    elseif ran == total then
        return ("✓ all %d cells ran"):format(total)
    end
    return ("%d/%d cells ran"):format(ran, total)
end

---Split one table row into its trimmed cells, or nil if it is not a row.
local function row_cells(line)
    if not line:match("^%s*|") then return nil end
    local body = line:gsub("^%s*|", ""):gsub("|%s*$", "")
    local cells, current, escaped = {}, "", false
    for char in body:gmatch(".") do
        if char == "|" and not escaped then
            cells[#cells + 1] = vim.trim(current)
            current = ""
        else
            current = current .. char
        end
        escaped = char == "\\" and not escaped
    end
    cells[#cells + 1] = vim.trim(current)
    return cells
end

---Rewrite every Markdown table in the buffer with its padding removed. Cells
---in a notebook are often padded out to the widest one -- hundreds of spaces --
---so a table is wider than any window and the renderer cannot draw it. The
---table says the same afterwards; only the spaces change. Done when asked, never
---on its own, because it edits the notebook's text.
---@param buf? integer
---@return integer tables changed
function M.tidy_tables(buf)
    buf = buf or vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local out, changed, i = {}, 0, 1
    while i <= #lines do
        local header = row_cells(lines[i])
        local divider = header and lines[i + 1] and row_cells(lines[i + 1])
        local is_table = divider ~= nil
        if is_table then
            for _, cell in ipairs(divider) do
                if not cell:match("^:?%-+:?$") then is_table = false end
            end
        end
        if is_table then
            local first = i
            local rows = { header }
            local j = i + 2
            while lines[j] and row_cells(lines[j]) do
                rows[#rows + 1] = row_cells(lines[j])
                j = j + 1
            end
            local function join(cells) return "| " .. table.concat(cells, " | ") .. " |" end
            local tidy = { join(header) }
            local rule = {}
            for k, cell in ipairs(divider) do
                local left, right = cell:sub(1, 1) == ":", cell:sub(-1) == ":"
                rule[k] = (left and ":" or "") .. "---" .. (right and ":" or "")
            end
            tidy[2] = join(rule)
            for k = 2, #rows do tidy[#tidy + 1] = join(rows[k]) end
            for k, line in ipairs(tidy) do
                if line ~= lines[first + k - 1] then changed = changed + 1 end
                out[#out + 1] = line
            end
            i = j
        else
            out[#out + 1] = lines[i]
            i = i + 1
        end
    end
    if changed > 0 then vim.api.nvim_buf_set_lines(buf, 0, -1, false, out) end
    return changed
end

local marker_ns = vim.api.nvim_create_namespace("notebook_markers")

---Hide jupytext's `<!-- #region ... -->` / `<!-- #endregion -->` lines. They are
---bookkeeping for the file format, not part of the notebook; any other comment
---is left alone. Whole lines are concealed, so they take no row.
local function hide_markers(buf)
    if not vim.api.nvim_buf_is_valid(buf) then return end
    vim.api.nvim_buf_clear_namespace(buf, marker_ns, 0, -1)
    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if line:match("^<!%-%- #region.*%-%->%s*$") or line:match("^<!%-%- #endregion%s*%-%->%s*$") then
            pcall(vim.api.nvim_buf_set_extmark, buf, marker_ns, i - 1, 0, { conceal_lines = "" })
        end
    end
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
        if vim.wo[win].conceallevel < 1 then vim.wo[win].conceallevel = 2 end
    end
end

function M.setup()
    apply_output_mode()
    vim.g.molten_virt_lines_off_by_1 = true
    vim.g.molten_wrap_output = true
    vim.g.molten_output_win_max_height = 20
    if pcall(require, "image") then vim.g.molten_image_provider = "image.nvim" end

    vim.api.nvim_create_autocmd("User", {
        pattern = "MoltenDeinitPost",
        callback = function() initialized[vim.api.nvim_get_current_buf()] = nil end,
    })

    local commands = {
        { "NotebookRunCell", M.run_cell, "Run the code cell under the cursor" },
        { "NotebookRunAll", M.run_all, "Run every code cell, in order" },
        { "NotebookLoadOutputs", function() M.import_outputs() end, "Show the outputs saved in this notebook" },
        { "NotebookSaveOutputs", function() M.save_outputs() end, "Write the cell outputs into the .ipynb file" },
        { "NotebookTidyTables", function()
            local n = M.tidy_tables()
            notify(n > 0 and ("Tidied %d table lines"):format(n) or "Tables are already tidy")
        end, "Remove the padding from Markdown tables so they fit and render" },
        { "NotebookView", M.view_in_browser, "Open this notebook as a finished page in the browser" },
        { "NotebookOutputMode", M.toggle_output_mode, "Switch results between a window under the cell and inline text" },
        { "NotebookRunAbove", M.run_above, "Run every cell up to and including this one" },
        { "NotebookKernel", molten("MoltenInit"), "Choose and start a kernel for this notebook" },
        { "NotebookInterrupt", molten("MoltenInterrupt"), "Stop the cell that is running" },
        { "NotebookRestart", molten("MoltenRestart!"), "Restart the kernel and clear outputs" },
        { "NotebookClearOutput", molten("MoltenDelete!"), "Clear every cell's output" },
        { "NotebookOutput", molten("noautocmd MoltenEnterOutput"), "Open the cell's output window to read or scroll it" },
        { "NotebookStop", molten("MoltenDeinit"), "Shut this notebook's kernel down" },
    }
    for _, c in ipairs(commands) do
        vim.api.nvim_create_user_command(c[1], c[2], { nargs = 0, desc = c[3] })
    end

    vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType", "TextChanged", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("NotebookMarkers", { clear = true }),
        pattern = { "*.ipynb" },
        callback = function(args)
            vim.defer_fn(function() hide_markers(args.buf) end, 150)
        end,
        desc = "Hide jupytext's region marker lines",
    })

    -- The jupytext header (jupyter: / jupytext: / kernelspec: ...) is a dozen
    -- lines nobody reads; fold it shut so the first cell is at the top.
    vim.api.nvim_create_autocmd({ "BufWinEnter", "FileType" }, {
        group = vim.api.nvim_create_augroup("NotebookHeader", { clear = true }),
        pattern = { "*.ipynb" },
        callback = function(args)
            vim.defer_fn(function()
                if not vim.api.nvim_buf_is_valid(args.buf) then return end
                local win = vim.fn.bufwinid(args.buf)
                if win == -1 then return end
                local lines = vim.api.nvim_buf_get_lines(args.buf, 0, 40, false)
                if lines[1] ~= "---" then return end
                for i = 2, #lines do
                    if lines[i] == "---" then
                        vim.api.nvim_win_call(win, function()
                            vim.wo.foldmethod = "manual"
                            vim.cmd("silent! 1," .. i .. "fold")
                            vim.cmd("silent! 1foldclose")
                        end)
                        return
                    end
                end
            end, 300)
        end,
        desc = "Fold the jupytext header in notebooks",
    })

    -- Opening one shows what it printed last time.
    vim.api.nvim_create_autocmd("BufWinEnter", {
        group = vim.api.nvim_create_augroup("NotebookOpen", { clear = true }),
        pattern = "*.ipynb",
        callback = function(args)
            if imported[args.buf] then return end
            imported[args.buf] = true
            local file = vim.api.nvim_buf_get_name(args.buf)
            if vim.fn.filereadable(file) == 1 and has_saved_outputs(file) then
                vim.schedule(function() M.import_outputs(args.buf) end)
            end
        end,
        desc = "Show a notebook's saved outputs when it is opened",
    })

    -- Saving a notebook saves what its cells printed, too.
    vim.api.nvim_create_autocmd("BufWritePost", {
        group = vim.api.nvim_create_augroup("NotebookOutputs", { clear = true }),
        pattern = "*.ipynb",
        callback = function(args)
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(args.buf) then M.save_outputs(args.buf) end
            end)
        end,
        desc = "Write cell outputs into the notebook when it is saved",
    })

    -- <leader>n runs the cell, in notebooks only.
    vim.api.nvim_create_autocmd("BufEnter", {
        group = vim.api.nvim_create_augroup("NotebookKeys", { clear = true }),
        pattern = "*.ipynb",
        callback = function(args)
            vim.keymap.set("n", "<leader>n", M.run_cell, { buffer = args.buf, desc = "Run the notebook cell under the cursor" })
        end,
    })
end

return M
