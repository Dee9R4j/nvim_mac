require "nvchad.mappings"
local map = vim.keymap.set
local control_center = require("configs.control_center")

control_center.setup()

-- === DIAGNOSTIC UTILS === --
map("n", "<leader>ld", function()
  vim.diagnostic.open_float({ border = "rounded", source = "always", scope = "line" })
end, { desc = "Line Diagnostic (Float)" })

map("n", "<leader>lt", function()
  local current_config = vim.diagnostic.config()
  local new_state = not current_config.virtual_text
  vim.diagnostic.config({ virtual_text = new_state })
  vim.notify("Diagnostics: " .. (new_state and "ON" or "OFF"))
end, { desc = "Toggle Diagnostic Text" })

-- === WINDOW HELPERS === --
local function goto_main_window()
  local wins = vim.api.nvim_list_wins()
  for _, w in ipairs(wins) do
    local buf = vim.api.nvim_win_get_buf(w)
    local ft = vim.bo[buf].filetype
    if ft ~= "NvimTree" then vim.api.nvim_set_current_win(w); return end
  end
  vim.cmd("vsplit")
end

local function focus_current_host_app()
  local app = vim.g.neovide and "Neovide" or "Ghostty"
  os.execute("osascript -e 'tell application \"" .. app .. "\" to activate'")
end


-- === CENTRALIZED SAVE LOGIC (Final: Clean & Silent) === --
local function save_and_run(callback)
  local file = vim.fn.expand("%")
  
  -- Case A: Untitled File -> Trigger AppleScript Dialog
  if file == "" then
    -- We use 'activate' + standard 'choose file name' to avoid permission errors
    local cmd = "osascript -e 'activate' -e 'set theFile to choose file name with prompt \"Save File As...\" default name \"untitled\"' -e 'POSIX path of theFile' 2>&1"
    
    local result = vim.fn.system(cmd)
    
    focus_current_host_app()
    
    -- Check for errors or cancellation
    if vim.v.shell_error ~= 0 then
      if string.find(result, "User canceled") then
        vim.notify("Save Cancelled", vim.log.levels.INFO)
      end
      -- Silent return on error (no debug message)
      return
    end

    -- Clean the result
    local path = result:gsub("[\r\n]", "")
    if path == "" then return end 

    -- Safe Save
    local success, err = pcall(function()
      vim.cmd("saveas " .. vim.fn.fnameescape(path))
    end)

    if success then
      -- Save successful, run callback (close/quit) if provided
      if callback then callback() end
    else
      -- Only show error if the actual file write fails (e.g. disk full)
      vim.notify("Write Error: " .. tostring(err), vim.log.levels.ERROR)
    end

  -- Case B: Existing File -> Just Save
  else
    vim.cmd("w")
    if vim.fn.mode() == 'i' then vim.cmd("stopinsert") end
    if callback then callback() end
  end
end


-- === BEAUTIFUL EXIT LOGIC (Fixed: Single Press 'n') === --
local function ask_to_save(callback)
  vim.cmd("stopinsert")
  local choice = vim.fn.confirm("Save Changes?", "&Yes\n&No\n&Cancel", 1)
  
  if choice == 1 then -- YES
    -- Use the smart save logic (handles untitled files)
    save_and_run(callback)
    
  elseif choice == 2 then -- NO
    -- FIX: Force "modified" to false so the close command works INSTANTLY
    vim.bo.modified = false 
    callback()
  end
end

local function smart_close()
  local buf = vim.api.nvim_get_current_buf()
  local modified = vim.bo[buf].modified
  local bufs = vim.t.bufs or vim.api.nvim_list_bufs()
  
  local function proceed_close()
    local listed_bufs = {}
    for _, b in ipairs(bufs) do
      if vim.bo[b].buflisted then table.insert(listed_bufs, b) end
    end
    if #listed_bufs <= 1 then
        vim.cmd("qa!") 
    else
        require("nvchad.tabufline").close_buffer()
    end
  end

  if modified then
    ask_to_save(proceed_close)
  else
    proceed_close()
  end
end

local function smart_quit_app()
  local modified = false
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].modified then modified = true; break end
  end

  if modified then
    vim.cmd("stopinsert")
    local choice = vim.fn.confirm("Quit App?", "&Yes (Save All)\n&No (Discard)\n&Cancel", 1)
    
    if choice == 1 then -- YES
      -- If current file is untitled, save it first, then Quit All
      if vim.fn.expand("%") == "" then
        save_and_run(function() vim.cmd("wa"); vim.cmd("qa") end)
      else
        vim.cmd("wa")
        vim.cmd("qa")
      end
    elseif choice == 2 then -- NO
      vim.cmd("qa!") -- Force quit everything
    end
  else
    vim.cmd("qa")
  end
end

-- === SMART TERMINAL === --
local function smart_term_exec(cmd_str)
  local osascript = [[
    osascript -e '
      tell application "Terminal"
        if not running then
           activate
           repeat until (count of windows) > 0
               delay 0.1
           end repeat
           do script "]] .. cmd_str .. [[" in window 1
        else
           if (count of windows) is 0 then
              activate
              do script "]] .. cmd_str .. [["
           else
              activate
              try
                 set isBusy to busy of selected tab of front window
              on error
                 set isBusy to false
              end try
              
              if isBusy then
                 do script "]] .. cmd_str .. [["
              else
                 do script "]] .. cmd_str .. [[" in front window
              end if
           end if
        end if
        tell application "System Events" to set frontmost of process "Terminal" to true
      end tell'
  ]]
  os.execute(osascript)
end

-- === CLIPBOARD & PASTE === --
map({ "n", "v", "x" }, "<D-c>", '"+y', { desc = "Copy" })
map("i", "<D-c>", '<Esc>"+yygi', { desc = "Copy Line" })
map("i", "<D-v>", '<C-r><C-p>+', { desc = "Paste (Smart)" })
map({ "n", "v", "x" }, "<D-v>", '"+p', { desc = "Paste" })
map({ "n", "v", "x" }, "<D-x>", '"+d', { desc = "Cut" })
map("i", "<D-x>", '<Esc>"+ddgi', { desc = "Cut Line" })

local function copy_visual_to_mac_clipboard()
  vim.cmd('normal! "zy')
  vim.fn.system("pbcopy", vim.fn.getreg("z"))
end

local function copy_line_to_mac_clipboard()
  vim.fn.system("pbcopy", vim.api.nvim_get_current_line())
end

local function paste_from_mac_clipboard_normal()
  local text = vim.fn.system("pbpaste")
  if vim.v.shell_error ~= 0 or text == "" then return end
  text = text:gsub("\r\n", "\n")
  vim.fn.setreg("z", text)
  vim.cmd('normal! "zp')
end

local function paste_from_mac_clipboard_insert()
  local text = vim.fn.system("pbpaste")
  if vim.v.shell_error ~= 0 or text == "" then return end
  text = text:gsub("\r\n", "\n")
  vim.api.nvim_put(vim.split(text, "\n", { plain = true }), "c", true, true)
end

-- Native terminal equivalents for clipboard actions
map({ "v", "x" }, "<leader>c", copy_visual_to_mac_clipboard, { desc = "Copy" })
map("n", "<leader>c", copy_line_to_mac_clipboard, { desc = "Copy Line" })
map({ "n", "v" }, "<leader>v", paste_from_mac_clipboard_normal, { desc = "Paste" })
map("i", "<leader>v", paste_from_mac_clipboard_insert, { desc = "Paste (Smart)" })

-- === FILE OPS === --
map({ "n", "i", "v" }, "<D-n>", function() goto_main_window(); vim.cmd("enew") end, { desc = "New File" })

-- SMART SAVE (Refactored to use the shared logic)
map({ "n", "i", "v" }, "<D-s>", function() 
  save_and_run()
  focus_current_host_app()
end, { desc = "Smart Save" })

map({ "n", "i", "v" }, "<D-o>", function()
  local cmd = "osascript -e 'tell application \"System Events\"' -e 'activate' -e 'set theFolder to choose folder with prompt \"Select Project\"' -e 'POSIX path of theFolder' -e 'end tell'"
  local handle = io.popen(cmd); local result = handle:read("*a"); handle:close()
  focus_current_host_app()
  if result and result ~= "" then vim.cmd("cd " .. result:gsub("\n", "")); vim.cmd("NvimTreeFocus") end
end, { desc = "Open Project" })

map({ "n", "i", "v" }, "<D-O>", function()
  local cmd = "osascript -e 'tell application \"System Events\"' -e 'activate' -e 'set theFile to choose file with prompt \"Select a File\"' -e 'POSIX path of theFile' -e 'end tell'"
  local handle = io.popen(cmd); local result = handle:read("*a"); handle:close()
  focus_current_host_app()
  if result and result ~= "" then vim.cmd("e " .. result:gsub("\n", "")) end
end, { desc = "Open File" })

-- Native terminal equivalents for GUI openers
map({ "n", "v" }, "<leader>o", function()
  local cmd = "osascript -e 'tell application \"System Events\"' -e 'activate' -e 'set theFolder to choose folder with prompt \"Select Project\"' -e 'POSIX path of theFolder' -e 'end tell'"
  local handle = io.popen(cmd); local result = handle:read("*a"); handle:close()
  focus_current_host_app()
  if result and result ~= "" then vim.cmd("cd " .. result:gsub("\n", "")); vim.cmd("NvimTreeFocus") end
end, { desc = "Open Project (Folder)" })

map({ "n", "v" }, "<leader>O", function()
  local cmd = "osascript -e 'tell application \"System Events\"' -e 'activate' -e 'set theFile to choose file with prompt \"Select a File\"' -e 'POSIX path of theFile' -e 'end tell'"
  local handle = io.popen(cmd); local result = handle:read("*a"); handle:close()
  focus_current_host_app()
  if result and result ~= "" then vim.cmd("e " .. result:gsub("\n", "")) end
end, { desc = "Open File" })

-- BEAUTIFUL CLOSE/QUIT
map({ "n", "i", "v" }, "<D-w>", function() smart_close() end, { desc = "Close File" })
map({ "n", "i", "v" }, "<D-q>", function() smart_quit_app() end, { desc = "Quit App" })

-- === GIT LOGIC === --
map({ "n", "i", "v" }, "<D-g>", "<cmd>LazyGit<cr>", { desc = "Open Git" })

vim.api.nvim_create_autocmd("FileType", {
  pattern = "lazygit",
  callback = function()
    local opts = { buffer = true, silent = true }
    map("t", "<Esc>", "<C-\\><C-n>:q<cr>", opts) 
    map("t", "<D-g>", "<C-\\><C-n>:q<cr>", opts)
    map("n", "q", ":q<cr>", opts)
  end,
})

-- === EDITING === --
map({ "n", "i", "v" }, "<D-z>", "<cmd> u <cr>", { desc = "Undo" })
map("n", "<D-S-z>", "<C-r>", { desc = "Redo" })
map("i", "<D-S-z>", "<C-o><C-r>", { desc = "Redo" })
map("i", "<D-]>", "<C-o>>", { desc = "Indent" })
map("i", "<D-[>", "<C-o><", { desc = "Outdent" })
map("n", "<D-]>", ">>", { desc = "Indent" })
map("n", "<D-[>", "<<", { desc = "Outdent" })
map("v", "<D-]>", ">gv", { desc = "Indent" })
map("v", "<D-[>", "<gv", { desc = "Outdent" })
local function toggle_comment_current_line()
  local ok, api = pcall(require, "Comment.api")
  if ok then api.toggle.linewise.current() end
end

local function toggle_comment_visual()
  local ok, api = pcall(require, "Comment.api")
  if not ok then return end
  local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
  vim.api.nvim_feedkeys(esc, "nx", false)
  api.toggle.linewise(vim.fn.visualmode())
end

map("n", "<D-/>", toggle_comment_current_line, { desc = "Comment/Uncomment Line" })
map("v", "<D-/>", toggle_comment_visual, { desc = "Comment/Uncomment Selection" })
map("i", "<D-/>", function()
  toggle_comment_current_line()
  vim.cmd("startinsert")
end, { desc = "Comment/Uncomment Line" })
map("i", "<S-CR>", "<Esc>A", { desc = "Jump to End" })
map("n", "<S-CR>", "A", { desc = "Jump to End" })
map("v", "<S-CR>", "$", { desc = "Jump to End" })

-- === NAVIGATION & SIDEBAR LOGIC === --
map({ "n", "i", "v" }, "<D-t>", function()
  vim.cmd("wincmd w")
  if vim.bo.filetype == "NvimTree" then vim.cmd("stopinsert") end
end, { desc = "Cycle Windows" })

map({ "n", "v" }, "<leader>t", function()
  vim.cmd("wincmd w")
  if vim.bo.filetype == "NvimTree" then vim.cmd("stopinsert") end
end, { desc = "Cycle Windows" })

map({ "n", "i", "v" }, "<D-k>", function() 
  vim.cmd("stopinsert") 
  vim.cmd("NvimTreeToggle") 
end, { desc = "Toggle Sidebar" })

map({ "n", "v" }, "<leader>k", function()
  vim.cmd("stopinsert")
  vim.cmd("NvimTreeToggle")
end, { desc = "Toggle Sidebar" })

map({ "n", "i", "v" }, "<D-p>", function() goto_main_window(); require("telescope.builtin").find_files() end, { desc = "Find File" })
map({ "n", "i", "v" }, "<D-S-p>", function() control_center.open() end, { desc = "Control Center" })
map({ "n", "i", "v" }, "<D-P>", function() control_center.open() end, { desc = "Control Center" })
map({ "n", "i", "v" }, "<D-F>", function() require("telescope.builtin").live_grep() end, { desc = "Live Grep" })
map({ "n", "i", "v" }, "<D-f>", function() require("telescope.builtin").current_buffer_fuzzy_find() end, { desc = "Find in File" })
map("n", "<D-CR>", vim.lsp.buf.definition, { desc = "Go to Definition" })
map({ "n", "v" }, "<leader>p", function() goto_main_window(); require("telescope.builtin").find_files() end, { desc = "Find File" })
map({ "n", "v" }, "<leader>P", function() control_center.open() end, { desc = "Control Center" })
map({ "n", "v" }, "<leader>F", function() require("telescope.builtin").live_grep() end, { desc = "Global Search" })
map({ "n", "v" }, "<leader>f", function() require("telescope.builtin").current_buffer_fuzzy_find() end, { desc = "Find in File" })
-- map({ "n", "i", "v" }, "<D-a>", "<cmd> normal! ggVG <cr>", { desc = "Select All" })
-- Select All (Fixed for Insert Mode)
map("n", "<D-a>", "ggVG", { desc = "Select All" })
map("i", "<D-a>", "<Esc>ggVG", { desc = "Select All" }) -- Explicit <Esc> fixes the mode switch
map("v", "<D-a>", "<Esc>ggVG", { desc = "Select All" })

-- === SMART RUN COMMANDS === --
map({ "n", "i", "v" }, "<D-j>", function()
  local cwd = vim.fn.getcwd()
  local cmd = "cd " .. vim.fn.shellescape(cwd) .. " && clear"
  smart_term_exec(cmd)
end, { desc = "Smart Terminal" })

map({ "n", "i", "v" }, "<D-b>", function()
  vim.cmd("silent! w")
  local file = vim.g.last_code_file
  if not file or file == "" then file = vim.fn.expand("%:p") end
  local cwd = vim.fn.getcwd()
  local run_script = "~/.config/nvim/run_code.sh " .. vim.fn.shellescape(file)
  local cmd = "cd " .. vim.fn.shellescape(cwd) .. " && clear && " .. run_script
  smart_term_exec(cmd)
end, { desc = "Smart Run Code" })

map({ "n", "v" }, "<leader>rn", function()
  vim.cmd("silent! w")
  local file = vim.g.last_code_file
  if not file or file == "" then file = vim.fn.expand("%:p") end
  local cwd = vim.fn.getcwd()
  local run_script = "~/.config/nvim/run_code.sh " .. vim.fn.shellescape(file)
  local cmd = "cd " .. vim.fn.shellescape(cwd) .. " && clear && " .. run_script
  smart_term_exec(cmd)
end, { desc = "Smart Run Code" })

map({ "n", "i", "v" }, "<C-`>", function()
  local file_dir = vim.fn.expand("%:p:h")
  if file_dir == "" then file_dir = vim.fn.getcwd() end
  local cmd = "cd " .. vim.fn.shellescape(file_dir) .. " && clear"
  smart_term_exec(cmd)
end, { desc = "Terminal at File Dir" })

-- === VS CODE BEHAVIOR & SELECTION DELETE === --
map("v", "<BS>", '"_d', { desc = "Delete Selection" })
map("v", "<Del>", '"_d', { desc = "Delete Selection" })

-- ===============================================
-- ===  NEW: BEAUTIFUL TOGGLETERM INTEGRATION  ===
-- ===============================================
map({ "n", "t" }, "<D-\\>", "<cmd>ToggleTerm direction=float<cr>", { desc = "Toggle Terminal" })
map({ "n", "v" }, "<leader>\\", "<cmd>ToggleTerm direction=float<cr>", { desc = "Toggle Terminal" })

local term_id_counter = 1
map("t", "<D-n>", function()
  term_id_counter = term_id_counter + 1
  vim.cmd(term_id_counter .. "ToggleTerm direction=float")
end, { desc = "New Terminal Instance" })

map("t", "<D-w>", "<cmd>close<cr>", { desc = "Close Terminal" })
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit Terminal Mode" })

map("t", "<D-v>", function()
  local text = vim.fn.getreg('+')
  vim.api.nvim_chan_send(vim.bo.channel, text)
end, { desc = "Paste in Terminal" })

map("t", "<D-s>", "<C-\\><C-n>:w<cr>", { desc = "Smart Save" })
map("t", "<D-a>", "<C-\\><C-n>ggVG", { desc = "Select All" })

-- ==========================================================
-- ===  NATIVE TERMINAL (LEADER) FALLBACKS                ===
-- ==========================================================

map({ "n", "v" }, "<leader>n", function() goto_main_window(); vim.cmd("enew") end, { desc = "New File" })
map({ "n", "v" }, "<leader>s", function()
  save_and_run()
  focus_current_host_app()
end, { desc = "Smart Save" })
map({ "n", "v" }, "<leader>w", function() smart_close() end, { desc = "Close File" })
map({ "n", "v" }, "<leader>q", function() smart_quit_app() end, { desc = "Quit App" })

map({ "n", "v" }, "<leader>j", function()
  local cwd = vim.fn.getcwd()
  local cmd = "cd " .. vim.fn.shellescape(cwd) .. " && clear"
  smart_term_exec(cmd)
end, { desc = "Smart Terminal" })

map({ "n", "v" }, "<leader>g", "<cmd>LazyGit<cr>", { desc = "Open Git" })

map({ "n", "v" }, "<leader>z", "<cmd> u <cr>", { desc = "Undo" })
map({ "n", "v" }, "<leader>Z", "<C-r>", { desc = "Redo" })
map({ "n", "v" }, "<leader>a", "ggVG", { desc = "Select All" })
map("v", "<leader>c", copy_visual_to_mac_clipboard, { desc = "Copy" })
map("n", "<leader>c", copy_line_to_mac_clipboard, { desc = "Copy Line" })
map({ "n", "v" }, "<leader>v", paste_from_mac_clipboard_normal, { desc = "Paste" })
map("v", "<leader>x", '+"d', { desc = "Cut" })
map("n", "<leader>x", '+"dd', { desc = "Cut Line" })
map("n", "<leader>/", toggle_comment_current_line, { desc = "Comment/Uncomment Line" })
map("v", "<leader>/", toggle_comment_visual, { desc = "Comment/Uncomment Selection" })
map("n", "<leader>]", ">>", { desc = "Indent" })
map("n", "<leader>[", "<<", { desc = "Outdent" })
map("v", "<leader>]", ">gv", { desc = "Indent" })
map("v", "<leader>[", "<gv", { desc = "Outdent" })

-- LSP & formatting native terminal shortcuts
map("n", "<leader>cf", function() require("conform").format({ lsp_fallback = true }) end, { desc = "Format Code" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
map("n", "gr", vim.lsp.buf.references, { desc = "Go to References" })
map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
map("n", "gcc", toggle_comment_current_line, { desc = "Comment/Uncomment Line" })
map("v", "gc", toggle_comment_visual, { desc = "Comment/Uncomment Selection" })
