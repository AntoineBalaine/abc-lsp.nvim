local M = {}

local config = require('abc_lsp.config')

-- Setup plugin commands
function M.setup()
  -- Create Neovim commands
  vim.api.nvim_create_user_command('AbcLspStart', function()
    require('abc_lsp').start_server()
  end, { desc = 'Start ABC LSP server' })
  
  vim.api.nvim_create_user_command('AbcLspStop', function()
    require('abc_lsp').stop_server()
  end, { desc = 'Stop ABC LSP server' })
  
  vim.api.nvim_create_user_command('AbcLspRestart', function()
    require('abc_lsp').restart_server()
  end, { desc = 'Restart ABC LSP server' })
end

-- Register buffer-specific commands
function M.register_buffer_commands(bufnr)
  local opts = config.options
  
  -- Create buffer-local commands
  vim.api.nvim_buf_create_user_command(bufnr, 'AbcDivideRhythm', function()
    M.divide_rhythm()
  end, { desc = 'Divide rhythm in selection' })
  
  vim.api.nvim_buf_create_user_command(bufnr, 'AbcMultiplyRhythm', function()
    M.multiply_rhythm()
  end, { desc = 'Multiply rhythm in selection' })
  
  vim.api.nvim_buf_create_user_command(bufnr, 'AbcTransposeUp', function()
    M.transpose_up()
  end, { desc = 'Transpose selection up an octave' })
  
  vim.api.nvim_buf_create_user_command(bufnr, 'AbcTransposeDown', function()
    M.transpose_down()
  end, { desc = 'Transpose selection down an octave' })
  
  -- Setup keymaps if configured
  if opts.keymaps.enabled then
    -- Setup buffer-local keymaps for custom commands
    local function buf_set_keymap(mode, lhs, rhs, opts)
      opts = opts or {}
      opts.buffer = bufnr
      vim.keymap.set(mode, lhs, rhs, opts)
    end
    
    -- Rhythm transformation commands
    if opts.keymaps.divide_rhythm then
      -- Normal mode
      buf_set_keymap('n', opts.keymaps.divide_rhythm, function()
        M.divide_rhythm()
      end, { desc = 'Divide rhythm' })
      
      -- Visual mode
      buf_set_keymap('v', opts.keymaps.divide_rhythm, function()
        M.divide_rhythm()
      end, { desc = 'Divide rhythm in selection' })
    end
    
    if opts.keymaps.multiply_rhythm then
      -- Normal mode
      buf_set_keymap('n', opts.keymaps.multiply_rhythm, function()
        M.multiply_rhythm()
      end, { desc = 'Multiply rhythm' })
      
      -- Visual mode
      buf_set_keymap('v', opts.keymaps.multiply_rhythm, function()
        M.multiply_rhythm()
      end, { desc = 'Multiply rhythm in selection' })
    end
    
    -- Transposition commands
    if opts.keymaps.transpose_up then
      -- Normal mode
      buf_set_keymap('n', opts.keymaps.transpose_up, function()
        M.transpose_up()
      end, { desc = 'Transpose up an octave' })
      
      -- Visual mode
      buf_set_keymap('v', opts.keymaps.transpose_up, function()
        M.transpose_up()
      end, { desc = 'Transpose selection up an octave' })
    end
    
    if opts.keymaps.transpose_down then
      -- Normal mode
      buf_set_keymap('n', opts.keymaps.transpose_down, function()
        M.transpose_down()
      end, { desc = 'Transpose down an octave' })
      
      -- Visual mode
      buf_set_keymap('v', opts.keymaps.transpose_down, function()
        M.transpose_down()
      end, { desc = 'Transpose selection down an octave' })
    end
  end
end

-- Helper function to get the current selection
local function get_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  
  return {
    start = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
    end = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
    -- For LSP compatibility
    active = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
    anchor = { line = start_pos[2] - 1, character = start_pos[3] - 1 }
  }
end

-- Helper function to apply text edits
local function apply_text_edits(text_edits)
  if not text_edits or #text_edits == 0 then
    return
  end
  
  vim.lsp.util.apply_text_edits(text_edits, 0, "utf-8")
end

-- Divide rhythm in selection
function M.divide_rhythm()
  local bufnr = vim.api.nvim_get_current_buf()
  local uri = vim.uri_from_bufnr(bufnr)
  local selection = get_selection()
  
  -- Send request to the server
  vim.lsp.buf_request(
    bufnr,
    'divideRhythm',
    { uri = uri, selection = selection },
    function(err, result, _, _)
      if err then
        vim.notify('Error dividing rhythm: ' .. err.message, vim.log.levels.ERROR)
        return
      end
      
      apply_text_edits(result)
    end
  )
end

-- Multiply rhythm in selection
function M.multiply_rhythm()
  local bufnr = vim.api.nvim_get_current_buf()
  local uri = vim.uri_from_bufnr(bufnr)
  local selection = get_selection()
  
  -- Send request to the server
  vim.lsp.buf_request(
    bufnr,
    'multiplyRhythm',
    { uri = uri, selection = selection },
    function(err, result, _, _)
      if err then
        vim.notify('Error multiplying rhythm: ' .. err.message, vim.log.levels.ERROR)
        return
      end
      
      apply_text_edits(result)
    end
  )
end

-- Transpose up an octave
function M.transpose_up()
  local bufnr = vim.api.nvim_get_current_buf()
  local uri = vim.uri_from_bufnr(bufnr)
  local selection = get_selection()
  
  -- Send request to the server
  vim.lsp.buf_request(
    bufnr,
    'transposeUp',
    { uri = uri, selection = selection },
    function(err, result, _, _)
      if err then
        vim.notify('Error transposing up: ' .. err.message, vim.log.levels.ERROR)
        return
      end
      
      apply_text_edits(result)
    end
  )
end

-- Transpose down an octave
function M.transpose_down()
  local bufnr = vim.api.nvim_get_current_buf()
  local uri = vim.uri_from_bufnr(bufnr)
  local selection = get_selection()
  
  -- Send request to the server
  vim.lsp.buf_request(
    bufnr,
    'transposeDn',
    { uri = uri, selection = selection },
    function(err, result, _, _)
      if err then
        vim.notify('Error transposing down: ' .. err.message, vim.log.levels.ERROR)
        return
      end
      
      apply_text_edits(result)
    end
  )
end

return M
