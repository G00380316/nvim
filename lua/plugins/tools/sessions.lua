return {
    "Shatur/neovim-session-manager",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local config = require("session_manager.config")
        require("session_manager").setup({
            autoload_mode = config.AutoloadMode.CurrentDir,
            autosave_last_session = true,
            autosave_ignore_dirs = { vim.loop.os_homedir() },
            autosave_ignore_filetypes = { "gitcommit", "oil" },
            autosave_ignore_buftypes = { "nofile", "quickfix" },
        })
    end,
}
