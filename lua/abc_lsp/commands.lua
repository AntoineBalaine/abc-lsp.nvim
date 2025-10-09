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

--- Register buffer-specific commands
---@param bufnr number Buffer number
function abc_cmds.register_buffer_commands(bufnr)
	-- Create buffer-local commands
	vim.api.nvim_buf_create_user_command(bufnr, "AbcDivideRhythm", function()
		execute_abc_command("divideRhythm", "Error dividing rhythm: ", "Rhythm divided successfully")
	end, { desc = "Divide rhythm in selection", range = true })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcMultiplyRhythm", function()
		execute_abc_command("multiplyRhythm", "Error multiplying rhythm: ", "Rhythm multiplied successfully")
	end, { desc = "Multiply rhythm in selection", range = true })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcTransposeUp", function()
		execute_abc_command("transposeUp", "Error transposing up: ", "Transposed up successfully")
	end, { desc = "Transpose selection up an octave", range = true })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcTransposeDown", function()
		execute_abc_command("transposeDn", "Error transposing down: ", "Transposed down successfully")
	end, { desc = "Transpose selection down an octave", range = true })

	-- Preview and export commands
	vim.api.nvim_buf_create_user_command(bufnr, "AbcPreview", function()
		require("abc_lsp.preview").open_preview()
	end, { desc = "Open ABC preview in browser" })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcPreviewUrl", function()
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
			vim.notify("No preview opened for this buffer. Use :AbcPreview first.", vim.log.levels.WARN)
		end
	end, { desc = "Show and copy preview URL" })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcPreviewReopen", function()
		require("abc_lsp.preview").reopen_preview()
	end, { desc = "Reopen preview in browser" })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcExportHtml", function()
		require("abc_lsp.export").export_html()
	end, { desc = "Export ABC as HTML" })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcExportSvg", function()
		require("abc_lsp.export").export_svg()
	end, { desc = "Export ABC as SVG" })

	vim.api.nvim_buf_create_user_command(bufnr, "AbcPrintPreview", function()
		require("abc_lsp.export").print_preview()
	end, { desc = "Open ABC print preview" })
end

return abc_cmds
