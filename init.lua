vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.autoread = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"

vim.diagnostic.config({
  virtual_text = true,
  signs = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup({
        renderer = {
          icons = {
            show = {
              file = false,
              folder = false,
              folder_arrow = false,
              git = false,
            },
          },
        },
      })
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          require("nvim-tree.api").tree.open()
        end,
      })
    end,
  },

  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "clangd",
          "lua_ls",
          "pyright",
          "ts_ls",
          "gopls",
          "rust_analyzer",
          "bashls",
          "jsonls",
          "yamlls",
        },
        automatic_enable = true,
      })
    end,
  },

  { "neovim/nvim-lspconfig" },

  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-nvim-lsp" },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        sources = { { name = "nvim_lsp" } },
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
        }),
      })
    end,
  },

  { "hrsh7th/cmp-nvim-lsp" },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          hidden = true,
        },
      })
      local builtin = require("telescope.builtin")
      vim.keymap.set("n", "<leader>ff", function()
        builtin.find_files({ hidden = true })
      end, {})
      vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
      vim.keymap.set("n", "<leader>fb", builtin.buffers, {})
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
    end,
  },

  { "nvim-lua/plenary.nvim" },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },

  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "+" },
          change       = { text = "~" },
          delete       = { text = "-" },
          topdelete    = { text = "-" },
          changedelete = { text = "~" },
          untracked    = { text = "?" },
        },
      })
    end,
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf, silent = true }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
    vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
  end,
})
