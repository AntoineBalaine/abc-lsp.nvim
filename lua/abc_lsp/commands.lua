local abc_cmds = {}
local config = require("abc_lsp.config")

-- Register buffer-specific commands
function abc_cmds.register_buffer_commands(bufnr)
	local opts = config.options

	-- Create buffer-local commands
	vim.api.nvim_buf_create_user_command(bufnr, "AbcDivideRhythm", function()
		abc_cmds.divide_rhythm()
	end, { desc = "Divide rhythm in selection" })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcMultiplyRhythm", function()
		abc_cmds.multiply_rhythm()
	end, { desc = "Multiply rhythm in selection" })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcTransposeUp", function()
		abc_cmds.transpose_up()
	end, { desc = "Transpose selection up an octave" })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcTransposeDown", function()
		abc_cmds.transpose_down()
	end, { desc = "Transpose selection down an octave" })

	-- Setup keymaps if configured
	-- Setup buffer-local keymaps for custom commands
	local function buf_set_keymap(mode, lhs, rhs, opts)
		opts = opts or {}
		opts.buffer = bufnr
		vim.keymap.set(mode, lhs, rhs, opts)
	end

	-- Rhythm transformation commands
	if opts.keymaps.divide_rhythm then
		-- Normal mode
		buf_set_keymap("n", opts.keymaps.divide_rhythm, function()
			abc_cmds.divide_rhythm()
		end, { desc = "Divide rhythm" })

		-- Visual mode
		buf_set_keymap("v", opts.keymaps.divide_rhythm, function()
			abc_cmds.divide_rhythm()
		end, { desc = "Divide rhythm in selection" })
	end

	if opts.keymaps.multiply_rhythm then
		-- Normal mode
		buf_set_keymap("n", opts.keymaps.multiply_rhythm, function()
			abc_cmds.multiply_rhythm()
		end, { desc = "Multiply rhythm" })

		-- Visual mode
		buf_set_keymap("v", opts.keymaps.multiply_rhythm, function()
			abc_cmds.multiply_rhythm()
		end, { desc = "Multiply rhythm in selection" })
	end

	-- Transposition commands
	if opts.keymaps.transpose_up then
		-- Normal mode
		buf_set_keymap("n", opts.keymaps.transpose_up, function()
			abc_cmds.transpose_up()
		end, { desc = "Transpose up an octave" })

		-- Visual mode
		buf_set_keymap("v", opts.keymaps.transpose_up, function()
			abc_cmds.transpose_up()
		end, { desc = "Transpose selection up an octave" })
	end

	if opts.keymaps.transpose_down then
		-- Normal mode
		buf_set_keymap("n", opts.keymaps.transpose_down, function()
			abc_cmds.transpose_down()
		end, { desc = "Transpose down an octave" })

		-- Visual mode
		buf_set_keymap("v", opts.keymaps.transpose_down, function()
			abc_cmds.transpose_down()
		end, { desc = "Transpose selection down an octave" })
	end
end

-- Helper function to get the current selection
local function get_selection()
	local start_pos = vim.fn.getpos("'<")
	local end_pos = vim.fn.getpos("'>")

	return {
		start = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
		["end"] = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
		-- For LSP compatibility
		active = { line = end_pos[2] - 1, character = end_pos[3] - 1 },
		anchor = { line = start_pos[2] - 1, character = start_pos[3] - 1 },
	}
end

-- Helper function to apply text edits
local function apply_text_edits(text_edits)
	if not text_edits or #text_edits == 0 then
		return
	end

	vim.lsp.util.apply_text_edits(text_edits, 0, "utf-8")
end

-- Divide rhythm in selection
function abc_cmds.divide_rhythm()
	local bufnr = vim.api.nvim_get_current_buf()
	local abc_srvr = require("abc_lsp.server")
	local client = abc_srvr.client_id

	if not client then
		vim.notify("ABC LSP server not attached to current buffer", vim.log.levels.ERROR)
		return
	end

	-- Get current selection
	local selection = vim.get_visual_selection()
	local uri = vim.uri_from_bufnr(bufnr)

	-- Parameters for the custom request
	local params = {
		uri = uri,
		selection = selection,
	}

	-- Make the LSP request
	client.request("abc-lsp/divideRhythm", params, function(err, result, _, _)
		if err then
			vim.notify("Error dividing rhythm: " .. err.message, vim.log.levels.ERROR)
			return
		end

		-- Apply the text edits returned by the server
		if result then
			vim.lsp.util.apply_text_edits(result, bufnr, "utf-8")
			vim.notify("Rhythm divided successfully", vim.log.levels.INFO)
		end
	end, bufnr)
end

-- Multiply rhythm in selection
function abc_cmds.multiply_rhythm()
	local bufnr = vim.api.nvim_get_current_buf()
	local client = abc_srvr.client_id

	if not client then
		vim.notify("ABC LSP server not attached to current buffer", vim.log.levels.ERROR)
		return
	end

	-- Get current selection
	local selection = vim.get_visual_selection()
	local uri = vim.uri_from_bufnr(bufnr)

	-- Parameters for the custom request
	local params = {
		uri = uri,
		selection = selection,
	}

	-- Make the LSP request
	client.request("abc-lsp/multiplyRhythm", params, function(err, result, _, _)
		if err then
			vim.notify("Error multiplying rhythm: " .. err.message, vim.log.levels.ERROR)
			return
		end

		-- Apply the text edits returned by the server
		if result then
			vim.lsp.util.apply_text_edits(result, bufnr, "utf-8")
			vim.notify("Rhythm multiplied successfully", vim.log.levels.INFO)
		end
	end, bufnr)
end

-- Transpose Function to transpose up
function abc_cmds.transpose_up()
	local bufnr = vim.api.nvim_get_current_buf()
	local client = abc_srvr.get_client_id()

	if not client then
		vim.notify("ABC LSP server not attached to current buffer", vim.log.levels.ERROR)
		return
	end

	-- Get current selection
	local selection = vim.get_visual_selection()
	local uri = vim.uri_from_bufnr(bufnr)

	-- Parameters for the custom request
	local params = {
		uri = uri,
		selection = selection,
	}

	-- Make the LSP request
	client.request("abc-lsp/transposeUp", params, function(err, result, _, _)
		if err then
			vim.notify("Error transposing up: " .. err.message, vim.log.levels.ERROR)
			return
		end

		-- Apply the text edits returned by the server
		if result then
			vim.lsp.util.apply_text_edits(result, bufnr, "utf-8")
			vim.notify("Transposed up successfully", vim.log.levels.INFO)
		end
	end, bufnr)
end

-- Function to transpose down
function abc_cmds.transpose_down()
	local bufnr = vim.api.nvim_get_current_buf()
	local client = nil
	-- local client = abc_srvr.client_id

	if not client then
		vim.notify("ABC LSP server not attached to current buffer", vim.log.levels.ERROR)
		return
	end

	-- Get current selection
	local selection = vim.get_visual_selection()
	local uri = vim.uri_from_bufnr(bufnr)

	-- Parameters for the custom request
	local params = {
		uri = uri,
		selection = selection,
	}

	-- Make the LSP request
	client.request("abc-lsp/transposeDn", params, function(err, result, _, _)
		if err then
			vim.notify("Error transposing down: " .. err.message, vim.log.levels.ERROR)
			return
		end

		-- Apply the text edits returned by the server
		if result then
			vim.lsp.util.apply_text_edits(result, bufnr, "utf-8")
			vim.notify("Transposed down successfully", vim.log.levels.INFO)
		end
	end, bufnr)
end

return abc_cmds
