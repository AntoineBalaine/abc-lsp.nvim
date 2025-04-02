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

	-- Preview configuration
	preview = {
		-- Auto-open preview when opening an ABC file
		auto_open = false,
		-- Port for the preview server
		port = 8088,
		-- Rendering options
		options = {
			responsive = true,
			print = false,
			oneSvgPerLine = false,
			showDebug = false,
			jazzchords = false,
			visualTranspose = 0,
			showTransposedSource = false,
		},
	},

	-- Export configuration
	export = {
		-- Default directory for exports (nil = same as file)
		default_directory = nil,
	},
}

-- Runtime options (will be populated by setup)
abc_cfg.options = {}

return abc_cfg
