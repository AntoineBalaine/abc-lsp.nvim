---@class AbcServer
local abc_srvr = {}

---@type AbcConfig
local abc_cfg = require("abc_lsp.config")
---@type AbcCommands
local abc_cmds = require("abc_lsp.commands")

---@type boolean
abc_srvr.server_running = false
---@type number|nil
abc_srvr.client_id = nil

--- Get the client ID
---@return number|nil Client ID
function abc_srvr.get_client_id()
	return abc_srvr.client_id
end

--- Start the ABC LSP server
function abc_srvr.start()
	local opts = abc_cfg.options

	if abc_srvr.is_running() then
		-- return
	end

	-- Check if LSP path is provided
	if not opts.lsp_path then
		vim.notify(
			"ABC language server path not provided. Please set path in your configuration.",
			vim.log.levels.ERROR
		)
		return
	end

	opts.server.cmd = {
		"node",
		opts.lsp_path,
		"--stdio",
	}

	-- Build capabilities
	local capabilities = vim.lsp.protocol.make_client_capabilities()

	if opts.server.capabilities then
		capabilities = vim.tbl_deep_extend("force", capabilities, opts.server.capabilities)
	end

	capabilities.textDocument.semanticTokens = {
		dynamicRegistration = false,
		tokenTypes = {
			"namespace",
			"type",
			"class",
			"enum",
			"interface",
			"struct",
			"typeParameter",
			"parameter",
			"variable",
			"property",
			"enumMember",
			"event",
			"function",
			"method",
			"macro",
			"keyword",
			"modifier",
			"comment",
			"string",
			"number",
			"regexp",
			"operator",
			"decorator",
		},
		tokenModifiers = {}, -- Empty array matching your implementation
		requests = {
			range = false,
			full = true,
		},
		formats = {},
	}

	capabilities.textDocument.formatting.dynamicRegistration = true

	-- Try to start the server
	local client_id = vim.lsp.start_client({
		name = "abc-lsp",
		cmd = opts.server.cmd,
		capabilities = capabilities,
		settings = opts.server.settings or {},
		on_attach = function(_, bufnr)
			abc_cmds.register_buffer_commands(bufnr)
		end,
	})

	if client_id then
		abc_srvr.client_id = client_id
		abc_srvr.server_running = true
		vim.notify("ABC LSP server started", vim.log.levels.INFO)
	else
		vim.notify("Failed to start ABC LSP server", vim.log.levels.ERROR)
	end
end

--- Stop the ABC LSP server
function abc_srvr.stop()
	vim.lsp.get_client_by_id(abc_srvr.client_id).stop()

	abc_srvr.server_running = false
	vim.notify("ABC LSP server stopped", vim.log.levels.INFO)
end

--- Restart the ABC LSP server
function abc_srvr.restart()
	abc_srvr.stop()
	vim.defer_fn(function()
		abc_srvr.start()
	end, 500)
end

--- Attach to a buffer
---@param bufnr number Buffer number
function abc_srvr.attach_to_buffer(bufnr)
	bufnr = bufnr

	abc_srvr.start()

	local client_ls = vim.lsp.get_clients({ id = abc_srvr.client_id, bufnr = bufnr })

	if #client_ls < 1 then
		-- Attach the buffer to the LSP client
		vim.lsp.buf_attach_client(bufnr, abc_srvr.client_id)
	end
end

--- Check if the server is running
---@return boolean Whether the server is running
function abc_srvr.is_running()
	return abc_srvr.server_running == true
end

-- LSP on_attach callback
return abc_srvr
