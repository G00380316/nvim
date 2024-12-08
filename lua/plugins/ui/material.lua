return {
    "marko-cerovac/material.nvim",
    name = "material",
    priority = 1000,
    config = function()
        -- Enable transparency for material theme
        require("material").setup({
            background_colour = "#000000",
            contrast = {
                sidebars = false,         -- Disable contrast for sidebars
                floating_windows = false, -- Disable contrast for floating windows
            },
            disable = {
                background = true, -- This disables the background color (enables transparency)
            },
        })

        -- Set the colorscheme
        vim.cmd.colorscheme("material")
    end,
}
