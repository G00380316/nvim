---R Markdown (.Rmd) and Quarto (.qmd). Both open as Markdown, so everything
---a note has -- rendering in the buffer, lists, tables, hints -- works in them
---too, and the R inside the {r} chunks is highlighted. Chunks run in an R
---session in a terminal (`:RmdRunChunk`), and the whole file is rendered to a
---web page, PDF or Word file and opened (`:RmdRender`).
local M = {}

local session -- the terminal buffer R runs in

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "R Markdown" })
end

---Is this buffer an R Markdown or Quarto file?
---@param buf? integer
---@return boolean
function M.is_rmd(buf)
    local name = vim.api.nvim_buf_get_name(buf or 0)
    return name:match("%.[Rr]md$") ~= nil or name:match("%.qmd$") ~= nil
end

local function is_quarto(buf)
    return vim.api.nvim_buf_get_name(buf or 0):match("%.qmd$") ~= nil
end

---The code chunks of a buffer: language, options and the lines between the
---fences ({first, last}, 1-based, inclusive; last < first for an empty chunk).
---@param buf integer
---@return { lang: string, options: string, first: integer, last: integer }[]
function M.chunks(buf)
    local chunks, open = {}, nil
    for i, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
        if not open then
            local lang, options = line:match("^```%s*{%s*([%w_+-]+)%s*,?%s*(.-)%s*}%s*$")
            if not lang then lang = line:match("^```%s*([%w_+-]+)%s*$") end
            if lang then open = { lang = lang:lower(), options = options or "", first = i + 1 } end
        elseif line:match("^```%s*$") then
            open.last = i - 1
            chunks[#chunks + 1] = open
            open = nil
        end
    end
    return chunks
end

-- --------------------------------------------------------------- R session

local function session_job()
    if session and vim.api.nvim_buf_is_valid(session) then
        local job = vim.b[session].terminal_job_id
        if job and vim.fn.jobwait({ job }, 0)[1] == -1 then return job end
    end
    session = nil
end

---Show the R terminal without moving you out of the note.
local function reveal(buf)
    local origin = vim.api.nvim_get_current_win()
    if #vim.fn.win_findbuf(buf) == 0 then require("terminals").focus(buf) end
    if vim.api.nvim_win_is_valid(origin) then pcall(vim.api.nvim_set_current_win, origin) end
    if vim.fn.mode():sub(1, 1) == "t" then vim.cmd("stopinsert") end
end

---Start R in a terminal (once), then call `after`.
---@param after? fun()
function M.console(after)
    if session_job() then
        if after then after() end
        return
    end
    local deps = require("deps")
    deps.ensure("R", { reason = "running R code" }, function(ok)
        if not ok then return end
        local terminals = require("terminals")
        vim.cmd("TerminalNew")
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].filetype ~= "floaterm" then return end
        -- In the note's folder, so file paths in chunks mean what they do when rendering.
        local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(vim.fn.bufnr("#") > 0 and vim.fn.bufnr("#") or 0))
        terminals.send("R --quiet --no-save", { focus = false, wait = true })
        session = terminals.target() or buf
        if dir and dir ~= "" and vim.fn.isdirectory(dir) == 1 then
            vim.fn.chansend(vim.b[session].terminal_job_id, ('setwd("%s")\n'):format(dir:gsub("\\", "\\\\"):gsub('"', '\\"')))
        end
        if after then vim.defer_fn(after, 300) end
    end)
end

local function send_code(code)
    M.console(function()
        local job = session_job()
        if not job then return end
        reveal(session)
        vim.fn.chansend(job, code:gsub("\n*$", "") .. "\n")
    end)
end

---Whether a chunk's options say not to run it: eval=FALSE in the header
---({r, eval=FALSE}), or `#| eval: false` as the first lines of a Quarto chunk.
local function eval_off(buf, chunk)
    if chunk.options:match("eval%s*=%s*F") then return true end
    for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, chunk.first - 1, chunk.last, false)) do
        local option = line:match("^#|%s*(.-)%s*$")
        if not option then break end
        if option:match("^eval:%s*false$") or option:match("^eval:%s*no$") then return true end
    end
    return false
end

---Whether a chunk should be run here: R chunks only, not one marked off.
local function runnable(buf, chunk)
    if chunk.lang ~= "r" then
        notify(("Only R chunks run here; this one is %s"):format(chunk.lang), vim.log.levels.WARN)
        return false
    end
    return not eval_off(buf, chunk)
end

local function chunk_code(buf, chunk)
    return table.concat(vim.api.nvim_buf_get_lines(buf, chunk.first - 1, chunk.last, false), "\n")
end

-- ------------------------------------------------------------ inline plots

-- Plots are drawn by R into PNG files (a device per chunk), and the last plot of
-- each chunk is shown in the note under the chunk, as notebook plots are, when
-- the terminal can draw pictures (kitty). Elsewhere the file is opened.

local cache_dir = vim.fn.stdpath("cache") .. "/rmarkdown"
local helper_file = cache_dir .. "/helper.R"
local run_counter = 0
local images = {} -- [buf][chunk index] = image
M.on_done = nil -- test hook: function(run) called when a run has finished

local helper = [==[
.nvim_mark <- function(dir) {
  graphics.off()
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  assign(".nvim_dir", dir, globalenv())
  options(device = function(...) grDevices::png(file.path(.nvim_dir, "p%03d.png"), width = 900, height = 600, res = 110))
}
.nvim_run <- function(file, id) {
  on.exit({ graphics.off(); cat(paste0("\n[[nvim-done ", id, "]]\n")) })
  source(file, echo = TRUE, max.deparse.length = Inf)
}
]==]

local function can_draw()
    return (vim.env.KITTY_WINDOW_ID or (vim.env.TERM or ""):match("kitty")) and pcall(require, "image")
end

---Show the last plot of a chunk under it, replacing the one from the last run.
local function show_plot(buf, index, fence_row, files)
    images[buf] = images[buf] or {}
    local old = images[buf][index]
    if old then pcall(function() old:clear() end) end
    images[buf][index] = nil
    if #files == 0 then return end
    local file = files[#files]
    if not can_draw() then
        vim.ui.open(file)
        return
    end
    pcall(function() require("image_setup").setup() end)
    local win = vim.fn.win_findbuf(buf)[1]
    local ok, image = pcall(function()
        local img = require("image").from_file(file, {
            buffer = buf, window = win, with_virtual_padding = true, x = 0, y = fence_row,
        })
        img:render()
        return img
    end)
    if ok then images[buf][index] = image end
end

---Remove every plot shown in this note.
function M.clear_plots()
    local buf = vim.api.nvim_get_current_buf()
    for _, img in pairs(images[buf] or {}) do pcall(function() img:clear() end) end
    images[buf] = nil
end

---Open the plots of the last run in the default viewer.
local last_files = {}
function M.open_plots()
    if #last_files == 0 then
        notify("No plots from the last run")
        return
    end
    for _, file in ipairs(last_files) do vim.ui.open(file) end
end

---Run these chunks in the R session, in order, as one script, and show their plots.
---@param buf integer
---@param items { index: integer, chunk: table }[]
local function run_chunks(buf, items)
    vim.fn.mkdir(cache_dir, "p")
    vim.fn.writefile(vim.split(helper, "\n", { plain = true }), helper_file)

    run_counter = run_counter + 1
    local id = ("%d-%d"):format(os.time(), run_counter)
    local base = ("%s/run-%s"):format(cache_dir, id)
    local script, order = {}, {}
    for _, item in ipairs(items) do
        local dir = ("%s/chunk-%d"):format(base, item.index)
        script[#script + 1] = (".nvim_mark(%q)"):format(dir)
        script[#script + 1] = chunk_code(buf, item.chunk)
        order[#order + 1] = { index = item.index, dir = dir, row = item.chunk.last }
    end
    local script_file = ("%s/run-%s.R"):format(cache_dir, id)
    vim.fn.writefile(vim.split(table.concat(script, "\n"), "\n", { plain = true }), script_file)

    M.console(function()
        local job = session_job()
        if not job then return end
        reveal(session)
        vim.fn.chansend(job, ('source(%q); .nvim_run(%q, %q)\n'):format(helper_file, script_file, id))

        local sentinel = "[[nvim-done " .. id .. "]]"
        local timer = vim.uv.new_timer()
        local started = vim.uv.hrtime()
        timer:start(300, 300, vim.schedule_wrap(function()
            local finished = false
            if session and vim.api.nvim_buf_is_valid(session) then
                local lines = vim.api.nvim_buf_get_lines(session, 0, -1, false)
                for i = #lines, 1, -1 do
                    if lines[i]:find(sentinel, 1, true) then finished = true break end
                end
            end
            -- Stop looking after ten minutes, or when the session has gone.
            if not finished and (vim.uv.hrtime() - started < 6e11) and session_job() then return end
            timer:stop()
            timer:close()
            if not finished then return end
            last_files = {}
            for _, entry in ipairs(order) do
                local files = vim.fn.glob(entry.dir .. "/p*.png", false, true)
                table.sort(files)
                vim.list_extend(last_files, files)
                if vim.api.nvim_buf_is_valid(buf) then show_plot(buf, entry.index, entry.row, files) end
            end
            if M.on_done then M.on_done({ id = id, files = last_files, order = order }) end
        end))
    end)
end

function M.run_chunk()
    local buf = vim.api.nvim_get_current_buf()
    local chunks = M.chunks(buf)
    local row = vim.api.nvim_win_get_cursor(0)[1]
    for index, chunk in ipairs(chunks) do
        if row >= chunk.first - 1 and row <= chunk.last + 1 then
            if runnable(buf, chunk) and chunk.last >= chunk.first then run_chunks(buf, { { index = index, chunk = chunk } }) end
            return
        end
    end
    notify("The cursor is not in a code chunk")
end

---Run every R chunk (or those up to the cursor), top to bottom, as one go.
local function run_many(upto)
    local buf = vim.api.nvim_get_current_buf()
    local items = {}
    for index, chunk in ipairs(M.chunks(buf)) do
        if upto and chunk.first > upto + 1 then break end
        if chunk.lang == "r" and not eval_off(buf, chunk) and chunk.last >= chunk.first then
            items[#items + 1] = { index = index, chunk = chunk }
        end
    end
    if #items == 0 then
        notify("No R chunks to run")
        return
    end
    run_chunks(buf, items)
end

function M.run_all() run_many(nil) end
function M.run_above() run_many(vim.api.nvim_win_get_cursor(0)[1]) end

---Run the selected lines in R (visual mode), or the current line.
function M.run_selection()
    local first, last = vim.fn.line("v"), vim.fn.line(".")
    if first > last then first, last = last, first end
    send_code(table.concat(vim.api.nvim_buf_get_lines(0, first - 1, last, false), "\n"))
end

function M.stop()
    local job = session_job()
    if job then vim.fn.chansend(job, "q('no')\n") end
    session = nil
end

-- ----------------------------------------------------------------- render

local formats = {
    html = { r = "html_document", quarto = "html", ext = "html" },
    pdf = { r = "pdf_document", quarto = "pdf", ext = "pdf" },
    word = { r = "word_document", quarto = "docx", ext = "docx" },
}

local function rmarkdown_installed()
    local result = vim.system({ "Rscript", "-e", "quit(status = !requireNamespace('rmarkdown', quietly = TRUE))" }):wait(15000)
    return result.code == 0
end

---The R packages an error says are missing ("there is no package called
---'tidyverse'"), each once.
---@param text string
---@return string[]
function M.missing_packages(text)
    local found, seen = {}, {}
    -- R quotes with ' or the curly pair, depending on the locale.
    text = text:gsub("\226\128[\152\153]", "'")
    for name in text:gmatch("no package called [\"'`]([%w%.]+)") do
        if not seen[name] then
            seen[name] = true
            found[#found + 1] = name
        end
    end
    return found
end

---Offer to install the packages a failed render was missing.
---@param text string the render's error output
function M.offer_packages(text)
    local missing = M.missing_packages(text)
    if #missing == 0 then return end
    local list = table.concat(missing, ", ")
    if vim.fn.confirm(("The document needs R packages that are not installed: %s. Install them now?"):format(list),
        "&Install\n&Not now", 1) ~= 1 then
        return
    end
    local quoted = vim.tbl_map(function(name) return ('"%s"'):format(name) end, missing)
    require("terminals").send(
        ("Rscript -e 'install.packages(c(%s), repos = \"https://cloud.r-project.org\")'"):format(table.concat(quoted, ", ")),
        { focus = false })
    notify(("Installing %s in the terminal; render again when it finishes"):format(list))
end

---Render the file to `format` (html, pdf or word) and open the result.
---@param format? string
function M.render(format)
    local buf = vim.api.nvim_get_current_buf()
    if not M.is_rmd(buf) then
        notify("This is not an .Rmd or .qmd file")
        return
    end
    format = (format and format ~= "") and format:lower() or "html"
    local spec = formats[format]
    if not spec then
        notify("Formats: html, pdf, word", vim.log.levels.WARN)
        return
    end
    if vim.bo[buf].modified then vim.cmd("silent write") end
    local file = vim.api.nvim_buf_get_name(buf)
    local dir, name = vim.fs.dirname(file), vim.fs.basename(file)
    local output = dir .. "/" .. name:gsub("%.%w+$", "") .. "." .. spec.ext

    local function run(command)
        notify(("Rendering %s to %s ..."):format(name, format))
        vim.system(command, { cwd = dir, text = true }, vim.schedule_wrap(function(result)
            if result.code ~= 0 then
                local tail = vim.trim(result.stderr or "")
                notify("Render failed:\n" .. tail:sub(-600), vim.log.levels.ERROR)
                M.offer_packages(tail)
                return
            end
            notify("Rendered " .. vim.fs.basename(output))
            vim.ui.open(output)
        end))
    end

    if is_quarto(buf) then
        local function with_quarto() run({ "quarto", "render", name, "--to", spec.quarto }) end
        if vim.fn.executable("quarto") == 1 then return with_quarto() end
        return require("deps").ensure("quarto", { reason = "rendering .qmd files" }, function(ok)
            if ok then vim.schedule(with_quarto) end
        end)
    end

    local function with_r()
        if not rmarkdown_installed() then
            if vim.fn.confirm("The R package rmarkdown is not installed. Install it now?", "&Install\n&Not now", 1) == 1 then
                require("terminals").send(
                    [[Rscript -e 'install.packages("rmarkdown", repos = "https://cloud.r-project.org")']],
                    { focus = false })
                notify("Installing rmarkdown in the terminal; render again when it finishes")
            end
            return
        end
        run({
            "Rscript", "-e",
            ("rmarkdown::render(%q, output_format = %q, quiet = TRUE)"):format(name, spec.r),
        })
    end

    if vim.fn.executable("Rscript") == 1 then
        with_r()
    else
        require("deps").ensure("Rscript", { reason = "rendering R Markdown" }, function(ok)
            if ok then vim.schedule(with_r) end
        end)
    end
end

-- ------------------------------------------------------------------ setup

function M.setup()
    -- Markdown to everything else: render-markdown, lists, tables, hints.
    vim.filetype.add({ extension = { Rmd = "markdown", rmd = "markdown", qmd = "markdown" } })

    -- The R inside {r} chunks is highlighted by the R parser, fetched once.
    vim.api.nvim_create_autocmd("BufReadPost", {
        group = vim.api.nvim_create_augroup("RmarkdownSetup", { clear = true }),
        pattern = { "*.Rmd", "*.rmd", "*.qmd" },
        callback = function(args)
            vim.b[args.buf].rmarkdown = true
            vim.keymap.set("n", "<leader>n", M.run_chunk, { buffer = args.buf, desc = "Run the R chunk under the cursor" })
            vim.keymap.set("x", "<leader>n", function()
                M.run_selection()
                vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
            end, { buffer = args.buf, desc = "Run the selected lines in R" })
            if vim.env.NVIM_DEPS_QUIET or #vim.api.nvim_list_uis() == 0 then return end
            if not pcall(vim.treesitter.language.add, "r") then
                pcall(function() require("nvim-treesitter").install({ "r" }) end)
            end
        end,
    })

    local commands = {
        { "RmdRunChunk", M.run_chunk, "Run the R chunk under the cursor" },
        { "RmdRunAll", M.run_all, "Run every R chunk, top to bottom" },
        { "RmdRunAbove", M.run_above, "Run the R chunks up to and including this one" },
        { "RmdConsole", function() M.console(function() end) end, "Start (or show) the R session" },
        { "RmdStop", M.stop, "End the R session" },
        { "RmdClearPlots", M.clear_plots, "Remove the plots shown in this note" },
        { "RmdPlots", M.open_plots, "Open the plots of the last run in the default viewer" },
    }
    for _, c in ipairs(commands) do
        vim.api.nvim_create_user_command(c[1], c[2], { nargs = 0, desc = c[3] })
    end
    vim.api.nvim_create_user_command("RmdRender", function(args) M.render(args.args) end, {
        nargs = "?",
        complete = function() return { "html", "pdf", "word" } end,
        desc = "Render this file to html (default), pdf or word, and open it",
    })
end

return M
