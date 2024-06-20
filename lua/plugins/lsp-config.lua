return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "pyright",
          "tsserver",
          "jdtls",
          "html",
          "clangd",
          "vimls",
          "tailwindcss",
          "jsonls",
          "angularls",
          "arduino_language_server",
          "rust_analyzer"
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local lspconfig = require("lspconfig")

      local original_notify = vim.notify
      vim.notify = function(msg, log_level, opts)
        -- Suppress specific messages
        if msg:match("language server") or msg:match("LSP") or msg:match("lsp.log") then
          -- Filter out the specific LSP errors
          return
        end
        original_notify(msg, log_level, opts)
      end

      local function setup_servers()
        lspconfig.tsserver.setup({ -- JavaScript
          capabilities = capabilities,
        })
        lspconfig.jdtls.setup({ -- Java
          capabilities = capabilities,
        })
        lspconfig.html.setup({ -- Html
          capabilities = capabilities,
        })
        lspconfig.lua_ls.setup({ -- Lua
          capabilities = capabilities,
        })
        lspconfig.pyright.setup({ -- Python
          capabilities = capabilities,
        })
        lspconfig.clangd.setup({ -- C/C++
          capabilities = capabilities,
        })
        lspconfig.vimls.setup({ --  Vim
          capabilities = capabilities,
        })
        lspconfig.jsonls.setup({ -- JSON
          capabilities = capabilities,
        })
        lspconfig.angularls.setup({ -- Angular JS
          capabilities = capabilities,
        })
        lspconfig.arduino_language_server.setup({ -- Arduino
          capabilities = capabilities,
        })
        lspconfig.tailwindcss.setup({ -- Tailwind CSS
          capabilities = capabilities,
        })
        lspconfig.rust_analyzer.setup({ -- Rust
          capabilities = capabilities,
        })
      end

      setup_servers()

      vim.keymap.set({ "n", "v" }, "<C-i>", vim.lsp.buf.hover, {})        -- This gives you information on the function or keyword (shift and i)
      vim.keymap.set({ "n", "v" }, "<C-d>", vim.lsp.buf.definition, {})   -- This takes you to the module or place where a function is usually defined (shift and d)
      vim.keymap.set({ "n", "v" }, "<leader>a", vim.lsp.buf.code_action, {}) -- To use code actions (space and a) this allows you to see warnings given by the LSP

      --  Function to get the root directory for LSP servers
      local function get_root_dir()
        local bufnr = vim.api.nvim_get_current_buf()
        local fname = vim.api.nvim_buf_get_name(bufnr)
        if fname == "" then
          return nil
        end
        return vim.fn.fnamemodify(fname, ":p:h")
      end

      --  Autocommand to re-setup the LSP servers on BufEnter event
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          get_root_dir()
          setup_servers()
        end,
      })
      --  Add comment later
    end,
  },
}
