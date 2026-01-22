---@brief
---
--- https://github.com/swiftlang/sourcekit-lsp
---
--- Language server for Swift and C/C++/Objective-C.

local util = require 'lspconfig.util'

---@type vim.lsp.Config
return {
	cmd = { 'sourcekit-lsp' },
	filetypes = { 'swift', 'objc', 'objcpp', 'c', 'cpp' },
	root_dir = function(bufnr, on_dir)
		local filename = vim.api.nvim_buf_get_name(bufnr)
		on_dir(
			util.root_pattern('buildServer.json', '.bsp')(filename)
			or util.root_pattern('*.xcodeproj', '*.xcworkspace')(filename)
			-- better to keep it at the end, because some modularized apps contain multiple Package.swift files
			or util.root_pattern('compile_commands.json', 'Package.swift')(filename)
			or vim.fs.dirname(vim.fs.find('.git', { path = filename, upward = true })[1])
		)
	end,
	get_language_id = function(_, ftype)
		local t = { objc = 'objective-c', objcpp = 'objective-cpp' }
		return t[ftype] or ftype
	end,
	capabilities = {
		workspace = {
			didChangeWatchedFiles = {
				dynamicRegistration = true,
			},
		},
		textDocument = {
			diagnostic = {
				dynamicRegistration = true,
				relatedDocumentSupport = true,
			},
		},
	},
	on_init = function(client)
		local root = client.config.root_dir
		if not root then
			return
		end

		-- If BSP already exists, do nothing
		if vim.fn.filereadable(root .. "/buildServer.json") == 1 then
			return
		end

		-- Only auto-generate for Xcode projects
		local xcodeproj = vim.fn.glob(root .. "/*.xcodeproj")
		if xcodeproj == "" then
			return
		end

		local scheme = vim.fn.fnamemodify(xcodeproj, ":t:r")

		vim.notify("SourceKit: generating buildServer.json…", vim.log.levels.INFO)

		vim.fn.jobstart({
			"xcode-build-server",
			"config",
			"-project",
			xcodeproj,
			"-scheme",
			scheme,
		}, {
			cwd = root,
			detach = true,
			on_exit = function()
				vim.schedule(function()
					local bsp = root .. "/buildServer.json"

					if vim.fn.filereadable(bsp) == 1 then
						vim.notify("SourceKit BSP ready, restarting LSP", vim.log.levels.INFO)
						vim.cmd("lsp restart sourcekit")
					else
						vim.notify(
							"SourceKit BSP generation failed (buildServer.json not found)",
							vim.log.levels.ERROR
						)
					end
				end)
			end,
		})
	end,
}
