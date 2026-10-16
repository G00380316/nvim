-- Strokes: record keys, keep inserted text as text, play back, save with <C-s>, cancel with <C-c>.
local strokes = require("strokes")
-- Typed keys are fed with "tx": treated as typed, and run to completion at once.
local function type_keys(keys) vim.api.nvim_feedkeys(keys, "tx", false) end
local function press_save() vim.api.nvim_feedkeys("\19", "mx", false) end
local save_before = vim.fn.maparg("<C-s>", "n", false, true).desc

local function fresh(lines)
    vim.cmd("enew!")
    vim.bo.filetype = "text"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
end
local function text() return vim.api.nvim_buf_get_lines(0, 0, -1, false) end

-- Record: go to the end of the line, type text in insert mode, leave.
fresh({ "one", "two", "three" })
strokes.start(1)
T.ok(strokes.recording(), "recording")
type_keys("A and more\27j")
vim.wait(200)
press_save()
vim.wait(300)
T.ok(not strokes.recording(), "<C-s> ended the recording")
T.eq(text(), { "one and more", "two", "three" }, "the recording itself did what was typed")
local segs = strokes.get(1)
T.ok(segs, "slot 1 was saved")
local kinds = {}
for _, seg in ipairs(segs) do kinds[#kinds + 1] = seg.text and ("text:" .. seg.text) or "keys" end
T.eq(kinds, { "keys", "text: and more", "keys" }, "keys, then the inserted text as text, then keys")
T.eq(segs[1].keys, "A", "the insert started with A")

-- <C-s> is the file save again afterwards.
T.eq(vim.fn.maparg("<C-s>", "n", false, true).desc, save_before, "<C-s> has its old meaning back")

-- Play it on the second line, from a fresh buffer.
fresh({ "alpha", "beta", "gamma" })
vim.api.nvim_win_set_cursor(0, { 2, 0 })
strokes.play(1)
T.eq(text(), { "alpha", "beta and more", "gamma" }, "played back: the text is added")
T.eq(vim.api.nvim_win_get_cursor(0)[1], 3, "and the motion after it ran too")

-- With a count.
fresh({ "a", "b", "c", "d" })
strokes.play(1, 2)
T.eq(text()[1], "a and more", "count: first line")
T.eq(text()[2], "b and more", "count: second line")

-- Insert text with characters that autopairs would mangle if typed again.
fresh({ "x" })
strokes.start(2)
type_keys("A foo(bar[1]) \"q\"\27")
vim.wait(200)
press_save()
vim.wait(300)
fresh({ "y" })
strokes.play(2)
local expected = vim.fn.getreg('"') ~= nil
local recorded
for _, seg in ipairs(strokes.get(2)) do if seg.text then recorded = seg.text end end
T.eq(text()[1], "y" .. recorded, "pasted text equals what ended up in the buffer when recorded")

-- Cancel.
fresh({ "keep" })
strokes.start(3)
type_keys("dd")
vim.wait(100)
vim.api.nvim_feedkeys("\3", "mx", false)
vim.wait(200)
T.ok(not strokes.recording(), "<C-c> cancelled")
T.eq(strokes.get(3), nil, "nothing was saved for a cancelled recording")

-- Saved across sessions: stored on disk.
T.eq(vim.fn.filereadable(vim.fn.stdpath("state") .. "/strokes.json"), 1, "slots are stored on disk")
strokes.delete(1); strokes.delete(2)
T.eq(strokes.get(1), nil, "a slot can be cleared")
