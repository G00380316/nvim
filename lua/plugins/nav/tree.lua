return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup({
      sort = {
        sorter = "case_sensitive",
      },
      view = {
        width = 25,
      },
      renderer = {
        group_empty = true,
      },
      filters = {
        dotfiles = false, -- Hides dotfiles by default
      },
      actions = {
        open_file = {
          quit_on_open = true, -- Automatically closes nvim-tree when you open a file
        },
      },
    })
  end,
}
