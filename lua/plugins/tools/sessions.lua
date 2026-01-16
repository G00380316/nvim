return {
    "Shatur/neovim-session-manager",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
        local config = require("session_manager.config")
        local session_manager = require("session_manager")

        session_manager.setup({
            autoload_mode = config.AutoloadMode.GitSession,
            autosave_last_session = true,
            autosave_only_in_session = true,

            autosave_ignore_dirs = { vim.loop.os_homedir() },
            autosave_ignore_filetypes = { "gitcommit", "oil" },
            autosave_ignore_buftypes = { "nofile", "quickfix" },

            load_include_current = false,
            max_path_length = 50,
        })
    end,
}
