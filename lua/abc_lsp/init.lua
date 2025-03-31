local M = {}

local config = require('abc_lsp.config')
local server = require('abc_lsp.server')
local commands = require('abc_lsp.commands')

-- Setup function to initialize the plugin
function M.setup(opts)
  -- Merge user options with defaults
  opts = vim.tbl_deep_extend('force', config.defaults, opts or {})
  
  -- Store the configuration
  config.options = opts
  
  -- Setup autocommands
  M.create_autocommands()
  
  -- Setup commands
  commands.setup()
  
  -- Start the server if auto_start is enabled
  if opts.auto_start then
    server.start()
  end
end

-- Create autocommands for the plugin
function M.create_autocommands()
  local augroup = vim.api.nvim_create_augroup('AbcLsp', { clear = true })
  
  -- Attach to ABC files
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'abc',
    callback = function()
      -- Start the server if not already running
      if not server.is_running() then
        server.start()
      end
      
      -- Attach the LSP client to the buffer
      server.attach_to_buffer(0)
    end,
  })
end

-- Start the ABC LSP server
function M.start_server()
  server.start()
end

-- Stop the ABC LSP server
function M.stop_server()
  server.stop()
end

-- Restart the ABC LSP server
function M.restart_server()
  server.restart()
end

return M
