local abc_srvr = {}

local abc_cfg = require("abc_lsp.config")
local abc_cmds = require("abc_lsp.commands")
abc_srvr.running = false
abc_srvr.client_id = nil

-- Start the ABC LSP server
function abc_srvr.start()
	local opts = abc_cfg.options

	if abc_srvr.server_running then
		return
	end

	abc_srvr.client_id = vim.lsp.start_client({
		name = "abc-lsp",
		cmd = opts.server.cmd,
		capabilities = vim.tbl_deep_extend(
			"force",
			vim.lsp.protocol.make_client_capabilities(),
			require("cmp_nvim_lsp").default_capabilities(),
			opts.server.capabilities or {}
		),
		commands = {
			{ "divide_rhythm", abc_cmds.divide_rhythm },
			{ "multiply_rhythm", abc_cmds.multiply_rhythm },
			{ "transpose_up", abc_cmds.transpose_up },
			{ "transpose_down", abc_cmds.transpose_down },
		},
	})
	-- Setup the LSP client configuration
	abc_srvr.server_running = true
	vim.notify("ABC LSP server started", vim.log.levels.INFO)
end

-- Stop the ABC LSP server
function abc_srvr.stop()
	vim.lsp.get_client_by_id(abc_srvr.client_id).stop()

	abc_srvr.server_running = false
	vim.notify("ABC LSP server stopped", vim.log.levels.INFO)
end

-- Restart the ABC LSP server
function abc_srvr.restart()
	abc_srvr.stop()
	vim.defer_fn(function()
		abc_srvr.start()
	end, 500)
end

---@param bufnr number
function abc_srvr.attach_to_buffer(bufnr)
	bufnr = bufnr

	abc_srvr.start()

	local client_ls = vim.lsp.get_clients({ id = abc_srvr.client_id, bufnr = bufnr })

	if #client_ls < 1 then
		-- Attach the buffer to the LSP client
		vim.lsp.buf_attach_client(bufnr, abc_srvr.client_id)
	end
end

-- LSP on_attach callback
return abc_srvr
