# abc-lsp.nvim

A Neovim plugin for ABC music notation that provides language server features.

## Features

- Syntax highlighting for ABC notation
- Diagnostics for syntax errors
- Code formatting
- Completions for ABC notation symbols
- Custom commands for rhythm transformation and transposition

## Requirements

- Neovim >= 0.7.0
- Node.js (for running the language server)
- [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig)
- [abc-parser](https://github.com/AntoineBalaine/abc_parse) (installed as a dependency of the server)

## Installation

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'AntoineBalaine/abc-lsp.nvim',
  requires = {
    'neovim/nvim-lspconfig',
  },
  config = function()
    require('abc_lsp').setup()
  end
}
```

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'AntoineBalaine/abc-lsp.nvim',
  dependencies = {
    'neovim/nvim-lspconfig',
  },
  config = function()
    require('abc_lsp').setup()
  end
}
```

## Server Installation

The ABC LSP server needs to be installed separately. You can install it globally:

```bash
# Clone the repository
git clone https://github.com/AntoineBalaine/abc-lsp-server.git
cd abc-lsp-server

# Install dependencies
npm install

# Build the server
npm run compile

# Create a symlink to make it globally available
npm link
```

## Configuration

You can configure the plugin by passing options to the setup function:

```lua
require('abc_lsp').setup({
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
})
```

## Commands

The plugin provides the following commands:

- `:AbcLspStart` - Start the ABC LSP server
- `:AbcLspStop` - Stop the ABC LSP server
- `:AbcLspRestart` - Restart the ABC LSP server

When editing an ABC file, the following buffer-local commands are available:

- `:AbcDivideRhythm` - Divide rhythm in selection
- `:AbcMultiplyRhythm` - Multiply rhythm in selection
- `:AbcTransposeUp` - Transpose selection up an octave
- `:AbcTransposeDown` - Transpose selection down an octave

## Keymaps

If keymaps are enabled, the following default keymaps are available in normal and visual mode:

- `<Leader>ad` - Divide rhythm
- `<Leader>am` - Multiply rhythm
- `<Leader>au` - Transpose up an octave
- `<Leader>ad` - Transpose down an octave

## License

MIT
