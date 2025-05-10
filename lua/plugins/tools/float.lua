return {
    {
        "voldikss/vim-floaterm",
        config = function()
            vim.g.floaterm_autoclose = true -- Automatically close terminal window when process exits

            -- Close the current floating terminal
            vim.api.nvim_create_autocmd("filetype", {
                pattern = "floaterm",
                callback = function()
                    local opts = { noremap = true, silent = true, buffer = true }
                    vim.keymap.set("n", "<c-k>", ":q<cr>", opts)
                    vim.keymap.set("v", "<c-k>", "<c-\\><c-n>:q<cr>", opts)
                    vim.keymap.set("i", "<c-k>", "<c-\\><c-n>:q<cr>", opts)
                    vim.keymap.set("t", "<c-k>", "<c-\\><c-n>:q<cr>", opts)
                end,
            })
            -- Open lazygit in a floating terminal
            -- vim.cmd("command! LazyGitFloaterm FloatermNew lazygit")
            -- vim.api.nvim_set_keymap("n", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
            -- vim.api.nvim_set_keymap("v", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
            -- vim.api.nvim_set_keymap("i", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })
            -- vim.api.nvim_set_keymap("t", "<C-b>", "<cmd>LazyGitFloaterm<CR>", { noremap = true, silent = true })

            -- Navigate to the previous floating terminal
            vim.api.nvim_set_keymap("n", "ztp", ":FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("v", "ztp", ":FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("i", "ztp", ":FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("t", "ztp", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("n", "ztn", ":FloatermNext<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("v", "ztn", ":FloatermNext<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("i", "ztn", ":FloatermNext<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("t", "ztn", "<cmd>:FloatermNext<CR>", { noremap = true, silent = true })

            -- Open a new floating terminal
            vim.api.nvim_set_keymap("n", "<C-z>", ":FloatermNew<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("v", "<C-z>", ":FloatermNew<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("i", "<C-z>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("t", "<C-z>", "<cmd>FloatermNew<CR>", { noremap = true, silent = true })
            vim.keymap.set("n", "<C-t>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
            vim.keymap.set("v", "<C-t>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
            vim.keymap.set("i", "<C-t>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
            vim.keymap.set("t", "<C-t>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
        end,
    },
}
