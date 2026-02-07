vim.g.mapleader = " "
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.autoread = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.undofile = true
vim.opt.scrolloff = 8
vim.opt.updatetime = 250
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = "a"

vim.diagnostic.config({
  virtual_text = true,
  signs = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

local augroup = vim.api.nvim_create_augroup("UserAutoGroup", { clear = true })

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  pattern = "*",
  callback = function()
    if vim.tbl_contains({ "markdown", "diff", "gitcommit" }, vim.bo.filetype) then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[silent! keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.hl.on_yank({ timeout = 200 })
  end,
})

do
  local pair_map = {
    [".c"]   = { ".h" },
    [".cpp"] = { ".hpp", ".hxx", ".hh", ".h" },
    [".cxx"] = { ".hxx", ".hpp", ".hh", ".h" },
    [".cc"]  = { ".hh", ".hpp", ".hxx", ".h" },
    [".h"]   = { ".c", ".cpp", ".cxx", ".cc" },
    [".hpp"] = { ".cpp", ".cxx", ".cc" },
    [".hxx"] = { ".cxx", ".cpp", ".cc" },
    [".hh"]  = { ".cc", ".cpp", ".cxx" },
  }

  vim.api.nvim_create_autocmd("BufReadPost", {
    group = augroup,
    pattern = { "*.c", "*.cpp", "*.cxx", "*.cc", "*.h", "*.hpp", "*.hxx", "*.hh" },
    callback = function()
      if vim.fn.winnr("$") ~= 1 then return end
      local path = vim.api.nvim_buf_get_name(0)
      local stem, ext = path:match("^(.+)(%.%w+)$")
      if not stem or not pair_map[ext] then return end
      for _, candidate in ipairs(pair_map[ext]) do
        local pair_path = stem .. candidate
        if vim.uv.fs_stat(pair_path) then
          vim.schedule(function()
            vim.cmd("vsplit " .. vim.fn.fnameescape(pair_path))
            vim.cmd("wincmd h")
          end)
          return
        end
      end
    end,
  })
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)


local rg_base = {
  "rg", "--color=never", "--no-heading", "--with-filename",
  "--line-number", "--column", "--smart-case", "--max-columns=0",
}
local rg_literal = vim.list_extend(vim.list_extend({}, rg_base), { "--fixed-strings" })

require("lazy").setup({
  {
    "AlexvZyl/nordic.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("nordic").setup({})
      vim.cmd.colorscheme("nordic")
    end,
  },

  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      local api = require("nvim-tree.api")
      require("nvim-tree").setup({
        view = { side = "right" },
        renderer = {
          icons = {
            show = { file = false, folder = false, folder_arrow = false, git = false },
          },
        },
        on_attach = function(bufnr)
          api.config.mappings.default_on_attach(bufnr)
          vim.keymap.set("n", "<C-t>", api.tree.toggle, { buffer = bufnr, desc = "Toggle file tree" })
        end,
      })
      vim.keymap.set("n", "<C-t>", api.tree.toggle, { desc = "Toggle file tree" })
    end,
  },

  { "williamboman/mason.nvim", opts = {} },

  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim", "neovim/nvim-lspconfig" },
    opts = {
      ensure_installed = {
        "clangd", "lua_ls", "pyright", "ts_ls",
        -- "gopls",
        "bashls", "jsonls", "yamlls", "marksman",
      },
      automatic_enable = true,
    },
  },

  { "b0o/schemastore.nvim", lazy = true },

  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-nvim-lsp", "neovim/nvim-lspconfig" },
    config = function()
      local cmp = require("cmp")
      cmp.setup({
        sources = { { name = "nvim_lsp" } },
        mapping = cmp.mapping.preset.insert({
          ["<CR>"]  = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping.select_next_item(),
        }),
      })
    end,
  },

  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = { vimgrep_arguments = rg_literal },
      })
      local b = require("telescope.builtin")
      vim.keymap.set("n", "<C-p>", function() b.find_files({ hidden = true }) end, { desc = "Find files" })
      vim.keymap.set("n", "<C-g>", b.live_grep, { desc = "Live grep (literal)" })
      vim.keymap.set("n", "<C-r>", function() b.live_grep({ vimgrep_arguments = rg_base }) end, { desc = "Live grep (regex)" })
      vim.keymap.set("n", "<leader>fb", b.buffers, { desc = "Find buffers" })
      vim.keymap.set("n", "<leader>fh", b.help_tags, { desc = "Find help tags" })
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()
      local wanted = { "cpp", "typescript", "python", "lua", "json", "yaml", "markdown", "markdown_inline" }
      local installed = require("nvim-treesitter").get_installed()
      local missing = vim.tbl_filter(function(l) return not vim.list_contains(installed, l) end, wanted)
      if #missing > 0 then require("nvim-treesitter").install(missing) end
      vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add          = { text = "+" },
        change       = { text = "~" },
        delete       = { text = "-" },
        topdelete    = { text = "-" },
        changedelete = { text = "~" },
        untracked    = { text = "?" },
      },
    },
  },
})

vim.lsp.config("jsonls", {
  settings = {
    json = {
      schemas = require("schemastore").json.schemas(),
      validate = { enable = true },
    },
  },
})

vim.lsp.config("yamlls", {
  settings = {
    yaml = {
      schemaStore = { enable = false, url = "" },
      schemas = require("schemastore").yaml.schemas(),
    },
  },
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = augroup,
  callback = function(args)
    local function map(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = args.buf, silent = true, desc = desc })
    end
    map("gd", vim.lsp.buf.definition, "Go to definition")
    map("K", vim.lsp.buf.hover, "Hover documentation")
    map("gr", vim.lsp.buf.references, "Find references")
    map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("<leader>ca", vim.lsp.buf.code_action, "Code action")
  end,
})
