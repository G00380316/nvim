-- A terminal panel gets a title bar; an editor window keeps the global winbar.
vim.cmd("edit " .. T.file("a.py", "x=1\n"))
local editor = vim.api.nvim_get_current_win()
vim.cmd("TerminalNew")
vim.wait(800)
vim.cmd("wincmd k")
vim.wait(300)

local seen_panel = false
for _, w in ipairs(vim.api.nvim_list_wins()) do
    local wb = vim.api.nvim_get_option_value("winbar", { win = w, scope = "local" })
    if w == editor then
        T.eq(wb, "", "editor window has no local winbar")
    elseif vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "floaterm" then
        seen_panel = true
        vim.g.statusline_winid = w
        local r = vim.api.nvim_eval_statusline(wb, { winid = w, use_winbar = true })
        T.ok(r.str:find("TERMINAL"), "terminal panel is titled")
    end
end
T.ok(seen_panel, "a terminal panel exists")
