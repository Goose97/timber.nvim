local plenary_dir = os.getenv("PLENARY_DIR") or "/tmp/plenary.nvim"

if vim.fn.isdirectory(plenary_dir) == 0 then
  vim.fn.system({ "git", "clone", "https://github.com/nvim-lua/plenary.nvim", plenary_dir })
end

local nvim_treesitter_dir = "/tmp/nvim-treesitter"
if vim.fn.isdirectory(nvim_treesitter_dir) == 0 then
  vim.fn.system({ "git", "clone", "https://github.com/nvim-treesitter/nvim-treesitter.git", nvim_treesitter_dir })
end

vim.opt.rtp:append(".")
vim.opt.rtp:append(plenary_dir)
vim.opt.rtp:append(nvim_treesitter_dir)

vim.cmd("runtime plugin/plenary.vim")
require("plenary.busted")

require("nvim-treesitter.configs").setup({
  ensure_installed = { "javascript", "typescript", "tsx" },
  sync_install = true,
  auto_install = false,
  indent = { enable = true },
})
