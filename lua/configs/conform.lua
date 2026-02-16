local options = {
  formatters_by_ft = {
    python = { "black" },
    rust = { "rustfmt" },
    javascript = { "prettier" },
    typescript = { "prettier" },
    javascriptreact = { "prettier" },
    typescriptreact = { "prettier" },
    c = { "clang-format" },
    cpp = { "clang-format" },
    java = { "google-java-format" },
    lua = { "stylua" },
    markdown = { "prettier" },
    text = { "prettier" },
  },
  -- Strict formatting on save
  format_on_save = {
    timeout_ms = 1000, -- Increased slightly for heavy Java/Rust files
    lsp_fallback = true,
  },
}
return require("conform").setup(options)
