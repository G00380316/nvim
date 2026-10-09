-- Action menus put the rows that suit where they were opened first.
local menus = require("action_menus")
local function first(menu, origin)
    return menus.ranked_actions(menus.menus[menu], origin)[1].label
end

vim.cmd("edit " .. T.file("page.html", "<p>x</p>\n"))
local file_win = vim.api.nvim_get_current_win()
local file_origin = { win = file_win, buf = vim.api.nvim_get_current_buf() }
T.eq(first("files", file_origin), "Open HTML file in browser", "html file: browser first")
T.eq(first("git", file_origin), "Preview hunk", "file buffer: hunk actions first")

vim.cmd("FocusTree")
vim.wait(500)
local oil_origin = { win = vim.api.nvim_get_current_win(), buf = vim.api.nvim_get_current_buf() }
T.eq(first("files", oil_origin), "Reveal in Finder", "explorer: reveal first")
T.eq(first("git", oil_origin), "Open LazyGit", "explorer: LazyGit first")
T.eq(first("view", oil_origin):lower():find("explorer") ~= nil, true, "explorer: explorer toggles first")

-- Nothing is lost.
T.eq(#menus.ranked_actions(menus.menus.git, oil_origin), #menus.menus.git.actions, "same rows")

-- Recently used rows rise: run one, and it leads a menu that has no opinion.
local ssh = menus.menus.ssh
local last = ssh.actions[#ssh.actions]
T.ok(menus.ranked_actions(ssh, oil_origin)[1] ~= last, "last row is not first to begin with")
local recent = require("recent_actions")
recent.record(recent.key(ssh.title, last.label))
T.eq(menus.ranked_actions(ssh, oil_origin)[1], last, "a row just used leads the menu")
T.eq(recent.key("Git Actions", "x"), recent.key("Git", "x"), "menu title and palette group share one key")
