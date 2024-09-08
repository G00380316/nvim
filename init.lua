local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("set")
require("keymaps")
require("lazy").setup("plugins")

local auto_save_group = vim.api.nvim_create_augroup("AutoSave", { clear = true })
--local auto_dir_group = vim.api.nvim_create_augroup("Dir", { clear = true })
--local auto_refresh_neotree = vim.api.nvim_create_augroup("Update", { clear = true })
local yank_group = vim.api.nvim_create_augroup("HighlightYank", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
	group = yank_group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 40,
		})
	end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = auto_save_group,
	pattern = "*",
	command = [[%s/\s\+$//e]],
})

-- Auto-save on buffer leave
--vim.api.nvim_create_autocmd("BufLeave", {
--  group = auto_save_group,
--  pattern = "*",
-- command = "silent! write",
--})

-- Auto-save on ModeChange
--vim.api.nvim_create_autocmd('ModeChanged', {
--   group = auto_save_group,
--   pattern = '*',
--   command = 'silent! write',
--})

-- Auto-save on CursorHold
vim.api.nvim_create_autocmd("CursorHold", {
	group = auto_save_group,
	pattern = "*",
	command = "silent! write",
})

-- Auto-Refresh Neo-tree on ModeChange
--vim.api.nvim_create_autocmd('ModeChanged', {
--   group = auto_refresh_neotree,
--   pattern = "*",
--   callback = function()
--      local current_win = vim.api.nvim_get_current_win()
--     local mode = vim.fn.mode()
--
--      for _, win in ipairs(vim.api.nvim_list_wins()) do
--         local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(win))
--         -- Check if the buffer name contains 'neo-tree'
--         if bufname:match("neo%-tree") then
--           if mode == 'i' or mode == 'n'then
--              -- Switch to the Neo-tree window
--               vim.cmd('Neotree')
--               -- Restore the original window
--               vim.api.nvim_set_current_win(current_win)
--               return
--            end
--         end
--      end
--   end,
--})

-- Auto-change directory to the file's directory on buffer enter
--vim.api.nvim_create_autocmd("BufEnter", {
--   group = auto_dir_group,
--   pattern = "*",
--   command = "silent! :cd %:p:h",
--})

-- Function to find the nearest directory containing package.json or .git
local function find_project_root()
	local path = vim.fn.expand("%:p:h")

	-- First, look for the nearest package.json
	local package_json_dir = vim.fn.findfile("package.json", path .. ";")
	if package_json_dir ~= "" then
		return vim.fn.fnamemodify(package_json_dir, ":p:h")
	end

	-- If no package.json is found, look for the nearest .git directory
	local git_dir = vim.fn.finddir(".git", path .. ";")
	if git_dir ~= "" then
		-- Return the parent directory of the .git directory
		return vim.fn.fnamemodify(git_dir, ":p:h:h")
	end

	-- If neither is found, fall back to the current file's directory
	return path
end

-- Auto-change directory to the nearest package.json, .git's parent directory, or current file's directory
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "*",
	callback = function()
		local project_root = find_project_root()
		if project_root then
			vim.cmd("silent! cd " .. project_root)
		end
	end,
})

vim.g.netrw_browse_split = 0
vim.g.netrw_banner = 0
vim.g.netrw_winsize = 25
