return {
  {
    "nvim-tree/nvim-web-devicons",
    opts = {
      variant = "light",
      override = {
        zsh = { icon = "", color = "#428850", name = "Zsh" },
        ["Run_code.sh"] = { icon = "", color = "#428850", name = "Zsh" },
      },
    },
  },
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "clangd", "pyright", "rust-analyzer", "jdtls",
        "tailwindcss-language-server", "clang-format", "black", "prettier", "google-java-format", "marksman",
      },
    },
  },
  
  -- ==========================================================
  -- ===  THE FIX: ACTIVATE FRIENDLY SNIPPETS SAFELY        ===
  -- ==========================================================
  {
    "L3MON4D3/LuaSnip",
    -- 1. Ensure the snippet library is downloaded
    dependencies = { "rafamadriz/friendly-snippets" },
    -- 2. Configure LuaSnip to actually LOAD them
    config = function(_, opts)
      -- Load standard NvChad options
      require("luasnip").setup(opts)
      -- Load the VSCode-style snippets from friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()
    end,
  },
  -- ==========================================================

  -- 1. EMPOWERED LSP CONFIGURATION
  {
    "neovim/nvim-lspconfig",
    dependencies = { "pmizio/typescript-tools.nvim" },
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      local lspconfig = require "lspconfig"
      local nvlsp = require "nvchad.configs.lspconfig"

      -- Shared on_attach to enable Inlay Hints
      local on_attach = function(client, bufnr)
        nvlsp.on_attach(client, bufnr)
        if client.server_capabilities.inlayHintProvider then
           vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end

      -- Standard Servers (Removed clangd from loop to configure it manually)
      local servers = { "pyright", "jdtls", "tailwindcss" }
      for _, lsp in ipairs(servers) do
        lspconfig[lsp].setup {
          on_attach = on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
        }
      end

      -- === SPECIAL CONFIG FOR C++ (CLANGD + GCC HEADERS) ===
      lspconfig.clangd.setup {
        on_attach = on_attach,
        on_init = nvlsp.on_init,
        capabilities = nvlsp.capabilities,
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          -- This tells clangd to ask GCC where the headers (like bits/stdc++.h) are
          "--query-driver=/opt/homebrew/bin/g++-*,/usr/bin/g++",
        },
      }

      -- Rust with Specific Settings
      lspconfig.rust_analyzer.setup {
        on_attach = on_attach,
        on_init = nvlsp.on_init,
        capabilities = nvlsp.capabilities,
        settings = {
          ["rust-analyzer"] = {
            inlayHints = {
              bindingModeHints = { enable = true },
              typeHints = { enable = true },
              chainingHints = { enable = true },
              parameterHints = { enable = true },
            },
          },
        },
      }
    end,
  },
  -- 2. JETBRAINS-GRADE TYPESCRIPT
  {
    "pmizio/typescript-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
    ft = { "typescript", "typescriptreact", "javascript", "javascriptreact" },
    opts = {
      on_attach = function(client, bufnr)
        require("nvchad.configs.lspconfig").on_attach(client, bufnr)
        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end
      end,
      settings = {
        tsserver_file_preferences = {
          includeInlayParameterNameHints = "all",
          includeInlayParameterNameHintsWhenArgumentMatchesName = false,
          includeInlayFunctionParameterTypeHints = true,
          includeInlayVariableTypeHints = true,
          includeInlayPropertyDeclarationTypeHints = true,
          includeInlayFunctionLikeReturnTypeHints = true,
          includeInlayEnumMemberValueHints = true,
        },
        separate_diagnostic_server = true,
        publish_diagnostic_on = "insert_leave",
        jsx_close_tag = { enable = true, filetypes = { "javascriptreact", "typescriptreact" } },
      },
    },
  },
  -- 3. STANDARD TREESITTER
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      indent = { enable = true }, 
      highlight = { enable = true },
      ensure_installed = { "typescript", "tsx", "javascript", "html", "css", "rust", "python", "lua", "c", "cpp", "markdown", "markdown_inline" },
    },
  },
  -- 4. AUTOPAIRS (Restored to Simple/Safe mode)
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup {}
    end,
  },
  -- 5. EMMET
  {
    "olrtg/nvim-emmet",
    config = function()
      vim.keymap.set({ "n", "v" }, "<leader>xe", require("nvim-emmet").wrap_with_abbreviation)
    end,
  },
  -- 6. BEAUTIFUL UI (COMPACT DIALOGS)
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
      select = {
        backend = { "builtin" }, 
        builtin = {
          relative = "editor",
          max_width = 30,
          min_height = 3,
          border = "rounded",
          mappings = { n = { ["q"] = "Close", ["<Esc>"] = "Close" } },
        },
      },
      input = {
        relative = "editor",
        title_pos = "center",
        start_in_insert = true,
        border = "rounded",
        win_options = { winblend = 0 },
      },
    },
  },
  -- 7. CENTERED COMMAND LINE (NOICE) + WARNING SILENCER
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      -- === ADD THIS BLOCK ===
      lsp = {
        signature = {
          enabled = false, -- This turns off the annoying auto-popup box
        },
        hover = {
          enabled = false, -- Optional: Set to false if you also hate the hover documentation box
        },
      },
      -- ======================
      cmdline = {
        view = "cmdline_popup",
      },
      -- THIS ROUTES BLOCK IS WHAT HIDES THE WARNINGS
      routes = {
        {
          filter = {
            event = "notify",
            find = "deprecated",
          },
          opts = { skip = true },
        },
        {
          filter = {
            event = "notify",
            find = "lspconfig",
          },
          opts = { skip = true },
        },
      },
      views = {
        cmdline_popup = {
          position = {
            row = "75%", 
            col = "75%",
          },
          size = {
            width = "50%",
            height = "auto",
          },
        },
        popupmenu = {
          relative = "editor",
          position = {
            row = "60%",
            col = "50%",
          },
          size = {
            width = 60,
            height = 10,
          },
          border = {
            style = "rounded",
            padding = { 0, 1 },
          },
          win_options = {
            winhighlight = { Normal = "Normal", FloatBorder = "DiagnosticInfo" },
          },
        },
      },
      popupmenu = { enabled = true },
      presets = {
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
    },
  },
  -- 8. SUPERCHARGED GIT (LAZYGIT)
  {
    "kdheepak/lazygit.nvim",
    cmd = { "LazyGit", "LazyGitConfig" },
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>lg", "<cmd>LazyGit<cr>", desc = "LazyGit" }
    },
  },
  {
    "nvim-tree/nvim-tree.lua",
    opts = {
      filters = { dotfiles = false, git_ignored = false },
      sync_root_with_cwd = true,
      respect_buf_cwd = true,
      view = { width = 40, side = "left", preserve_window_proportions = true },
      actions = { open_file = { quit_on_open = false, resize_window = false, window_picker = { enable = false } } },
    },
  },
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require "configs.conform"
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make" } },
    opts = function()
      local conf = require "nvchad.configs.telescope"
      conf.defaults.vimgrep_arguments = {
        "rg",
        "--color=never",
        "--no-heading",
        "--with-filename",
        "--line-number",
        "--column",
        "--smart-case",
        "--hidden",
        "-g",
        "!.git",
        "-g",
        "!node_modules",
        "-g",
        "!Library",
      }
      conf.defaults.initial_mode = "insert"
      conf.pickers = {
        find_files = {
          find_command = {
            "fd",
            "--type",
            "f",
            "--hidden",
            "--strip-cwd-prefix",
            "--exclude",
            ".git",
            "--exclude",
            "node_modules",
            "--exclude",
            "target",
            "--exclude",
            "build",
            "--exclude",
            "Library",
            "--exclude",
            ".Trash",
            "--exclude",
            ".cache",
          },
        },
      }
      return conf
    end,
  },
  {
    "windwp/nvim-ts-autotag",
    ft = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
    config = function()
      require("nvim-ts-autotag").setup()
    end,
  },


  -- === DEBUGGER (DAP) ===
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio", 
      "jay-babu/mason-nvim-dap.nvim",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("dapui").setup()
      require("mason-nvim-dap").setup({
        ensure_installed = { "codelldb", "js-debug-adapter" },
        automatic_installation = true,
      })

      -- Open Debug UI automatically
      dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
      dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
      dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end
      
      -- Keymaps
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
    end,
  },

  -- === BEAUTIFUL TERMINAL (ToggleTerm) ===
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    config = function()
      require("toggleterm").setup({
        size = 20,
        open_mapping = [[<C-\>]], -- Keeps your Control+Backslash
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
          border = "curved",
          winblend = 0,
          highlights = { border = "Normal", background = "Normal" },
        },
      })
    end,
  },
}



