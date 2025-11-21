return {
    "goolord/alpha-nvim",
    dependencies = {
        "nvim-tree/nvim-web-devicons",
    },

    config = function()
        local alpha = require("alpha")
        local dashboard = require("alpha.themes.dashboard")
        local telescope = require("telescope.builtin")

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
            dashboard.button("o", "  Open Folder", function()
                vim.ui.input({
                    prompt = "Open directory: ",
                    default = "~/",
                    completion = "dir",
                }, function(input)
                    if input and input ~= "" then
                        local dir = vim.fn.expand(input)

                        -- Open with Oil instead of a plain buffer
                        require("oil").open(dir)

                        -- Ask whether to create new file/folder
                        vim.ui.select({ "Open", "Create new file", "Create new folder" }, { prompt = "Action:" },
                            function(choice)
                                if choice == "Create new file" then
                                    local fname = vim.fn.input("File name: ")
                                    if fname and fname ~= "" then
                                        vim.cmd("edit " .. dir .. "/" .. fname)
                                    end
                                elseif choice == "Create new folder" then
                                    local dname = vim.fn.input("Folder name: ")
                                    if dname and dname ~= "" then
                                        vim.fn.mkdir(dir .. "/" .. dname, "p")
                                        print("Created folder: " .. dname)
                                    end
                                end
                            end)
                    end
                end)
            end),
            -- dashboard.button("o", "  Open Folder", function()
            --     -- Prompt user for a directory with autocomplete
            --     local dir = vim.fn.input("Enter directory path: ", "", "dir")
            --     if dir and dir ~= "" then
            --         -- Open the directory in a buffer
            --         vim.cmd("edit " .. dir)
            --
            --         -- Ask if they want to create a new file or folder
            --         vim.ui.select({ "Create new file", "Create new folder", "Just open" }, { prompt = "Action:" },
            --             function(choice)
            --                 if choice == "Create new file" then
            --                     local fname = vim.fn.input("File name: ")
            --                     if fname and fname ~= "" then
            --                         vim.cmd("edit " .. dir .. "/" .. fname)
            --                     end
            --                 elseif choice == "Create new folder" then
            --                     local dname = vim.fn.input("Folder name: ")
            --                     if dname and dname ~= "" then
            --                         vim.fn.mkdir(dir .. "/" .. dname, "p")
            --                         print("Created folder: " .. dname)
            --                     end
            --                 end
            --             end)
            --     end
            -- end),
            dashboard.button("s", "  Session", "<cmd>SessionManager load_session<CR>"),
            dashboard.button("r", "  Connect to Remote", "<cmd>SshLauncher<CR>"),
            dashboard.button("l", "  LeetCode", "<cmd>Leet<CR>"),
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
