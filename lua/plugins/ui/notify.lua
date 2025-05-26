return {
    "rcarriga/nvim-notify",
    config = function()
        vim.notify = require("notify")
        require("notify").setup({
            stages = "fade",               -- animation style: fade, slide, static
            timeout = 3000,                -- milliseconds before the popup disappears
            background_colour = "#000000", -- Optional: fixes transparency issues
            top_down = true,               -- Newer notifications on top
        })
    end,
}
