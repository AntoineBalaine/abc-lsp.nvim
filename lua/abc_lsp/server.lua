local M = {}

local lspconfig = require('lspconfig')
local config = require('abc_lsp.config')

-- Server state
local server_running = false
local server_job_id = nil

-- Check if the server is running
function M.is_running()
  return server_running
end

-- Start the ABC LSP server
function M.start()
  local opts = config.options
  
  -- Check if the server is already running
  if server_running then
    vim.notify('ABC LSP server is already running', vim.log.levels.INFO)
    return
  end
  
  -- Setup the LSP client configuration
  local client_config = {
    cmd = opts.server.cmd,
    root_dir = function(fname)
      return lspconfig.util.find_git_ancestor(fname) or vim.fn.getcwd()
    end,
    settings = opts.server.settings,
    capabilities = vim.tbl_deep_extend(
      'force',
      vim.lsp.protocol.make_client_capabilities(),
      require('cmp_nvim_lsp').default_capabilities(),
      opts.server.capabilities or {}
    ),
    on_attach = function(client, bufnr)
      M.on_attach(client, bufnr)
    end,
    flags = {
      debounce_text_changes = 150,
    },
  }
  
  -- Register the LSP client
  lspconfig.abc_lsp = {
    default_config = client_config,
  }
  
  -- Start the server
  lspconfig.abc_lsp.setup({})
  
  server_running = true
  vim.notify('ABC LSP server started', vim.log.levels.INFO)
end

-- Stop the ABC LSP server
function M.stop()
  if not server_running then
    vim.notify('ABC LSP server is not running', vim.log.levels.INFO)
    return
  end
  
  -- Stop all ABC LSP clients
  for _, client in pairs(vim.lsp.get_active_clients()) do
    if client.name == 'abc_lsp' then
      client.stop()
    end
  end
  
  server_running = false
  vim.notify('ABC LSP server stopped', vim.log.levels.INFO)
end

-- Restart the ABC LSP server
function M.restart()
  M.stop()
  vim.defer_fn(function()
    M.start()
  end, 1000) -- Wait a second before restarting
end

-- Attach the LSP client to a buffer
function M.attach_to_buffer(bufnr)
  bufnr = bufnr or 0
  
  -- Check if the server is running
  if not server_running then
    vim.notify('ABC LSP server is not running. Starting...', vim.log.levels.INFO)
    M.start()
  end
  
  -- Check if the buffer is already attached
  local attached = false
  for _, client in pairs(vim.lsp.get_active_clients({ bufnr = bufnr })) do
    if client.name == 'abc_lsp' then
      attached = true
      break
    end
  end
  
  if not attached then
    -- Attach the buffer to the LSP client
    vim.lsp.buf_attach_client(bufnr, 'abc_lsp')
  end
end

-- LSP on_attach callback
function M.on_attach(client, bufnr)
  local opts = config.options
  
  -- Enable completion
  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
  
  -- Setup buffer-local keymaps
  local function buf_set_keymap(mode, lhs, rhs, opts)
    opts = opts or {}
    opts.buffer = bufnr
    vim.keymap.set(mode, lhs, rhs, opts)
  end
  
  -- Standard LSP keymaps
  buf_set_keymap('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
  buf_set_keymap('n', 'gr', vim.lsp.buf.references, { desc = 'Find references' })
  buf_set_keymap('n', 'K', vim.lsp.buf.hover, { desc = 'Show hover information' })
  buf_set_keymap('n', '<leader>f', vim.lsp.buf.formatting, { desc = 'Format document' })
  
  -- Register custom commands for this buffer
  require('abc_lsp.commands').register_buffer_commands(bufnr)
end

return M
