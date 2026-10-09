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
    with_kernel(function() evaluate(cell) end)
end

function M.run_all()
    local buf = vim.api.nvim_get_current_buf()
    local cells = M.cells(buf)
    if #cells == 0 then
        notify("No code cells in this notebook", vim.log.levels.WARN)
        return
    end
    with_kernel(function()
        for _, cell in ipairs(cells) do evaluate(cell) end
    end)
end

function M.run_above()
    local buf = vim.api.nvim_get_current_buf()
    local line = vim.api.nvim_win_get_cursor(0)[1]
    with_kernel(function()
        for _, cell in ipairs(M.cells(buf)) do
            if cell.first <= line then evaluate(cell) end
        end
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

function M.setup()
    vim.g.molten_virt_text_output = true
    vim.g.molten_virt_lines_off_by_1 = true
    vim.g.molten_auto_open_output = false
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
