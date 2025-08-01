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
            vim.api.nvim_set_keymap("n", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("v", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("i", "zp", ":FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("t", "zp", "<cmd>:FloatermPrev<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("n", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("v", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("i", "zn", ":FloatermNext<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("t", "zn", "<cmd>:FloatermNext<CR>", { noremap = true, silent = true })

            -- Open a new floating terminal
            vim.api.nvim_set_keymap("n", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("v", "<C-t>", ":FloatermNew<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("i", "<C-t>", "<Esc>:FloatermNew<CR>", { noremap = true, silent = true })
            vim.api.nvim_set_keymap("t", "<C-t>", "<cmd>FloatermNew<CR>", { noremap = true, silent = true })
            vim.keymap.set("n", "<C-z>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
            vim.keymap.set("v", "<C-z>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
            vim.keymap.set("i", "<C-z>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
            vim.keymap.set("t", "<C-z>", function()
                local dir = vim.fn.expand('%:p:h')
                vim.cmd('FloatermNew! cd ' .. dir)
            end, { noremap = true, silent = true })
        end,
    },
}
