return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {"lua_ls","pyright","tsserver"}
      })
    end
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local lspconfig = require("lspconfig")

      vim.keymap.set({'n', 'v'},'I', vim.lsp.buf.hover,{}) -- This gives you information on the function or keyword (shift and i) 
      vim.keymap.set({'n', 'v'},'D', vim.lsp.buf.definition,{}) -- This takes you to the module or place where a function is usually defined (shift and d)
      vim.keymap.set({'n','v'}, '<leader>a', vim.lsp.buf.code_action,{}) -- To use code actions (space and a) this allows you to see warnings given by the LSP


      lspconfig.lua_ls.setup({})
      lspconfig.pyright.setup({})
      lspconfig.tsserver.setup({})
    end
  }
}
