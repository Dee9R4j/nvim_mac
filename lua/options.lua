require "nvchad.options"
local o = vim.o

o.relativenumber = true
o.number = true
o.signcolumn = "yes"
o.wrap = true
o.linebreak = true

-- 1. FORCE DIAGNOSTICS OFF (The "Double Lock")
-- Step A: Set global default
vim.diagnostic.config({
  virtual_text = false, -- STRICTLY OFF
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})

-- Step B: The Watchdog (Prevents LSP from turning it back on)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.diagnostic.config({ virtual_text = false })
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client and client.server_capabilities.inlayHintProvider then
      vim.lsp.inlay_hint.enable(true, { bufnr = args.buf })
    end
  end,
})

-- 2. SMART AUTO-SAVE
vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
  pattern = "*",
  command = "silent! wall",
  nested = true,
})

-- 3. SIDEBAR MODE GUARD
vim.api.nvim_create_autocmd("FileType", {
  pattern = "NvimTree",
  callback = function()
    vim.cmd("stopinsert")
  end,
})

-- 4. BASICS
o.backspace = "indent,eol,start"


-- 5. FORCE PITCH BLACK BACKGROUND & DARK GREY SIDEBAR
-- This ensures the background stays black even if you switch themes (space + t + h)
vim.api.nvim_create_autocmd({ "UIEnter", "ColorScheme" }, {
  pattern = "*",
  callback = function()
    local pitch_black = "#000000"
    local dark_grey = "#111111" -- Adjust this if you want it lighter/darker

    -- A. Main Coding Area (Pitch Black)
    vim.api.nvim_set_hl(0, "Normal", { bg = pitch_black })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = pitch_black }) -- Non-focused windows
    vim.api.nvim_set_hl(0, "SignColumn", { bg = pitch_black }) -- Gutter (line numbers)
    
    -- B. Sidebar / NvimTree (Dark Grey)
    vim.api.nvim_set_hl(0, "NvimTreeNormal", { bg = dark_grey })
    vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { bg = dark_grey })
    vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { fg = dark_grey, bg = pitch_black }) 
    vim.api.nvim_set_hl(0, "NvimTreeEndOfBuffer", { fg = dark_grey, bg = dark_grey }) -- Hides tildes ~
  end,
})

-- =============================================
-- ===  NEW: NATIVE TERMINAL OPTIONS         ===
-- =============================================

-- 6. TERMINAL AUTO-INSERT
-- When you 'Tab' into a terminal buffer, automatically switch to Insert Mode
vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter", "TermOpen" }, {
  pattern = "term://*",
  command = "startinsert",
})

-- 7. TERMINAL CLEANUP (No Line Numbers)
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "*",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})


-- For making my neovide look good

-- Transparency (0.0 to 1.0)
-- 0.8 is a good sweet spot; 1.0 is opaque.
vim.g.neovide_opacity = 0.9

-- Enable macOS "Blur" (Frosted Glass effect)
-- This makes the transparency look premium instead of just "see-through"
vim.g.neovide_window_blurred = true
