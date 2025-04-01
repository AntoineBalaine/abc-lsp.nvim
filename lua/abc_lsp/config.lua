local abc_cfg = {}

-- Default configuration options
abc_cfg.defaults = {
	-- Server configuration
	server = {
		-- Path to the ABC LSP server executable (must be provided by user)
		cmd = nil,
		-- Server settings
		settings = {},
		-- Additional server capabilities
		capabilities = {},
	},
}

-- Runtime options (will be populated by setup)
abc_cfg.options = {}

return abc_cfg
