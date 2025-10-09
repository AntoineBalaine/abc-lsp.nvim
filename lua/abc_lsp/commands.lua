---@class AbcCommands
local abc_cmds = {}

--- Helper function to apply text edits
---@param text_edits table[] Array of text edits
---@param bufnr number|nil Buffer number
local function apply_text_edits(text_edits, bufnr)
	if not text_edits or #text_edits == 0 then
		return
	end

	bufnr = bufnr or vim.api.nvim_get_current_buf()
	vim.lsp.util.apply_text_edits(text_edits, bufnr, "utf-8")
end

--- Get the current selection or cursor position
---@return table Selection object with start, end, active, and anchor positions
local function get_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	-- If both marks are set and valid (line > 0)
	if start_pos[2] > 0 and end_pos[2] > 0 then
		-- Visual selection exists, use it
		return {
			start = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
			["end"] = { line = end_pos[2] - 1, character = end_pos[3] },
			-- For LSP compatibility
			active = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
			anchor = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
		}
	else
		-- No visual selection, use cursor position
		local cursor_pos = vim.fn.getpos(".")
		local line = cursor_pos[2] - 1
		local col = cursor_pos[3] - 1

		-- Get the character under the cursor
		local line_text = vim.api.nvim_buf_get_lines(0, line, line + 1, false)[1] or ""
		local char_end = col
		if col < #line_text then
			char_end = col + 1
		end

		return {
			start = { line = line, character = col },
			["end"] = { line = line, character = char_end },
			-- For LSP compatibility
			active = { line = line, character = char_end },
			anchor = { line = line, character = col },
		}
	end
end

--- Helper function to execute an ABC LSP command with range support
---@param method string LSP method name
---@param error_msg string Error message prefix
---@param success_msg string Success message
local function execute_abc_command(method, error_msg, success_msg)
	local bufnr = vim.api.nvim_get_current_buf()
	local abc_srvr = require("abc_lsp.server")
	local client = vim.lsp.get_client_by_id(abc_srvr.client_id)

	if not client then
		vim.notify("ABC LSP server not attached to current buffer", vim.log.levels.ERROR)
		return
	end

	-- Get selection based on cursor position or visual selection
	local selection = get_selection()

	local uri = vim.uri_from_bufnr(bufnr)

	-- Parameters for the custom request
	local params = {
		uri = uri,
		selection = selection,
	}

	-- Make the LSP request
	client.request(method, params, function(err, result, _, _)
		if err then
			vim.notify(error_msg .. err.message, vim.log.levels.ERROR)
			return
		end

		-- Apply the text edits returned by the server
		if result then
			apply_text_edits(result, bufnr)
			vim.notify(success_msg, vim.log.levels.INFO)
		end
	end, bufnr)
end

--- Define all subcommands
local subcommands = {
	rhythm_divide = {
		impl = function()
			execute_abc_command("divideRhythm", "Error dividing rhythm: ", "Rhythm divided successfully")
		end,
		desc = "Divide rhythm in selection"
	},
	rhythm_multiply = {
		impl = function()
			execute_abc_command("multiplyRhythm", "Error multiplying rhythm: ", "Rhythm multiplied successfully")
		end,
		desc = "Multiply rhythm in selection"
	},
	transpose_up = {
		impl = function()
			execute_abc_command("transposeUp", "Error transposing up: ", "Transposed up successfully")
		end,
		desc = "Transpose selection up an octave"
	},
	transpose_down = {
		impl = function()
			execute_abc_command("transposeDn", "Error transposing down: ", "Transposed down successfully")
		end,
		desc = "Transpose selection down an octave"
	},
	preview_open = {
		impl = function()
			require("abc_lsp.preview").open_preview()
		end,
		desc = "Open ABC preview in browser"
	},
	preview_url = {
		impl = function()
			local preview = require("abc_lsp.preview")
			local url = preview.get_preview_url()
			if url then
				vim.notify("Preview URL: " .. url, vim.log.levels.INFO)
				-- Also copy to clipboard if available
				if vim.fn.has("clipboard") == 1 then
					vim.fn.setreg("+", url)
					vim.notify("URL copied to clipboard", vim.log.levels.INFO)
				end
			else
				vim.notify("No preview opened for this buffer. Use :Abc preview_open first.", vim.log.levels.WARN)
			end
		end,
		desc = "Show and copy preview URL to clipboard"
	},
	preview_reopen = {
		impl = function()
			require("abc_lsp.preview").reopen_preview()
		end,
		desc = "Reopen preview in browser"
	},
	preview_stop = {
		impl = function()
			require("abc_lsp.preview").stop_server()
		end,
		desc = "Stop preview server"
	},
	export_html = {
		impl = function()
			require("abc_lsp.export").export_html()
		end,
		desc = "Export ABC as HTML"
	},
	export_svg = {
		impl = function()
			require("abc_lsp.export").export_svg()
		end,
		desc = "Export ABC as SVG"
	},
	print_preview = {
		impl = function()
			require("abc_lsp.export").print_preview()
		end,
		desc = "Open ABC print preview"
	},
	install = {
		impl = function()
			require("abc_lsp").install()
		end,
		desc = "Install/rebuild ABC preview server"
	},
	server_start = {
		impl = function()
			require("abc_lsp").start_server()
		end,
		desc = "Start ABC LSP server"
	},
	server_stop = {
		impl = function()
			require("abc_lsp").stop_server()
		end,
		desc = "Stop ABC LSP server"
	},
	server_restart = {
		impl = function()
			require("abc_lsp").restart_server()
		end,
		desc = "Restart ABC LSP server"
	},
}

--- Show help for all available subcommands
local function show_help()
	local lines = { "Available ABC commands:" }

	-- Group commands by category
	local groups = {
		{ title = "Rhythm & Transposition:", commands = { "rhythm_divide", "rhythm_multiply", "transpose_up", "transpose_down" } },
		{ title = "Preview:", commands = { "preview_open", "preview_url", "preview_reopen", "preview_stop" } },
		{ title = "Export:", commands = { "export_html", "export_svg", "print_preview" } },
		{ title = "Server:", commands = { "server_start", "server_stop", "server_restart" } },
		{ title = "Maintenance:", commands = { "install" } },
	}

	for _, group in ipairs(groups) do
		table.insert(lines, "")
		table.insert(lines, group.title)
		for _, cmd in ipairs(group.commands) do
			local subcommand = subcommands[cmd]
			if subcommand then
				table.insert(lines, string.format("  :Abc %s - %s", cmd, subcommand.desc))
			end
		end
	end

	vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

--- Register buffer-specific commands
---@param bufnr number Buffer number
function abc_cmds.register_buffer_commands(bufnr)
	vim.api.nvim_buf_create_user_command(bufnr, "Abc", function(opts)
		local subcommand_name = opts.fargs[1]

		if not subcommand_name then
			show_help()
			return
		end

		local subcommand = subcommands[subcommand_name]
		if subcommand then
			subcommand.impl()
		else
			vim.notify(
				string.format("Unknown subcommand: %s\nUse :Abc to see all available commands", subcommand_name),
				vim.log.levels.ERROR
			)
		end
	end, {
		nargs = "*",
		desc = "ABC notation commands",
		complete = function(arg_lead, _, _)
			-- Filter subcommands that start with the current input
			local matches = {}
			for cmd_name, _ in pairs(subcommands) do
				if vim.startswith(cmd_name, arg_lead) then
					table.insert(matches, cmd_name)
				end
			end
			table.sort(matches)
			return matches
		end,
	})
end

return abc_cmds
