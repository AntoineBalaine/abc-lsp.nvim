local abc_cmds = {}
local config = require("abc_lsp.config")

-- Register buffer-specific commands
function abc_cmds.register_buffer_commands(bufnr)
	local opts = config.options

	-- Create buffer-local commands
	vim.api.nvim_buf_create_user_command(bufnr, "AbcDivideRhythm", function(opts)
		abc_cmds.divide_rhythm(opts)
	end, { desc = "Divide rhythm in selection", range = true })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcMultiplyRhythm", function(opts)
		abc_cmds.multiply_rhythm(opts)
	end, { desc = "Multiply rhythm in selection", range = true })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcTransposeUp", function(opts)
		abc_cmds.transpose_up(opts)
	end, { desc = "Transpose selection up an octave", range = true })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcTransposeDown", function(opts)
		abc_cmds.transpose_down(opts)
	end, { desc = "Transpose selection down an octave", range = true })
end

-- Helper function to get the current selection
local function get_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	-- If both marks are set and valid (line > 0)
	if start_pos[2] > 0 and end_pos[2] > 0 then
		-- Visual selection exists, use it
		return {
			start = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
			["end"] = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
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

-- Helper function to apply text edits
local function apply_text_edits(text_edits, bufnr)
	if not text_edits or #text_edits == 0 then
		return
	end

	bufnr = bufnr or vim.api.nvim_get_current_buf()
	vim.lsp.util.apply_text_edits(text_edits, bufnr, "utf-8")
end

-- Helper function to execute an ABC LSP command with range support
local function execute_abc_command(opts, method, error_msg, success_msg)
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

-- Divide rhythm in selection
function abc_cmds.divide_rhythm(opts)
	execute_abc_command(opts, "divideRhythm", "Error dividing rhythm: ", "Rhythm divided successfully")
end

-- Multiply rhythm in selection
function abc_cmds.multiply_rhythm(opts)
	execute_abc_command(opts, "multiplyRhythm", "Error multiplying rhythm: ", "Rhythm multiplied successfully")
end

-- Transpose Function to transpose up
function abc_cmds.transpose_up(opts)
	execute_abc_command(opts, "transposeUp", "Error transposing up: ", "Transposed up successfully")
end

-- Function to transpose down
function abc_cmds.transpose_down(opts)
	execute_abc_command(opts, "transposeDn", "Error transposing down: ", "Transposed down successfully")
end

return abc_cmds
