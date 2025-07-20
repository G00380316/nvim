return {
    "goolord/alpha-nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")

        dashboard.section.header.val = {
            "                                                 ",
            " ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
            " ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
            " ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
            " ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
            " ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
            " ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
            "                                                 ",
        }

        dashboard.section.header.opts.position = "center"
        dashboard.section.footer.opts.position = "center"
        dashboard.section.buttons.val = {
            dashboard.button("s", "  Session", "<cmd>SessionManager load_session<CR>"),
            dashboard.button("r", "  Connect to Remote", "<cmd>SshLauncher<CR>"),
            dashboard.button("l", "  LeetCode", "<cmd>Leet<CR>"),
        }
        local fortune = require("alpha.fortune")
        dashboard.section.footer.val = fortune()

        dashboard.section.header.opts.hl = "Statement"
        dashboard.section.buttons.opts.hl = "Type"
        dashboard.section.footer.opts.hl = "Type"

        table.insert(dashboard.opts.layout, 1, { type = "padding", val = 5 })

        alpha.setup(dashboard.opts)

        -- Disable folding on alpha buffer
        vim.cmd([[
    autocmd FileType alpha setlocal nofoldenable
]])

        vim.keymap.set({ "n", "t" }, "<C-x>", "<cmd>Alpha<CR>", { noremap = true, silent = true })
    end,
}
