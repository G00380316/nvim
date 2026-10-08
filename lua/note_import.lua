local M = {}

-- Bring a document in as a Markdown note: a PDF, a Word file, a web page, a scan
-- or a screenshot. The result is a new note next to the one you are in (or at the
-- project root), headed with where it came from, and opened.
--
-- It uses what is on the machine and says what is missing rather than failing:
--
--   PDF                    the bundled reader, built on PDFKit (scripts/pdf2md.swift),
--                          compiled once; scanned pages are OCR'd with tesseract
--   Word, ODT, RTF, HTML   pandoc when installed, giving real Markdown --
--                          headings, lists, tables, images; otherwise macOS's own
--                          textutil, which gives the text but not the structure
--   EPUB, PPTX, LaTeX ...  pandoc only
--   images                 embedded, with the text in them if tesseract is there
--   txt, md                taken as they are

local script = vim.fn.stdpath("config") .. "/scripts/pdf2md.swift"
local binary = vim.fn.stdpath("cache") .. "/pdf2md"

local pandoc_only = {
    epub = true, pptx = true, xlsx = true, tex = true, latex = true, rst = true, org = true,
    ipynb = true, textile = true, mediawiki = true, odp = true, fb2 = true, docbook = true,
}
local textutil_formats = {
    docx = true, doc = true, odt = true, rtf = true, html = true, htm = true, webarchive = true,
}
local text_formats = { txt = true, md = true, markdown = true, text = true }
local images = {
    png = true, jpg = true, jpeg = true, gif = true, webp = true, tiff = true, tif = true, bmp = true, heic = true,
}

---All the extensions the importer will accept, for the file picker.
local function supported()
    local list = { "pdf" }
    for _, set in ipairs({ pandoc_only, textutil_formats, text_formats, images }) do
        for extension in pairs(set) do list[#list + 1] = extension end
    end
    table.sort(list)
    return list
end

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Import" })
end

local function extension_of(path)
    return vim.fn.fnamemodify(path, ":e"):lower()
end

---Where the new note goes: beside the Markdown note being edited, else the
---project root.
local function destination_directory()
    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.bo[buf].filetype == "markdown" and name ~= "" then
        return vim.fs.dirname(name)
    end
    return require("workspace").get()
end

local function unique_path(directory, stem)
    stem = stem:gsub("[/\\:]", "-")
    local path = directory .. "/" .. stem .. ".md"
    local n = 1
    while vim.uv.fs_stat(path) do
        n = n + 1
        path = string.format("%s/%s %d.md", directory, stem, n)
    end
    return path
end

---Run a command and hand back its output, off the main thread.
---@param command string[]
---@param opts? table
---@param done fun(ok: boolean, stdout: string, stderr: string)
local function run(command, opts, done)
    local started, err = pcall(vim.system, command, vim.tbl_extend("force", { text = true }, opts or {}),
        vim.schedule_wrap(function(result)
            done(result.code == 0, result.stdout or "", result.stderr or "")
        end))
    if not started then done(false, "", tostring(err)) end
end

-- ---------------------------------------------------------------- converters

---The PDF reader is a small Swift program compiled on first use and again only
---when its source changes.
local function with_pdf_reader(callback)
    local built, source = vim.uv.fs_stat(binary), vim.uv.fs_stat(script)
    if built and source and built.mtime.sec >= source.mtime.sec then
        return callback(binary)
    end

    if vim.fn.executable("swiftc") ~= 1 then
        return callback(nil, "PDF import needs the Swift toolchain. Install it with: xcode-select --install")
    end

    notify("Preparing the PDF reader (once, takes a few seconds)...")
    vim.fn.mkdir(vim.fn.fnamemodify(binary, ":h"), "p")
    run({ "swiftc", "-O", script, "-o", binary }, nil, function(ok, _, stderr)
        if ok then
            callback(binary)
        else
            callback(nil, "Could not build the PDF reader:\n" .. stderr)
        end
    end)
end

local function convert_pdf(path, _, done)
    with_pdf_reader(function(reader, err)
        if not reader then return done(nil, err) end
        run({ reader, path }, nil, function(ok, stdout, stderr)
            if not ok then
                return done(nil, vim.trim(stderr) ~= "" and vim.trim(stderr) or "The PDF could not be read")
            end
            -- The reader says on stderr how much it read, and what it could
            -- not. The first is a result; only the second is a caveat.
            local detail, problems = nil, {}
            for line in vim.gsplit(vim.trim(stderr), "\n", { plain = true }) do
                if line:match("^read %d+ page") then
                    detail = line:gsub("^read ", ""):gsub("page%(s%)", "pages")
                elseif line ~= "" then
                    problems[#problems + 1] = line
                end
            end
            done(stdout, nil, #problems > 0 and table.concat(problems, "; ") or nil, detail)
        end)
    end)
end

---A leading bullet character, removed. Spelled out rather than as a [..] class:
---a Lua character class matches single bytes, and these are several bytes each,
---so a class would match the first byte of a bullet and leave the rest behind.
local bullet_marks = { "•", "●", "▪", "◦", "·" }

local function strip_bullet(text)
    for _, mark in ipairs(bullet_marks) do
        if text:sub(1, #mark) == mark then return vim.trim(text:sub(#mark + 1)) end
    end
end

local entities = { amp = "&", lt = "<", gt = ">", quot = '"', apos = "'", nbsp = " ", ["#39"] = "'" }

local function decode(text)
    return (text:gsub("&(#?%w+);", function(name) return entities[name] end))
end

---Word, RTF and HTML through macOS's own converter, as HTML.
---
---textutil does not know Markdown, but its HTML records the font size of every
---paragraph, which is most of what makes a heading one: the sizes stand in for
---heading levels exactly as they do for PDFs, a short all-bold line is a
---smaller heading, and the bullets Word writes as text become list items.
---Tables, links and images are lost; pandoc keeps them.
local function from_textutil(path, done)
    run({ "textutil", "-convert", "html", "-encoding", "UTF-8", "-stdout", path }, nil, function(ok, html, stderr)
        if not ok then return done(nil, vim.trim(stderr)) end

        -- p.p1 {... font: 24.0px Times} -> the size each paragraph class is set in
        local class_size = {}
        for class, size in html:gmatch("p%.(%w+)%s*{[^}]-font:%s*([%d%.]+)px") do
            class_size[class] = tonumber(size)
        end

        local body = html:match("<body[^>]*>(.*)</body>") or html

        ---@type { pos: integer, kind: string, class: string?, level: string?, inner: string }[]
        local blocks = {}
        for pos, attrs, inner in body:gmatch("()<p%f[%W]([^>]*)>(.-)</p>") do
            blocks[#blocks + 1] = { pos = pos, kind = "p", class = attrs:match('class="(%w+)"'), inner = inner }
        end
        -- %2, not %1: the position capture "()" is capture number one.
        for pos, level, inner in body:gmatch("()<h([1-6])%f[%W][^>]*>(.-)</h%2>") do
            blocks[#blocks + 1] = { pos = pos, kind = "h", level = level, inner = inner }
        end
        for pos, inner in body:gmatch("()<li%f[%W][^>]*>(.-)</li>") do
            blocks[#blocks + 1] = { pos = pos, kind = "li", inner = inner }
        end
        table.sort(blocks, function(a, b) return a.pos < b.pos end)

        -- The size most of the text is set in is the body; larger ones are headings.
        local weight, sizes = {}, {}
        for _, block in ipairs(blocks) do
            local size = block.class and class_size[block.class]
            if size then
                local length = #decode((block.inner:gsub("<[^>]+>", "")))
                weight[size] = (weight[size] or 0) + length
            end
        end
        local body_size, best = 0, -1
        for size, count in pairs(weight) do
            if count > best then body_size, best = size, count end
        end
        for size in pairs(weight) do
            if body_size > 0 and size >= body_size * 1.15 then sizes[#sizes + 1] = size end
        end
        table.sort(sizes, function(a, b) return a > b end)

        local out, previous_item = {}, false
        for _, block in ipairs(blocks) do
            local text = vim.trim(decode((block.inner:gsub("<[^>]+>", ""):gsub("%s+", " "))))
            if text ~= "" then
                local line, is_item = text, false
                local all_bold = block.inner:gsub("<b>.-</b>", ""):gsub("<[^>]+>", ""):gsub("%s+", "") == ""

                local bullet = strip_bullet(text)
                local numbered, rest = text:match("^(%d+[.)])%s+(.*)$")

                if block.kind == "h" then
                    line = string.rep("#", tonumber(block.level) + 1) .. " " .. text
                elseif block.kind == "li" or bullet then
                    line, is_item = "- " .. (bullet or text), true
                elseif numbered then
                    line, is_item = numbered .. " " .. rest, true
                else
                    local size = block.class and class_size[block.class]
                    local rank
                    for index, candidate in ipairs(sizes) do
                        if candidate == size then rank = index end
                    end
                    if rank then
                        line = string.rep("#", math.min(rank + 1, 4) + 1) .. " " .. text
                    elseif all_bold and #text <= 60 and not text:match("[.,;]$") then
                        line = "##### " .. text
                    end
                end

                if #out > 0 and not (is_item and previous_item) then out[#out + 1] = "" end
                out[#out + 1] = line
                previous_item = is_item
            end
        end
        done(table.concat(out, "\n"))
    end)
end

local function convert_office(path, ctx, done)
    local extension = extension_of(path)

    if vim.fn.executable("pandoc") == 1 then
        -- Named after the note, not the source: two imports that share a source
        -- name (a report.docx and a report.epub) must not share their pictures.
        -- No spaces: one in a link target ends the link.
        local media = ctx.note_stem:gsub("%s+", "-") .. "_files"
        run({
            "pandoc", "-t", "gfm", "--wrap=none",
            "--lua-filter=" .. vim.fn.stdpath("config") .. "/scripts/plain-markdown.lua",
            "--extract-media=" .. media, path,
        }, { cwd = ctx.directory }, function(ok, stdout, stderr)
                if ok then return done(stdout) end
                done(nil, "pandoc could not read it: " .. vim.trim(stderr))
            end)
        return
    end

    if pandoc_only[extension] then
        return done(nil, "." .. extension .. " files need pandoc. Install it with: brew install pandoc")
    end

    from_textutil(path, function(text, err)
        if not text then return done(nil, err) end
        done(text, nil, "pandoc is not installed, so this is the text without headings or tables. "
            .. "Install it for full conversion: brew install pandoc")
    end)
end

local function convert_image(path, ctx, done)
    local relative = vim.fs.relpath(ctx.directory, path) or path
    local body = string.format("![%s](%s)", ctx.stem, relative)

    if vim.fn.executable("tesseract") ~= 1 then
        return done(body, nil, "tesseract is not installed, so only the picture was added. "
            .. "Install it to read the text in it: brew install tesseract")
    end

    run({ "tesseract", path, "stdout" }, nil, function(ok, stdout)
        local text = ok and vim.trim(stdout) or ""
        if text ~= "" then
            body = body .. "\n\n## Text in the image\n\n" .. text
        end
        done(body)
    end)
end

local function convert_text(path, _, done)
    local ok, lines = pcall(vim.fn.readfile, path)
    if not ok then return done(nil, "Could not read " .. path) end
    done(table.concat(lines, "\n"))
end

---@return fun(path: string, ctx: table, done: function)?, string? problem
local function converter_for(path)
    local extension = extension_of(path)
    if extension == "pdf" then return convert_pdf end
    if images[extension] then return convert_image end
    if text_formats[extension] then return convert_text end
    if textutil_formats[extension] or pandoc_only[extension] then return convert_office end
    return nil, extension ~= "" and ("Do not know how to import ." .. extension .. " files")
        or "That file has no extension to tell what it is"
end

-- -------------------------------------------------------------------- import

---@param path string
function M.import(path)
    path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")
    if vim.fn.filereadable(path) ~= 1 then
        return notify("No such file: " .. path, vim.log.levels.ERROR)
    end

    local convert, problem = converter_for(path)
    if not convert then return notify(problem, vim.log.levels.WARN) end

    local ctx = {
        directory = destination_directory(),
        stem = vim.fn.fnamemodify(path, ":t:r"),
    }
    -- Decided now, not after converting, because the converter needs a name for
    -- the folder it puts pictures in.
    ctx.note = unique_path(ctx.directory, ctx.stem)
    ctx.note_stem = vim.fn.fnamemodify(ctx.note, ":t:r")

    notify("Importing " .. vim.fs.basename(path) .. "...")
    convert(path, ctx, function(body, err, caveat, detail)
        if not body then
            return notify("Import failed: " .. tostring(err), vim.log.levels.ERROR)
        end

        local note = ctx.note
        local header = {
            "# " .. ctx.stem,
            "",
            string.format("> Imported from `%s` on %s", vim.fn.fnamemodify(path, ":~"), os.date("%Y-%m-%d")),
            "",
        }
        local lines = vim.list_extend(header, vim.split(vim.trim(body), "\n", { plain = true }))
        lines[#lines + 1] = ""

        local ok, write_err = pcall(vim.fn.writefile, lines, note)
        if not ok then
            return notify("Could not write the note: " .. tostring(write_err), vim.log.levels.ERROR)
        end

        pcall(vim.cmd, "EditorFocus")
        vim.cmd.edit(vim.fn.fnameescape(note))
        notify("Imported as " .. vim.fn.fnamemodify(note, ":~:.") .. (detail and (" (" .. detail .. ")") or ""))
        if caveat then notify(caveat, vim.log.levels.WARN) end
    end)
end

---Choose a file from the places documents usually are.
function M.pick()
    local home = vim.fn.expand("~")
    local dirs = {}
    for _, directory in ipairs({ require("workspace").get(), home .. "/Downloads", home .. "/Documents", home .. "/Desktop" }) do
        if vim.fn.isdirectory(directory) == 1 and not vim.tbl_contains(dirs, directory) then
            dirs[#dirs + 1] = directory
        end
    end

    Snacks.picker.files({
        title = "Import a document  (PDF, Word, web page, image ...)",
        dirs = dirs,
        ft = supported(),
        hidden = false,
        confirm = function(picker, item)
            picker:close()
            if not item then return end
            local file = Snacks.picker.util.path(item)
            vim.schedule(function() M.import(file) end)
        end,
    })
end

function M.setup()
    vim.api.nvim_create_user_command("NoteImport", function(args)
        if args.args ~= "" then M.import(args.args) else M.pick() end
    end, {
        nargs = "?",
        complete = "file",
        desc = "Import a PDF, Word file, web page or image as a Markdown note",
    })
end

return M
