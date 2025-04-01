local M = {}

local abc_cfg = require("abc_lsp.config")
local abc_srvr = require("abc_lsp.server")

-- Setup function to initialize the plugin
--- vim.g.semantic_tokens_enabled = true
function M.setup(opts)
	vim.lsp.set_log_level("debug")
	vim.notify("ABC init", vim.log.levels.INFO)
	-- Merge user options with defaults
	opts = vim.tbl_deep_extend("force", abc_cfg.defaults, opts or {})

	-- Store the configuration
	abc_cfg.options = opts

	-- abc_srvr.start()

	-- Setup autocommands
	M.create_autocommands()
end

-- Create autocommands for the plugin
function M.create_autocommands()
	local augroup = vim.api.nvim_create_augroup("AbcLsp", { clear = true })

	-- Attach to ABC files
	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		pattern = "*.abc",
		callback = function()
			vim.notify("ABC Autocmd", vim.log.levels.INFO)
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
