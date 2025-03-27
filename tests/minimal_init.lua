local function install_dep(dir, path)
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.system({ "git", "clone", path, dir })
  end
  vim.opt.rtp:append(dir)
end

vim.opt.rtp:append(".")
install_dep("./vendor/plenary.nvim", "https://github.com/nvim-lua/plenary.nvim.git")
install_dep("./vendor/nvim-treesitter", "https://github.com/nvim-treesitter/nvim-treesitter.git")
install_dep("./vendor/telescope.nvim", "https://github.com/nvim-telescope/telescope.nvim.git")

-- Setup grepprg for global clear and comment tests
vim.o.grepprg = "grep --line-number --with-filename -R --exclude-dir=.git"
vim.o.grepformat = "%f:%l:%m"

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")

require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "javascript",
    "typescript",
    "astro",
    "tsx",
    "lua",
    "luau",
    "ruby",
    "elixir",
    "go",
    "rust",
    "python",
    "c",
    "cpp",
    "java",
    "c_sharp",
    "odin",
    "bash",
    "swift",
    "kotlin",
  },
  sync_install = true,
  auto_install = false,
  indent = { enable = true },
  modules = {},
  ignore_install = {},
})
