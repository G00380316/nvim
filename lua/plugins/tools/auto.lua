return {
	"windwp/nvim-ts-autotag",
	event = "InsertEnter",
	config = function()
		require("nvim-ts-autotag").setup({
			opts = {
				enable_close = true,          -- <div> → </div>
				enable_rename = true,         -- <div> → <span></span>
				enable_close_on_slash = true, -- </ completes tag
			},
			per_filetype = {
				html = {
					enable_close = true,
				},
			},
		})
	end,
}
