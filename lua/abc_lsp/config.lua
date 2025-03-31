local M = {}

-- Default configuration options
M.defaults = {
  -- Server configuration
  server = {
    -- Path to the ABC LSP server executable
    cmd = { 'node', vim.fn.expand('~/.local/share/nvim/abc-lsp-server/out/server.js') },
    -- Server settings
    settings = {},
    -- Additional server capabilities
    capabilities = {},
  },
  
  -- Auto-start the server when opening an ABC file
  auto_start = true,
  
  -- Highlighting configuration
  highlighting = {
    -- Enable semantic token highlighting
    enable = true,
  },
  
  -- Keymaps for ABC-specific commands
  keymaps = {
    -- Enable keymaps
    enabled = true,
    -- Rhythm transformation
    divide_rhythm = '<Leader>ad',
    multiply_rhythm = '<Leader>am',
    -- Transposition
    transpose_up = '<Leader>au',
    transpose_down = '<Leader>ad',
  },
}

-- Runtime options (will be populated by setup)
M.options = {}

return M
