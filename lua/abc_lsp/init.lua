local M = {}

local abc_cfg = require("abc_lsp.config")
local abc_srvr = require("abc_lsp.server")

-- Setup function to initialize the plugin
function M.setup(opts)
	-- Merge user options with defaults
	opts = vim.tbl_deep_extend("force", abc_cfg.defaults, opts or {})

	-- Store the configuration
	abc_cfg.options = opts

	-- Setup autocommands
	M.create_autocommands()

	abc_srvr.start()
end

-- Create autocommands for the plugin
function M.create_autocommands()
	local augroup = vim.api.nvim_create_augroup("AbcLsp", { clear = true })

	-- Attach to ABC files
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = "abc",
		callback = function()
			-- Start the server if not already running
			if not abc_srvr.is_running() then
				abc_srvr.start()
			end

			-- Attach the LSP client to the buffer
			abc_srvr.attach_to_buffer(0)
		end,
	})
end

-- Start the ABC LSP server
function M.start_server()
	abc_srvr.start()
end

-- Stop the ABC LSP server
function M.stop_server()
	abc_srvr.stop()
end

-- Restart the ABC LSP server
function M.restart_server()
	abc_srvr.restart()
end

return M
