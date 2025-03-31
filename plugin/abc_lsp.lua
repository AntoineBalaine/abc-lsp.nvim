-- Plugin registration for abc-lsp.nvim

-- Check if Neovim version is compatible
if vim.fn.has('nvim-0.7.0') == 0 then
  vim.notify('abc-lsp.nvim requires Neovim >= 0.7.0', vim.log.levels.ERROR)
  return
end

-- Prevent loading the plugin multiple times
if vim.g.loaded_abc_lsp == 1 then
  return
end
vim.g.loaded_abc_lsp = 1

-- Register filetype detection for ABC files
vim.filetype.add({
  extension = {
    abc = 'abc',
  },
})

-- Create user commands for the plugin
vim.api.nvim_create_user_command('AbcLspSetup', function(opts)
  require('abc_lsp').setup(opts.args ~= '' and loadstring('return ' .. opts.args)() or {})
end, {
  desc = 'Setup ABC LSP with optional configuration',
  nargs = '?',
  complete = function()
    return { '{' }
  end,
})
