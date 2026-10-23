local M = {}

-- Turn the Markdown note you are in into a document you can hand to someone, or
-- read in a browser. It uses pandoc, and xelatex for the PDF (both are in
-- Mac_Install), and says what is missing rather than failing.
--
--   MarkdownPdf       note.md -> note.pdf beside it, then opened
--   MarkdownHtml      note.md -> note.html beside it (one self-contained file:
--                     images and styles inside), then opened in the browser
--   MarkdownBrowser   a live-ish preview: rendered to the cache folder, opened in
--                     the browser, and re-rendered every time the note is saved
--                     (the page reloads itself every two seconds)

local style = [[
<style>
body { max-width: 46em; margin: 2em auto; padding: 0 1em; font: 16px/1.6 -apple-system, "Helvetica Neue", sans-serif; color: #222; }
pre { background: #f5f5f5; padding: .8em; overflow-x: auto; border-radius: 6px; }
code { background: #f5f5f5; padding: .1em .3em; border-radius: 4px; }
pre code { background: none; padding: 0; }
table { border-collapse: collapse; } td, th { border: 1px solid #ccc; padding: .3em .7em; }
blockquote { border-left: 4px solid #ccc; margin-left: 0; padding-left: 1em; color: #555; }
img { max-width: 100%; }
@media (prefers-color-scheme: dark) { body { background: #1e1e1e; color: #ddd; } pre, code { background: #2b2b2b; } td, th { border-color: #555; } blockquote { color: #aaa; border-color: #555; } }
</style>
]]

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Markdown export" })
end

---The note to export: the current buffer, saved first.
---@return string? path
local function current_note()
    local buf = vim.api.nvim_get_current_buf()
    local file = vim.api.nvim_buf_get_name(buf)
    if file == "" or not file:match("%.[mM][dD]$") and not file:match("%.markdown$") then
        notify("Open a Markdown note first", vim.log.levels.WARN)
        return nil
    end
    if vim.fn.executable("pandoc") == 0 then
        notify("pandoc is not installed (brew install pandoc)", vim.log.levels.WARN)
        return nil
    end
    if vim.bo[buf].modified then vim.cmd("silent write") end
    return file
end

local function resource_path(file)
    return vim.fn.fnamemodify(file, ":h")
end

---Run pandoc on `file`, calling `done(ok)` when it finishes.
local function pandoc(file, output, extra, done)
    local cmd = { "pandoc", file, "-o", output, "--resource-path=" .. resource_path(file) }
    vim.list_extend(cmd, extra)
    vim.system(cmd, { text = true, cwd = resource_path(file) }, vim.schedule_wrap(function(result)
        if result.code ~= 0 then
            local err = vim.trim(result.stderr or "")
            notify("pandoc failed:\n" .. (err ~= "" and err or ("exit " .. result.code)), vim.log.levels.ERROR)
            return done(false)
        end
        done(true)
    end))
end

local function open(path)
    vim.ui.open(path)
end

local function head_file(refresh)
    local path = vim.fn.stdpath("cache") .. "/markdown_export_head.html"
    local text = style
    if refresh then text = text .. '<meta http-equiv="refresh" content="2">\n' end
    vim.fn.writefile(vim.split(text, "\n"), path)
    return path
end

function M.pdf()
    local file = current_note()
    if not file then return end
    if vim.fn.executable("xelatex") == 0 then
        notify("xelatex is not installed (brew install --cask mactex-no-gui), try MarkdownHtml and print to PDF", vim.log.levels.WARN)
        return
    end
    local output = vim.fn.fnamemodify(file, ":r") .. ".pdf"
    notify("Making " .. vim.fn.fnamemodify(output, ":t") .. " ...")
    pandoc(file, output, {
        "--pdf-engine=xelatex", "-V", "geometry:margin=1in", "-V", "colorlinks=true", "--highlight-style=tango",
    }, function(ok)
        if not ok then return end
        notify("Saved " .. output)
        open(output)
    end)
end

function M.html()
    local file = current_note()
    if not file then return end
    local output = vim.fn.fnamemodify(file, ":r") .. ".html"
    pandoc(file, output, {
        "--standalone", "--embed-resources", "--metadata", "title=" .. vim.fn.fnamemodify(file, ":t:r"),
        "-H", head_file(false),
    }, function(ok)
        if not ok then return end
        notify("Saved " .. output)
        open(output)
    end)
end

local previews = {}

function M.browser()
    local file = current_note()
    if not file then return end
    local dir = vim.fn.stdpath("cache") .. "/markdown_preview"
    vim.fn.mkdir(dir, "p")
    local output = dir .. "/" .. vim.fn.fnamemodify(file, ":t:r") .. ".html"
    local function render(then_open)
        pandoc(file, output, {
            "--standalone", "--embed-resources", "--metadata", "title=" .. vim.fn.fnamemodify(file, ":t:r"),
            "-H", head_file(true),
        }, function(ok)
            if ok and then_open then open(output) end
        end)
    end
    render(true)
    if previews[file] then return end
    previews[file] = true
    vim.api.nvim_create_autocmd("BufWritePost", {
        buffer = vim.api.nvim_get_current_buf(),
        callback = function() render(false) end,
        desc = "Re-render the browser preview of this note",
    })
    notify("Browser preview: it updates when you save")
end

function M.setup()
    local commands = {
        MarkdownPdf = { M.pdf, "Save this note as a PDF beside it, and open it" },
        MarkdownHtml = { M.html, "Save this note as a self-contained web page, and open it in the browser" },
        MarkdownBrowser = { M.browser, "Preview this note in the browser, updating when you save" },
    }
    for name, spec in pairs(commands) do
        vim.api.nvim_create_user_command(name, function() spec[1]() end, { desc = spec[2] })
    end
end

return M
