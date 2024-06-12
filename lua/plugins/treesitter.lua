return {
  "nvim-treesitter/nvim-treesitter", build = ":TSUpdate",
  config = function()
    local config = require("nvim-treesitter.configs")
    config.setup({
      ensure_installed = {"c","lua","vim","html","css","java","javascript","cpp","gitignore","php","python","xml","typescript","yaml","ssh_config","sql","csv","dockerfile","json","json5"},
      sync_install = false,
      highlight = { enable = true },
      indent = { enable = true },
    })
  end
}
