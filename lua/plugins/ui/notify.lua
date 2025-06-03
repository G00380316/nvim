return {
    "rcarriga/nvim-notify",
    config = function()
        require("notify").setup({
            stages = "fade_in_slide_out",  -- animation style: fade, slide, static
            timeout = 2000,                -- milliseconds before the popup disappears
            background_colour = "#000000", -- Optional: fixes transparency issues
            top_down = true,               -- Newer notifications on top
            render = "minimal"
        })
    end,
}
