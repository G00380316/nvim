return {
    "G00380316/ssh-launcher.nvim",
    lazy = true,
    cmd = { "SshLauncher", "SshAddKey", "SshEditKey" },
    config = function()
        require("ssh_launcher").setup()
    end,
}
