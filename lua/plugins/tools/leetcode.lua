return {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    dependencies = {
        "nvim-telescope/telescope.nvim",
        "nvim-lua/plenary.nvim", -- required by telescope
        "MunifTanjim/nui.nvim",

        -- optional
        "nvim-treesitter/nvim-treesitter",
        --        "rcarriga/nvim-notify",
        "nvim-tree/nvim-web-devicons",
    },
    opts = {
        -- configuration goes here
        ---@type lc.lang
        lang = "python3",
        ---@type boolean
        image_support = true,
        ---@type lc.storage
        storage = {
            home = "~/Coding/Projects/Leetcode",
            cache = vim.fn.stdpath("cache") .. "/leetcode",
        },
    },
}
