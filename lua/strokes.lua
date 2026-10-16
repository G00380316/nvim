---Recorded strokes, in nine slots (1-9). Start from the palette, press a number,
---do the thing, <C-s> saves it and <C-c> throws it away. `<leader>.` and a number
---plays it back, with a count in front to repeat (3<leader>.1).
---
---Unlike a macro, what is typed in insert mode is not replayed as keystrokes. The
---text that ended up in the buffer is taken, and played back as if pasted: the
---same result every time, whatever autopairs, completion or snippets did while
---you typed it. Everything outside insert mode -- motions, deletes, commands --
---is recorded as the keys typed. A recording always starts in normal mode.
local M = {}

local file = vim.fn.stdpath("state") .. "/strokes.json"
local ns = vim.api.nvim_create_namespace("strokes")

---@class strokes.Segment
---@field keys? string keys typed (raw bytes)
---@field text? string text that ended up in the buffer from an insert

---@type { slot: integer, keys: string, segs: strokes.Segment[], in_insert: boolean, finish: boolean }?
local rec
local playing = false
local chunks, chunk_index = {}, 0
local slots ---@type table<string, strokes.Segment[]>?

-- ------------------------------------------------------------------ storage

local function load()
    slots = {}
    if vim.fn.filereadable(file) ~= 1 then return end
    local ok, data = pcall(vim.json.decode, table.concat(vim.fn.readfile(file), "\n"))
    if not (ok and type(data) == "table") then return end
    for slot, segs in pairs(data) do
        slots[slot] = {}
        for _, seg in ipairs(segs) do
            -- Stored as base64: typed keys are raw bytes, not always valid text.
            if seg.k then slots[slot][#slots[slot] + 1] = { keys = vim.base64.decode(seg.k) } end
            if seg.t then slots[slot][#slots[slot] + 1] = { text = vim.base64.decode(seg.t) } end
        end
    end
end

local function save_file()
    local out = {}
    for slot, segs in pairs(slots) do
        out[slot] = {}
        for _, seg in ipairs(segs) do
            out[slot][#out[slot] + 1] = seg.keys and { k = vim.base64.encode(seg.keys) } or { t = vim.base64.encode(seg.text) }
        end
    end
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":h"), "p")
    pcall(vim.fn.writefile, { vim.json.encode(out) }, file)
end

function M.get(slot)
    if not slots then load() end
    return slots[tostring(slot)]
end

function M.slots()
    if not slots then load() end
    local list = {}
    for n = 1, 9 do
        if slots[tostring(n)] then list[#list + 1] = n end
    end
    return list
end

local function notify(message, level)
    vim.notify(message, level or vim.log.levels.INFO, { title = "Strokes" })
end

-- ---------------------------------------------------------------- recording

local function mode_first()
    return vim.api.nvim_get_mode().mode:sub(1, 1)
end

---Is a recording in progress?
function M.recording() return rec ~= nil end

---Text for the statusline while recording.
function M.status()
    if not rec then return "" end
    return ("󰑊 REC %d  \u{b7}  <C-s> save  \u{b7}  <C-c> cancel"):format(rec.slot)
end

-- The mappings <C-s> and <C-c> had before the recording covered them.
local covered = {}

local function teardown()
    vim.on_key(nil, ns)
    for _, mode in ipairs({ "n", "i", "x" }) do
        for _, lhs in ipairs({ "<C-s>", "<C-c>" }) do
            pcall(vim.keymap.del, mode, lhs)
            local before = covered[mode .. lhs]
            if before and not vim.tbl_isempty(before) then pcall(vim.fn.mapset, mode, false, before) end
        end
    end
    covered = {}
    rec = nil
    vim.cmd("redrawstatus")
end

---The text an insert left in the buffer: from `'[` to `']`.
local function inserted_text()
    local s, e = vim.fn.getpos("'["), vim.fn.getpos("']")
    if s[2] == 0 or e[2] == 0 then return nil end
    local srow, scol, erow, ecol = s[2] - 1, s[3] - 1, e[2] - 1, e[3] - 1
    if erow < srow or (erow == srow and ecol < scol) then return nil end
    -- ']' is the last inserted character; the range is end-exclusive, and a
    -- character may be several bytes.
    local line = vim.api.nvim_buf_get_lines(0, erow, erow + 1, false)[1] or ""
    local extra = 0
    if ecol < #line then extra = vim.str_utf_end(line, ecol + 1) or 0 end
    ecol = math.min(#line, ecol + 1 + extra)
    local ok, parts = pcall(vim.api.nvim_buf_get_text, 0, srow, scol, erow, ecol, {})
    if not ok then return nil end
    local text = table.concat(parts, "\n")
    return text ~= "" and text or nil
end

local function finish_insert()
    if not (rec and rec.in_insert) then return end
    rec.in_insert = false
    if rec.keys ~= "" then rec.segs[#rec.segs + 1] = { keys = rec.keys } end
    local text = inserted_text()
    if text then rec.segs[#rec.segs + 1] = { text = text } end
    -- Insert mode ended with <Esc> (or something that acts like it).
    rec.keys = "\27"
end

local function commit()
    if not rec then return end
    -- The <C-s> that asked for this is typed, so it is the last key recorded.
    rec.keys = rec.keys:gsub("\19$", "")
    if rec.keys ~= "" then rec.segs[#rec.segs + 1] = { keys = rec.keys } end
    local slot, segs = rec.slot, rec.segs
    if not slots then load() end
    if #segs == 0 then
        teardown()
        notify("Nothing was recorded", vim.log.levels.WARN)
        return
    end
    slots[tostring(slot)] = segs
    save_file()
    teardown()
    notify(("Saved to slot %d: play it with <leader>. then %d"):format(slot, slot))
end

---Save the recording. In insert mode, the insert is finished first.
function M.save()
    if not rec then return end
    if mode_first() == "i" or mode_first() == "R" then
        rec.finish = true
        vim.cmd("stopinsert")
        return
    end
    commit()
end

function M.cancel()
    if not rec then return end
    teardown()
    notify("Recording cancelled")
end

---Start recording into a slot.
---@param slot integer 1-9
function M.start(slot)
    if rec then
        notify("Already recording: <C-s> saves it, <C-c> cancels", vim.log.levels.WARN)
        return
    end
    if not (slot and slot >= 1 and slot <= 9) then return end
    if mode_first() ~= "n" then pcall(vim.cmd, "stopinsert") end

    rec = { slot = slot, keys = "", segs = {}, in_insert = false, finish = false }

    vim.on_key(function(key, typed)
        if not rec or playing then return end
        local mode = mode_first()
        if mode == "i" or mode == "R" or mode == "t" then return end
        -- Only what was typed. The keys a mapping expands to (autopairs, for one,
        -- feeds expressions) arrive with nothing typed and are not part of this.
        if not typed or typed == "" then return end
        rec.keys = rec.keys .. typed
    end, ns)

    -- <C-s> saves and <C-c> cancels, from any mode, for as long as this lasts.
    -- What they did before is remembered and put back afterwards (<C-s> is
    -- "save and format" the rest of the time).
    for _, mode in ipairs({ "n", "i", "x" }) do
        for _, lhs in ipairs({ "<C-s>", "<C-c>" }) do
            covered[mode .. lhs] = vim.fn.maparg(lhs, mode, false, true)
        end
        vim.keymap.set(mode, "<C-s>", M.save, { silent = true, desc = "Save the strokes being recorded" })
        vim.keymap.set(mode, "<C-c>", M.cancel, { silent = true, desc = "Cancel the recording" })
    end

    vim.cmd("redrawstatus")
    notify(("Recording to slot %d: do it, then <C-s> saves or <C-c> cancels. Typing in insert mode is kept as text."):format(slot))
end

-- ------------------------------------------------------------------ playing

---The next piece of text to insert while a playback is running.
function M.chunk()
    chunk_index = chunk_index + 1
    return chunks[chunk_index] or ""
end

---Play a slot back.
---@param slot integer
---@param count? integer
function M.play(slot, count)
    local segs = M.get(slot)
    if not segs then
        notify(("Slot %d is empty"):format(slot), vim.log.levels.WARN)
        return
    end
    if rec then
        notify("Finish or cancel the recording first", vim.log.levels.WARN)
        return
    end

    chunks, chunk_index = {}, 0
    local keys = {}
    local once = {}
    for _, seg in ipairs(segs) do
        if seg.keys then
            once[#once + 1] = seg.keys
        else
            -- Inserted literally, as if pasted: <C-r><C-o>= puts an expression's
            -- value in without autopairs, abbreviations or completion getting a say.
            once[#once + 1] = "\18\15=v:lua.require'strokes'.chunk()\r"
        end
    end
    local sequence = table.concat(once)

    for _ = 1, math.max(1, count or 1) do
        keys[#keys + 1] = sequence
        for _, seg in ipairs(segs) do
            if seg.text then chunks[#chunks + 1] = seg.text end
        end
    end

    playing = true
    local ok, err = pcall(vim.api.nvim_feedkeys, table.concat(keys), "mx", false)
    playing = false
    if not ok then notify("Could not play slot " .. slot .. ": " .. tostring(err), vim.log.levels.ERROR) end
end

function M.delete(slot)
    if not slots then load() end
    if slots[tostring(slot)] then
        slots[tostring(slot)] = nil
        save_file()
        notify(("Slot %d cleared"):format(slot))
    end
end

-- ------------------------------------------------------------------ prompts

---Ask for a slot number: the next key pressed, 1-9. Escape or anything else cancels.
---@param prompt string
---@return integer?
local function ask_slot(prompt)
    vim.api.nvim_echo({ { prompt .. " (1-9, Esc cancels): ", "Question" } }, false, {})
    local ok, char = pcall(vim.fn.getcharstr)
    vim.cmd("redraw")
    local n = ok and tonumber(char)
    if n and n >= 1 and n <= 9 then return n end
    return nil
end

function M.record_command()
    local slot = ask_slot("Record strokes into slot")
    if slot then M.start(slot) end
end

function M.play_command(count)
    local slot = ask_slot("Play strokes from slot")
    if slot then M.play(slot, count) end
end

function M.delete_command()
    local slot = ask_slot("Clear slot")
    if slot then M.delete(slot) end
end

---Every saved slot, with a short description of what it does.
local function describe(segs)
    local parts = {}
    for _, seg in ipairs(segs) do
        if seg.text then
            parts[#parts + 1] = ('insert "%s"'):format((seg.text:gsub("\n", "\u{21b5}")):sub(1, 24))
        else
            parts[#parts + 1] = vim.fn.strtrans(seg.keys):sub(1, 24)
        end
    end
    return table.concat(parts, "  ")
end

function M.list()
    local slots_list = M.slots()
    if #slots_list == 0 then
        notify("No strokes saved yet: Record strokes in the palette")
        return
    end
    local items = {}
    for _, n in ipairs(slots_list) do
        items[#items + 1] = { text = n .. " " .. describe(M.get(n)), slot = n, desc = describe(M.get(n)) }
    end
    vim.ui.select(items, {
        prompt = "Strokes (Enter plays)",
        format_item = function(item) return ("%d  %s"):format(item.slot, item.desc) end,
    }, function(choice)
        if choice then vim.schedule(function() M.play(choice.slot) end) end
    end)
end

function M.setup()
    vim.api.nvim_create_user_command("StrokesRecord", M.record_command, { desc = "Record keystrokes into slot 1-9 (<C-s> saves, <C-c> cancels)" })
    vim.api.nvim_create_user_command("StrokesPlay", function() M.play_command() end, { desc = "Play strokes back from slot 1-9" })
    vim.api.nvim_create_user_command("StrokesList", M.list, { desc = "List the saved strokes; pick one to play" })
    vim.api.nvim_create_user_command("StrokesClear", M.delete_command, { desc = "Clear a strokes slot" })

    vim.keymap.set("n", "<leader>.", function()
        M.play_command(vim.v.count1)
    end, { desc = "Play recorded strokes (then a number 1-9; a count repeats)" })

    local group = vim.api.nvim_create_augroup("Strokes", { clear = true })
    vim.api.nvim_create_autocmd("InsertEnter", {
        group = group,
        callback = function()
            if rec and not playing then
                rec.in_insert = true
            end
        end,
    })
    vim.api.nvim_create_autocmd("InsertLeave", {
        group = group,
        callback = function()
            if rec and rec.in_insert then
                finish_insert()
                if rec.finish then
                    rec.finish = false
                    vim.schedule(commit)
                end
            end
        end,
    })
    vim.api.nvim_create_autocmd("VimLeavePre", { group = group, callback = function() if rec then teardown() end end })
end

return M
