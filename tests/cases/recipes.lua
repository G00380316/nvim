-- Surround / unwrap recipes edit the buffer as their names say.
local function recipe(label)
    for _, item in ipairs(require("recipes").items()) do
        if item.label == label then return item.run end
    end
    error("no recipe " .. label)
end
local function buf(lines, row, col)
    vim.cmd("enew!")
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
    vim.api.nvim_win_set_cursor(0, { row, col })
end
local function text() return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") end

buf({ "say hello there" }, 1, 6)
recipe("Surround word with double quotes")()
T.eq(text(), 'say "hello" there', "word in double quotes")

buf({ 'say "hello" there' }, 1, 7)
recipe("Remove the double quotes around the cursor")()
T.eq(text(), "say hello there", "quotes removed")

buf({ 'say "hello" there' }, 1, 7)
recipe("Change double quotes to single quotes")()
T.eq(text(), "say 'hello' there", "quotes changed")

buf({ "f(a, b)" }, 1, 3)
recipe("Change parentheses to square brackets")()
T.eq(text(), "f[a, b]", "brackets changed")

buf({ "say hello there" }, 1, 4)
vim.cmd("normal! viw\27")
recipe("Surround selection with parentheses")()
T.eq(text(), "say (hello) there", "selection in parentheses")

buf({ "a", "b" }, 1, 0)
recipe("Duplicate the line")()
vim.wait(100)
T.ok(#require("recipes").items() > 50, "plenty of recipes")
