if vim.g.vscode then return end

local _notify = vim.notify
vim.notify = function(msg, level, opts)
  if type(msg) == "string" and (msg:find("deprecated") or msg:find("lspconfig") or msg:find("stack traceback")) then return end
  _notify(msg, level, opts)
end

vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end
vim.opt.rtp:prepend(lazypath)

local status, lazy_config = pcall(require, "configs.lazy")
if not status then lazy_config = {} end

require("lazy").setup({
  { "NvChad/NvChad", lazy = false, branch = "v2.5", import = "nvchad.plugins" },
  { import = "plugins" },
}, lazy_config)

dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "nvchad.autocmds"
vim.schedule(function() require "mappings" end)

-- FILE TRACKER for Run Code
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local name = vim.api.nvim_buf_get_name(buf)
    local ft = vim.bo[buf].filetype
    local bt = vim.bo[buf].buftype
    if bt == "" and ft ~= "NvimTree" and ft ~= "TelescopePrompt" and name ~= "" then
        vim.g.last_code_file = name
    end
  end
})

-- DISABLE AUTO-COMMENTS
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function() vim.opt_local.formatoptions:remove({ "c", "r", "o" }) end,
})

-- ==========================================================
-- ===  EXTERNAL FILE OPENER (PDF, IMAGES, VIDEOS)        ===
-- ==========================================================
local external_extensions = { 
  "pdf", "png", "jpg", "jpeg", "gif", "webp", 
  "mp4", "mov", "mkv", "avi", "webm", 
  "doc", "docx", "xls", "xlsx", "ppt", "pptx", 
  "svg", "icns", "ico" 
}

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = "*",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local file_path = vim.api.nvim_buf_get_name(buf)
    
    -- Skip execution if there is no file name (e.g. new scratch buffer)
    if file_path == "" then return end

    -- Get the file extension
    local ext = vim.fn.fnamemodify(file_path, ":e"):lower()
    
    -- Check if the extension is in our blocklist
    if vim.tbl_contains(external_extensions, ext) then
      -- 1. Open the file in the default macOS app (asynchronously)
      vim.fn.jobstart({ "open", file_path }, { detach = true })
      
      -- 2. Delete the buffer immediately so it doesn't clutter Neovim
      -- We schedule it to ensure the autocommand finishes first
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.api.nvim_buf_delete(buf, { force = true })
        end
      end)
      
      -- 3. Notify the user
      vim.notify("Opening externally: " .. vim.fn.fnamemodify(file_path, ":t"), vim.log.levels.INFO)
    end
  end,
})

-- Enable Spell Check for Text and Markdown
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    -- vim.opt_local.spell = true
    vim.opt_local.wrap = true
  end,
})
