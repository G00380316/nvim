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
      use_libuv_file_watcher = true
  })
    vim.keymap.set("n", "<C-e>", ":Neotree filesystem reveal left<CR>", {noremap = true ,silent = true}) -- <CR> immitates enter so we don't have to press enter after Ctrl and e
    vim.keymap.set("v", "<C-e>", ":Neotree filesystem reveal left<CR>", {noremap = true, silent = true})
    vim.keymap.set("t", "<C-e>", ":Neotree filesystem reveal left<CR>", { noremap = true, silent = true })
    vim.keymap.set("i", "<C-e>", "<Esc>:Neotree filesystem reveal left<CR>", { noremap = true, silent = true })
  end,
}
