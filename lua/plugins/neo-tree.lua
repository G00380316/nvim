return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  config = function()
    require("neo-tree").setup({
      buffers = {
          follow_current_file = {
            enabled = true, -- This will find and focus the file in the active buffer every time
            --              -- the current file is changed while the tree is open.
            leave_dirs_open = false, -- `false` closes auto expanded dirs, such as with `:Neotree reveal`
          }
      }
   })
    vim.keymap.set("n", "<C-e>", ":Neotree filesystem reveal left<CR>", {}) -- <CR> immitates enter so we don't have to press enter after Ctrl and e
    vim.keymap.set("v", "<C-e>", ":Neotree filesystem reveal left<CR>", {})
    vim.keymap.set("t", "<C-e>", ":Neotree filesystem reveal left<CR>", { noremap = true, silent = true })
    vim.keymap.set("i", "<C-e>", "<Esc>:Neotree filesystem reveal left<CR>", { noremap = true, silent = true })
  end,
}
