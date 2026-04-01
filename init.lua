if vim.g.vscode then return end

local _notify = vim.notify
vim.notify = function(msg, level, opts)
  if type(msg) == "string" and (msg:find("deprecated") or msg:find("lspconfig") or msg:find("stack traceback")) then return end
  _notify(msg, level, opts)
end

vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

local uv = vim.uv or vim.loop

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not uv.fs_stat(lazypath) then
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

local function safe_dofile(path)
  if not uv.fs_stat(path) then return false end

  local ok, err = pcall(dofile, path)
  if not ok then
    vim.notify("Failed loading cache file: " .. path .. "\n" .. tostring(err), vim.log.levels.WARN)
    return false
  end

  return true
end

safe_dofile(vim.g.base46_cache .. "defaults")
safe_dofile(vim.g.base46_cache .. "statusline")

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

local external_extension_set = {}
for _, ext in ipairs(external_extensions) do
  external_extension_set[ext] = true
end

local function restore_non_external_buffer(target_win, opened_buf)
  if not vim.api.nvim_win_is_valid(target_win) then return end

  local function is_usable(buf)
    if buf == opened_buf or not vim.api.nvim_buf_is_valid(buf) then return false end
    if vim.bo[buf].buftype ~= "" then return false end
    local buf_name = vim.api.nvim_buf_get_name(buf)
    if buf_name == "" then return true end
    local buf_ext = vim.fn.fnamemodify(buf_name, ":e"):lower()
    return not external_extension_set[buf_ext]
  end

  local alternate = vim.fn.bufnr("#")
  if is_usable(alternate) then
    vim.api.nvim_win_set_buf(target_win, alternate)
    return
  end

  for _, info in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if is_usable(info.bufnr) then
      vim.api.nvim_win_set_buf(target_win, info.bufnr)
      return
    end
  end

  vim.api.nvim_win_call(target_win, function() vim.cmd("enew") end)
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = "*",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local file_path = vim.api.nvim_buf_get_name(buf)
    local bt = vim.bo[buf].buftype
    
    -- Skip execution if there is no file name (e.g. new scratch buffer)
    if file_path == "" then return end
    if bt ~= "" then return end

    -- Get the file extension
    local ext = vim.fn.fnamemodify(file_path, ":e"):lower()
    
    -- Check if the extension is in our blocklist
    if external_extension_set[ext] then
      -- 1. Open the file in the default macOS app (asynchronously)
      vim.fn.jobstart({ "open", file_path }, { detach = true })
      
      -- 2. Restore a normal editing buffer so window proportions stay stable.
      -- We schedule to let the current file-open flow complete first.
      vim.schedule(function()
        if vim.api.nvim_win_is_valid(win) then
          restore_non_external_buffer(win, buf)
        end

        if vim.api.nvim_buf_is_valid(buf) then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
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
