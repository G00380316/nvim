return {
   "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
  config = function()
    require('neo-tree').setup{}
    vim.keymap.set('n', '<C-e>', ':Neotree filesystem reveal left<CR>', {}) -- <CR> immitates enter so we don't have to press enter after Ctrl and e 
  end
}
