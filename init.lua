--- Plugins ---

vim.pack.add({
	{ src = "https://github.com/stevearc/oil.nvim" },
	{ src = "https://github.com/nvim-telescope/telescope.nvim",          version = "0.1.8" },
	{ src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },
	{ src = "https://github.com/nvim-lua/plenary.nvim" },
	{ src = "https://github.com/voldikss/vim-floaterm" },
	{ src = "https://github.com/nvim-tree/nvim-web-devicons" },

	{ src = "https://github.com/rebelot/kanagawa.nvim" },
	{ src = "https://github.com/lewis6991/gitsigns.nvim" },
	{ src = "https://github.com/lukas-reineke/indent-blankline.nvim" },
	{ src = "https://github.com/HiPhish/rainbow-delimiters.nvim" },

	{ src = "https://github.com/3rd/image.nvim" },

	{ src = "https://github.com/neovim/nvim-lspconfig" },
	{ src = "https://github.com/chomosuke/typst-preview.nvim" },

})


--- Vim Settings ---

vim.cmd([[set mouse=]])
vim.cmd([[set noswapfile]])

vim.cmd([[hi @lsp.type.number gui=italic]])
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
vim.cmd(":hi statusline guibg=NONE")
vim.cmd(":hi signcolumn guibg=NONE")
vim.cmd [[
  highlight CursorLine cterm=NONE ctermbg=236 guibg=#2e2e2e
]]
vim.cmd("set completeopt+=noselect")

vim.o.tabstop = 4
vim.o.autoindent = true

vim.o.matchtime = 2   -- How long to show matching bracket

vim.o.autoread = true -- Auto reload files changed outside vim

vim.o.winborder = "rounded"

vim.o.hlsearch = true  -- `hlsearch = false`: Disables the highlighting of search results after searching.
vim.o.incsearch = true -- `incsearch = true`: Shows incremental search results as you type.

vim.o.number = true
vim.o.relativenumber = true
vim.o.cursorline = true
vim.o.guicursor = "n-v-c-sm:block-blinkon1,i-ci-ve:ver25,r-cr-o:hor20,a:Cursor/Cursor"
vim.o.signcolumn = "yes"
vim.o.scrolloff = 10 -- Keeps 10 lines of context around the cursor when scrolling.
vim.o.wrap = false

vim.o.termguicolors = true
vim.o.undofile = true
vim.o.clipboard = "unnamedplus" -- Adding clipboard func with wl-clipboard
vim.diagnostic.config({ virtual_text = true })


--- Plugin Configs ---  (Keymaps Line 137)

require("kanagawa").setup({
	compile = false, -- enable compiling the colorscheme
	undercurl = true, -- enable undercurls
	commentStyle = { italic = true },
	functionStyle = {},
	keywordStyle = { italic = false },
	statementStyle = { bold = true },
	typeStyle = {},
	transparent = true, -- do not set background color
	dimInactive = false, -- dim inactive window `:h hl-NormalNC`
	terminalColors = true, -- define vim.g.terminal_color_{0,17}
	colors = {      -- add/modify theme and palette colors
		palette = {},
		theme = {
			wave = {},
			dragon = {},
			all = {
				ui = {
					bg_gutter = "none",
					border = "rounded"
				}
			}
		},
	},
	overrides = function(colors) -- add/modify highlights
		local theme = colors.theme
		return {
			NormalFloat = { bg = "none" },
			FloatBorder = { bg = "none" },
			FloatTitle = { bg = "none" },
			Pmenu = { fg = theme.ui.shade0, bg = "NONE", blend = vim.o.pumblend }, -- add `blend = vim.o.pumblend` to enable transparency
			PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
			PmenuSbar = { bg = theme.ui.bg_m1 },
			PmenuThumb = { bg = theme.ui.bg_p2 },

			-- Save an hlgroup with dark background and dimmed foreground
			-- so that you can use it where your still want darker windows.
			-- E.g.: autocmd TermOpen * setlocal winhighlight=Normal:NormalDark
			NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },

			-- Popular plugins that open floats will link to NormalFloat by default;
			-- set their background accordingly if you wish to keep them dark and borderless
			LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
			MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
			TelescopeTitle = { fg = theme.ui.special, bold = true },
			TelescopePromptBorder = { fg = theme.ui.special, },
			TelescopeResultsNormal = { fg = theme.ui.fg_dim, },
			TelescopeResultsBorder = { fg = theme.ui.special, },
			TelescopePreviewBorder = { fg = theme.ui.special },
		}
	end,
	theme = "wave", -- Load "wave" theme when 'background' option is not set
	background = { -- map the value of 'background' option to a theme
		dark = "wave", -- try "dragon" !
	},
})


local telescope = require("telescope")
telescope.setup({
	defaults = {
		preview = { treesitter = true },
		color_devicons = true,
		sorting_strategy = "ascending",
		borderchars = {
			"", -- top
			"", -- right
			"", -- bottom
			"", -- left
			"", -- top-left
			"", -- top-right
			"", -- bottom-right
			"", -- bottom-left
		},
		file_ignore_patterns = {
			"node_modules",
			".git/",
			"dist/",
			"build/",
			"target/",
		},
		mappings = {
			i = {
				["<C-d>"] = "delete_buffer",
			},
			n = {
				["<C-d>"] = "delete_buffer",
			},
		},
		path_displays = { "smart" },
		layout_config = {
			height = 100,
			width = 400,
			prompt_position = "top",
			preview_cutoff = 40,
		},
		pickers = {
			buffers = {
				sort_mru = true,
				ignore_current_buffer = true,
			},
		},
	},
	keys = {
		vim.keymap.set({ "n", "v", "i" }, "<C-f>", ":Telescope find_files<CR>", { desc = "File Lookup" }),
		vim.keymap.set({ "n", "v", "i" }, "<C-g>", ":Telescope live_grep<CR>", { desc = "Grep" }),
		vim.keymap.set("n", "<leader>h", ":Telescope help_tags<CR>", { desc = "I need Help" }),
		vim.keymap.set("n", "zcf", function()
			require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
		end, { desc = "Find Config Files" }),
		vim.keymap.set({ "n", "x" }, "<leader>g", function() -- zwg
			local b = require("telescope.builtin")
			if vim.fn.mode():find("[vV]") then
				b.grep_string({ search = vim.fn.getreg('z'), use_regex = false })
			else
				b.grep_string({ search = vim.fn.expand("<cword>") })
			end
		end, { desc = "Search Visual selection or Word" }),
		vim.keymap.set("n", "zkm", ":Telescope keymaps<CR>", { desc = "Search Keymaps" }),
		-- vim.keymap.set("n", "zsb", ":Telescope git_branches<CR>", { desc = "Git Branches" })
		vim.keymap.set({ "n", "v", "i" }, "<C-b>", "<cmd>Telescope buffers<CR>", { desc = "Choose a buffer" }),
	}
})
telescope.load_extension("ui-select")


require("oil").setup({
	default_file_explorer = true, -- Replaces netrw
	watch_for_changes = true,
	delete_to_trash = true,
	columns = {
		"icon",
		-- "permissions",
		-- "size",
		-- "mtime",
	},
	skip_confirm_for_simple_edits = true,
	use_default_keymaps = false,
	view_options = {
		show_hidden = true,
	},
	float = {
		padding = 2,
		max_width = 80,
		max_height = 20,
		border = "rounded",
	},
	keymaps = {
		["g?"] = { "actions.show_help", mode = "n" },
		["<CR>"] = "actions.select",
		["zv"] = { "actions.select", opts = { vertical = true } },
		["zh"] = { "actions.select", opts = { horizontal = true } },
		["<C-t>"] = { "actions.select", opts = { tab = true } },
		["<C-p>"] = "actions.preview",
		["<C-c>"] = { "actions.close", mode = "n" },
		["<C-l>"] = "actions.refresh",
		["<BS>"] = { "actions.parent", mode = "n" },
		["_"] = { "actions.open_cwd", mode = "n" },
		["`"] = { "actions.cd", mode = "n" },
		["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
		["gs"] = { "actions.change_sort", mode = "n" },
		["gx"] = "actions.open_external",
		["g."] = { "actions.toggle_hidden", mode = "n" },
		["g\\"] = { "actions.toggle_trash", mode = "n" },
	},
	keys = {
		vim.keymap.set({ "n", "i", "v" }, "<C-e>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", true)
			require("oil").toggle_float()
		end, { desc = "Toggle Oil Float" }),
	},
})


require("image").setup({
	backend = "kitty",
	processor = "magick_cli", -- or "magick_rock"
	integrations = {
		markdown = {
			enabled = true,
			clear_in_insert_mode = false,
			download_remote_images = true,
			only_render_image_at_cursor = false,
			only_render_image_at_cursor_mode = "popup",
			floating_windows = false,
			filetypes = { "markdown", "vimwiki" },
		},
		neorg = {
			enabled = true,
			filetypes = { "norg" },
		},
		typst = {
			enabled = true,
			filetypes = { "typst" },
		},
		html = {
			enabled = false,
		},
		css = {
			enabled = false,
		},
	},
	max_width = nil,
	max_height = nil,
	max_width_window_percentage = nil,
	max_height_window_percentage = 50,
	window_overlap_clear_enabled = false,
	window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "snacks_notif", "scrollview", "scrollview_sign" },
	editor_only_render_when_focused = false,
	tmux_show_only_in_active_window = false,
	hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
})

local highlight = {
	"Color1",
	"Color2",
	"Color3",
	"Color4",
	"Color5",
	"Color6",
}

local sunflowerDelims = {
	"Sunflower1",
	"Sunflower2",
	"Sunflower3",
	"Sunflower4",
	"Sunflower5",
}

local hooks = require("ibl.hooks")
-- create the highlight groups in the highlight setup hook, so they are reset
-- every time the colorscheme changes
hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
	vim.api.nvim_set_hl(0, "Color1", { fg = "#d26487" })
	vim.api.nvim_set_hl(0, "Color2", { fg = "#35a8a5" })
	vim.api.nvim_set_hl(0, "Color3", { fg = "#6981c5" })
	vim.api.nvim_set_hl(0, "Color4", { fg = "#a15ea7" })
	vim.api.nvim_set_hl(0, "Color5", { fg = "#288668" })
	vim.api.nvim_set_hl(0, "Color6", { fg = "#ca754b" })
	vim.api.nvim_set_hl(0, "Sunflower1", { fg = "#FBCA47" })
	vim.api.nvim_set_hl(0, "Sunflower2", { fg = "#FBEB62" })
	vim.api.nvim_set_hl(0, "Sunflower3", { fg = "#DE6D11" })
	vim.api.nvim_set_hl(0, "Sunflower4", { fg = "#CF6B13" })
	vim.api.nvim_set_hl(0, "Sunflower5", { fg = "#F69F22" })
end)

vim.g.rainbow_delimiters = { highlight = sunflowerDelims }
require("ibl").setup({
	indent = { highlight = highlight },
	scope = { highlight = sunflowerDelims, show_start = false, show_end = false },
})

hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)


vim.g.floaterm_autoclose = true           -- Automatically close terminal window when process exits

vim.api.nvim_create_autocmd("TermOpen", { -- Close the current floating terminal
	pattern = "floaterm",
	callback = function()
		local opts = { noremap = true, silent = true, buffer = true }
		vim.keymap.set("n", "<c-k>", ":q<cr>", opts)
		vim.keymap.set("v", "<c-k>", "<c-\\><c-n>:q<cr>", opts)
		vim.keymap.set("i", "<c-k>", "<c-\\><c-n>:q<cr>", opts)
		vim.keymap.set("t", "<c-k>", "<c-\\><c-n>:q<cr>", opts)
	end,
})

vim.api.nvim_set_keymap("n", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true }) -- Navigate to the previous floating terminal
vim.api.nvim_set_keymap("v", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zp", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("n", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "zn", "<cmd>:FloatermNext<CR>", { noremap = true, silent = true })

vim.api.nvim_set_keymap("n", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true }) -- Open a new floating terminal
vim.api.nvim_set_keymap("v", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("i", "<C-t>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("t", "<C-t>", "<cmd>FloatermNew<CR>", { noremap = true, silent = true })


--- AutoCmds ---

local smart_cd_group = vim.api.nvim_create_augroup("SmartCD", { clear = true })

local function find_project_root(file_path)
	-- Get the directory of the current file
	local dir = vim.fn.fnamemodify(file_path, ":h")
	if dir == "" or not vim.fn.isdirectory(dir) then
		return nil
	end

	-- Search upwards for project markers
	local markers = { ".git", "package.json", ".project" }
	local root = vim.fs.find(markers, { path = dir, upward = true, type = "directory" })[1]
	    or vim.fs.find(markers, { path = dir, upward = true, type = "file" })[1]

	if root then
		-- Return the directory containing the marker
		return vim.fn.fnamemodify(root, ":h")
	end

	return nil
end

vim.api.nvim_create_autocmd("BufEnter", {
	group = smart_cd_group,
	pattern = "*", -- Run for all files
	callback = function()
		local file_path = vim.api.nvim_buf_get_name(0)
		if file_path == "" then return end

		-- Find the project root using our new function
		local project_root = find_project_root(file_path)

		-- Determine the target directory
		local target_dir
		if project_root then
			target_dir = project_root   -- Target the discovered project root 🌳
		else
			target_dir = vim.fn.fnamemodify(file_path, ":h") -- Fallback to the file's directory
		end

		-- Change directory only if needed and the target is valid
		if target_dir and vim.fn.isdirectory(target_dir) == 1 and vim.fn.getcwd() ~= target_dir then
			vim.cmd.cd(target_dir)
		end
	end,
	desc = "Smartly change directory to project root or file's directory",
})

local autoclose_group =
    vim.api.nvim_create_augroup("AutoCloseFloats", { clear = true })

local function limit_buffers(max)
	local bufs = vim.tbl_filter(function(buf)
		return vim.api.nvim_buf_is_loaded(buf)
		    and vim.bo[buf].buflisted
	end, vim.api.nvim_list_bufs())

	if #bufs > max then
		table.sort(bufs) -- older buffers first
		for i = 1, #bufs - max do
			vim.api.nvim_buf_delete(bufs[i], { force = true })
		end
	end
end

-- Limit total buffers
vim.api.nvim_create_autocmd("BufEnter", {
	group = autoclose_group,
	callback = function()
		limit_buffers(20)
	end,
})

-- Remove empty unnamed buffers
vim.api.nvim_create_autocmd("BufLeave", {
	group = autoclose_group,
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		local name = vim.api.nvim_buf_get_name(bufnr)

		if name == ""
		    and not vim.bo[bufnr].modified
		    and vim.bo[bufnr].buflisted
		    and vim.bo[bufnr].buftype == ""
		then
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(bufnr)
				    and vim.api.nvim_get_current_buf() ~= bufnr
				then
					vim.api.nvim_buf_delete(bufnr, { force = true })
				end
			end)
		end
	end,
})

-- Remove directory buffers
vim.api.nvim_create_autocmd("BufLeave", {
	group = autoclose_group,
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		local name = vim.api.nvim_buf_get_name(bufnr)

		if vim.fn.isdirectory(name) == 1
		    and not vim.bo[bufnr].modified
		    and vim.bo[bufnr].buftype == ""
		then
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(bufnr)
				    and vim.api.nvim_get_current_buf() ~= bufnr
				then
					vim.api.nvim_buf_delete(bufnr, { force = true })
				end
			end)
		end
	end,
})

-- Extra safety pass on BufEnter (kept intentionally)
vim.api.nvim_create_autocmd("BufEnter", {
	group = autoclose_group,
	callback = function()
		local bufnr = vim.api.nvim_get_current_buf()
		local name = vim.api.nvim_buf_get_name(bufnr)

		if name == ""
		    and not vim.bo[bufnr].modified
		    and vim.bo[bufnr].buflisted
		    and vim.bo[bufnr].buftype == ""
		then
			vim.schedule(function()
				if vim.api.nvim_buf_is_valid(bufnr)
				    and vim.api.nvim_get_current_buf() ~= bufnr
				then
					vim.api.nvim_buf_delete(bufnr, { force = true })
				end
			end)
		end
	end,
})

-- Define a list of filetypes that should NOT be auto-closed
local exclude_filetypes = {
	"TelescopePrompt",
	"NvimTree",
	"lazy",
	"mason",
	"noice",
	"alpha",
	"trouble",
	"snacks",
	"Leet"
}

vim.api.nvim_create_autocmd("WinLeave", {
	group = autoclose_group,
	pattern = "*",
	callback = function(args)
		local win_id = args.win
		local bufnr = args.buf

		-- First, ensure win_id is a number before using it.
		if type(win_id) ~= "number" then
			return
		end

		-- Then, check if the window is still valid.
		if not vim.api.nvim_win_is_valid(win_id) then
			return
		end

		-- Check if the buffer in the window is listed for exclusion
		local ftype = vim.bo[bufnr].filetype
		if vim.tbl_contains(exclude_filetypes, ftype) then
			return
		end

		-- Get window configuration
		local config = vim.api.nvim_win_get_config(win_id)

		-- Check if the window is a float
		if config.relative ~= "" then
			vim.schedule(function()
				-- check validity again inside the schedule
				if vim.api.nvim_win_is_valid(win_id) then
					vim.api.nvim_win_close(win_id, true)
				end
			end)
		end
	end,
})

local function enter_insert_if_zsh()
	-- Check if the buffer is a terminal running zsh
	local bufname = vim.fn.expand('%:p')
	if bufname:match("zsh") then
		vim.cmd("startinsert")
	end
end

-- Autocmd for when entering a terminal buffer
vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "term://*",
	callback = enter_insert_if_zsh,
})

local augroup = vim.api.nvim_create_augroup("UserConfig", {})

-- Auto-close terminal when process exits
vim.api.nvim_create_autocmd("TermClose", {
	group = augroup,
	callback = function()
		if vim.v.event.status == 0 then
			vim.api.nvim_buf_delete(0, {})
		end
	end,
})


--- Special Mappings ---

vim.keymap.set("n", "<C-d>", "<C-d>zz")                            -- Scroll Half-Page and Center
vim.keymap.set("n", "<C-u>", "<C-u>zz")                            -- Scroll Half-Page and Center
vim.keymap.set("n", "n", "nzzzv")                                  -- Center Search Results
vim.keymap.set("n", "N", "Nzzzv")                                  -- Center Search Results
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")                       -- Move Selected Text Up/Down in Visual Mode
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")                       -- Move Selected Text Up/Down in Visual Mode
vim.keymap.set("v", ">", ">gv", { noremap = true, silent = true }) -- Outdent selected block of text
vim.keymap.set("v", "<", "<gv", { noremap = true, silent = true }) -- Outdent selected block of text

vim.keymap.set({ 'n', 'v' }, 'y', '"+y')
vim.keymap.set({ "n", "v" }, "d", [["_d]]) -- Delete Without Affecting Clipboard
-- Standard-editor-style visual paste
vim.keymap.set("x", "p", function()
	return '"_dP'
end, { expr = true, silent = true })

-- Open lazygit in floating terminal (main UI)
vim.keymap.set("n", "zg", function()
	local buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		style = "minimal",
		border = "rounded",
	})
	vim.fn.jobstart({ "lazygit" }, { term = true })
	vim.cmd("startinsert")
end, { desc = "Open Lazygit in floating terminal" })


--- LSP ---

vim.lsp.enable({ "lua_ls" })


--- Keymaps ---

vim.g.mapleader = " "

vim.keymap.set('n', '<leader>o', ':update<CR> :source<CR>', { desc = "Update Source" })
vim.keymap.set('n', '<C-s>', ':write<CR>', { desc = "Write Changes" })
vim.keymap.set('n', '<leader>q', ':quit<CR>', { desc = "Quit" })


vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { desc = "Format Code" })


vim.keymap.set({ "n", "v", "i", "t" }, "<C-q>", "<cmd>bd!<CR>", { noremap = true, silent = true })


--- Most be Last ---

vim.cmd("colorscheme kanagawa")
