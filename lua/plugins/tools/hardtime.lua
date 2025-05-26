return {
    "m4xshen/hardtime.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
    event = "VeryLazy",
    opts = {
        max_count = 3, -- how many times a key can be pressed in a row
        disabled_keys = {
            ["<Up>"] = {}, ["<Down>"] = {}, ["<Left>"] = {}, ["<Right>"] = {}
        },
        restricted_keys = {
            ["h"] = { "n", "x" },
            ["j"] = { "n", "x" },
            ["k"] = { "n", "x" },
            ["l"] = { "n", "x" },
        },
        disable_mouse = true,
        hint = true, -- Show help message when you hit a restricted key
    }
}
