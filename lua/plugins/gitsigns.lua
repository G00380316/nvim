return {
    {
        "tpope/vim-fugitive",
        config = function()
        end,
    },
    {
        "lewis6991/gitsigns.nvim",
        config = function()
            require("gitsigns").setup({
                signs = {
                    add = { text = "+" },          -- Symbol for added lines
                    change = { text = "~" },       -- Symbol for changed lines
                    delete = { text = "_" },       -- Symbol for deleted lines
                    topdelete = { text = "‾" },    -- Symbol for deleted lines at the top
                    changedelete = { text = "~" }, -- Symbol for changed and deleted lines
                },
                update_debounce = 100, -- Debounce time in milliseconds for updates
                status_formatter = nil,
            })
        end,
    },
}

