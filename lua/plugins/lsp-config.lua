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
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local lspconfig = require("lspconfig")

      lspconfig.tsserver.setup({
        capabilities = capabilities
      })
      lspconfig.solargraph.setup({
        capabilities = capabilities
      })
      lspconfig.html.setup({
        capabilities = capabilities
      })
      lspconfig.lua_ls.setup({
        capabilities = capabilities
      })

      vim.keymap.set({'n', 'v'},'<C-i>', vim.lsp.buf.hover,{}) -- This gives you information on the function or keyword (shift and i)
      vim.keymap.set({'n', 'v'},'<C-d>', vim.lsp.buf.definition,{}) -- This takes you to the module or place where a function is usually defined (shift and d)
      vim.keymap.set({'n','v'}, '<leader>a', vim.lsp.buf.code_action,{}) -- To use code actions (space and a) this allows you to see warnings given by the LSP

      --  Function to get the root directory for LSP servers
      local function get_root_dir()
        local bufnr = vim.api.nvim_get_current_buf()
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == "" then
          return nil
        end
        return vim.fn.fnamemodify(fname, ":p:h")
      end

      lspconfig.lua_ls.setup({})
      lspconfig.pyright.setup({})
      lspconfig.tsserver.setup({})

      --  Autocommand to re-setup the LSP servers on BufEnter event
      vim.api.nvim_create_autocmd("BufEnter", {
      pattern = "*",
      callback = function()
        end
      })
      --  Add comment later 
    end
  }
}
