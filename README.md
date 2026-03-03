# Neovim Keymaps (Human-Readable)

This file documents all explicit keymaps currently defined in this config.

## Notation

- `Cmd` = macOS Command key
- `Ctrl` = Control key
- `Shift` = Shift key
- `Space` = your leader key
- Modes: `n` = normal, `i` = insert, `v` = visual, `x` = visual-block/select, `t` = terminal

## Scope

- `lua/mappings.lua`
- `lua/plugins/init.lua`

> Note: `require "nvchad.mappings"` also loads NvChad defaults. This README lists your explicit custom/plugin mappings here.

---

## `lua/mappings.lua`

### Diagnostic

- `[n] Space + l d` — Line Diagnostic (Float)
- `[n] Space + l t` — Toggle Diagnostic Text

### Clipboard / Copy / Paste / Cut

- `Copy` — Cmd: `[n,v,x] Cmd + c` | Space: `[v,x] Space + c`
- `Copy Line` — Cmd: `[i] Cmd + c` | Space: `[n] Space + c`
- `Paste (Smart)` — Cmd: `[i] Cmd + v` | Space: `[i] Space + v`
- `Paste` — Cmd: `[n,v,x] Cmd + v` | Space: `[n,v] Space + v`
- `Cut` — Cmd: `[n,v,x] Cmd + x` | Space: `[v] Space + x`
- `Cut Line` — Cmd: `[i] Cmd + x` | Space: `[n] Space + x`

### File Ops / App Ops

- `New File` — Cmd: `[n,i,v] Cmd + n` | Space: `[n,v] Space + n`
- `Smart Save` — Cmd: `[n,i,v] Cmd + s` | Space: `[n,v] Space + s`
- `Open Project (Folder)` — Cmd: `[n,i,v] Cmd + o` | Space: `[n,v] Space + o`
- `Open File` — Cmd: `[n,i,v] Cmd + Shift + o` | Space: `[n,v] Space + Shift + o`
- `Close File` — Cmd: `[n,i,v] Cmd + w` | Space: `[n,v] Space + w`
- `Quit App` — Cmd: `[n,i,v] Cmd + q` | Space: `[n,v] Space + q`

### Git

- `Open Git (LazyGit)` — Cmd: `[n,i,v] Cmd + g` | Space: `[n,v] Space + g`

### LazyGit Buffer-local (autocmd `FileType=lazygit`)

- `[t] Esc` — Exit terminal mode and close lazygit
- `[t] Cmd + g` — Exit terminal mode and close lazygit
- `[n] q` — Close lazygit window

### Editing / Text Manipulation

- `Undo` — Cmd: `[n,i,v] Cmd + z` | Space: `[n,v] Space + z`
- `Redo` — Cmd: `[n,i] Cmd + Shift + z` | Space: `[n,v] Space + Shift + z`
- `Indent` — Cmd: `[i,n,v] Cmd + ]` | Space: `[n,v] Space + ]`
- `Outdent` — Cmd: `[i,n,v] Cmd + [` | Space: `[n,v] Space + [`
- `Comment` — Cmd: `[n,v,i] Cmd + /` | Space: `[n,v] Space + /`
- `[i] Shift + Enter` — Jump to End
- `[n] Shift + Enter` — Jump to End
- `[v] Shift + Enter` — Jump to End
- `Select All` — Cmd: `[n,i,v] Cmd + a` | Space: `[n,v] Space + a`
- `[n] g c c` — Comment/Uncomment Line
- `[v] g c` — Comment/Uncomment Selection

### Navigation / Sidebar / Search

- `Cycle Windows` — Cmd: `[n,i,v] Cmd + t` | Space: `[n,v] Space + t`
- `Toggle Sidebar` — Cmd: `[n,i,v] Cmd + k` | Space: `[n,v] Space + k`
- `Find File` — Cmd: `[n,i,v] Cmd + p` | Space: `[n,v] Space + p`
- `Global Search (Live Grep)` — Cmd: `[n,i,v] Cmd + Shift + f` | Space: `[n,v] Space + Shift + f`
- `Find in File` — Cmd: `[n,i,v] Cmd + f` | Space: `[n,v] Space + f`
- `[n] Cmd + Enter` — Go to Definition

### Select All

- Covered above in `Editing / Text Manipulation` as a dual shortcut entry.

### Smart Terminal / Run

- `Smart Terminal` — Cmd: `[n,i,v] Cmd + j` | Space: `[n,v] Space + j`
- `Smart Run Code` — Cmd: `[n,i,v] Cmd + b` | Space: `[n,v] Space + rn`
- `[n,i,v] Ctrl + backtick` — Terminal at File Dir

### Delete Selection

- `[v] Backspace` — Delete Selection (black hole register)
- `[v] Delete` — Delete Selection (black hole register)

### ToggleTerm / Terminal-mode Maps

- `Toggle Terminal` — Cmd: `[n,t] Cmd + \` | Space: `[n,v] Space + \\`
- `[t] Cmd + n` — New Terminal Instance
- `[t] Cmd + w` — Close Terminal
- `[t] Esc` — Exit Terminal Mode
- `[t] Cmd + v` — Paste in Terminal
- `[t] Cmd + s` — Smart Save
- `[t] Cmd + a` — Select All

### LSP / Formatting

- `[n] Space + c f` — Format Code (`conform` with LSP fallback)
- `[n] g d` — Go to Definition
- `[n] g r` — Go to References
- `[n] g i` — Go to Implementation

---

## `lua/plugins/init.lua`

### Emmet

- `[n,v] Space + x e` — Wrap with abbreviation (`nvim-emmet`)

### LazyGit Plugin Keys

- `[n] Space + l g` — `:LazyGit`

### DAP

- `[n] F5` — Debug: Start/Continue
- `[n] F10` — Debug: Step Over
- `[n] F11` — Debug: Step Into
- `[n] F12` — Debug: Step Out
- `[n] Space + b` — Debug: Toggle Breakpoint

### ToggleTerm Plugin Setting

- `open_mapping = Ctrl + \` — plugin-level open mapping in ToggleTerm config

---
