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

      -- Function to get the root directory for LSP servers
      local function get_root_dir()
        local bufnr = vim.api.nvim_get_current_buf()
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == "" then
          return nil
        end
        return vim.fn.fnamemodify(fname, ":p:h")
      end

      -- Function to re-setup the LSP servers
      local function setup_servers()
        local new_root = get_root_dir()

      -- List of LSP servers to setup
      local servers = {
        lua_ls = {},
        pyright = {},
        tsserver = {}
        -- Add more servers as needed
      }

      for server, config in pairs(servers) do
        config.root_dir = get_root_dir
        lspconfig[server].setup(config)
        end
      end

    -- Initial setup of LSP servers
    setup_servers()

    -- Autocommand to re-setup the LSP servers on BufEnter event
    vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "*",
    callback = function()
      setup_servers()
      end
    })
    end
  }

    -- Function to Setup Servers:

    -- The setup_servers function gets the current buffer and file name, and then determines the new root directory as the directory of the current file.
    -- It sets up the LSP servers (Lua, Pyright, TSServer) with this new root directory.

    -- Initial LSP Setup:

    -- The initial call to setup_servers ensures that the LSP servers are set up when Neovim starts.

    -- Autocommand for BufEnter:

    -- The vim.api.nvim_create_autocmd function creates an autocommand that triggers the setup_servers function whenever a new buffer is entered. This ensures that the LSP servers are reconfigured to use the directory of the current file as the root directory each time you open a new file.

}
