---@class AbcPreview
local M = {}

---@type AbcConfig
local config = require("abc_lsp.config")

-- Store server job ID
---@type number|nil
M.server_job_id = nil
---@type number
M.server_port = 8088

-- Track previewed buffers: [bufnr] = {path, slug, opened}
M.previewed_buffers = {}

-- Counter for untitled files
M.untitled_counter = 0

--- Callback for processing stdout from the server
---@type function|nil
M.stdout_callback = nil

--- Generate URL-safe slug from file path
---@param file_path string Absolute path to the file
---@return string slug URL-safe slug
local function generate_slug(file_path)
	-- Get filename without path and extension
	local basename = vim.fn.fnamemodify(file_path, ":t:r")

	-- Handle unnamed buffers
	if basename == "" or basename == "untitled" then
		M.untitled_counter = M.untitled_counter + 1
		return "untitled-" .. M.untitled_counter
	end

	-- Replace spaces with dashes
	local slug = basename:gsub("%s+", "-")

	-- Check for collisions
	local counter = 1
	local original_slug = slug
	local collision = false

	for _, buf_info in pairs(M.previewed_buffers) do
		if buf_info.slug == slug then
			collision = true
			break
		end
	end

	if collision then
		repeat
			slug = original_slug .. "-" .. counter
			counter = counter + 1
			collision = false
			for _, buf_info in pairs(M.previewed_buffers) do
				if buf_info.slug == slug then
					collision = true
					break
				end
			end
		until not collision
	end

	return slug
end

--- Get or create buffer info
---@param bufnr number Buffer number
---@return table Buffer info {path, slug, opened}
local function get_buffer_info(bufnr)
	if M.previewed_buffers[bufnr] then
		return M.previewed_buffers[bufnr]
	end

	-- Create new buffer info
	local path = vim.api.nvim_buf_get_name(bufnr)

	-- Handle unnamed buffers
	if path == "" then
		path = "[No Name]"
	end

	local slug = generate_slug(path)

	local info = {
		path = path,
		slug = slug,
		opened = false,
	}

	M.previewed_buffers[bufnr] = info
	return info
end

--- Start the preview server
---@return number|nil Port number if server started successfully, nil otherwise
function M.start_server()
	if M.server_job_id then
		-- Server already running
		return M.server_port
	end

	-- Try to find the server path
	local server_path

	-- First try: Use debug.getinfo to find the plugin path
	local source = debug.getinfo(1, "S").source:sub(2) -- Remove the '@' prefix
	local plugin_path = vim.fn.fnamemodify(source, ":h:h:h") -- Go up 3 levels from lua/abc_lsp/preview.lua
	local primary_path = plugin_path .. "/preview-server/dist/server.js"

	if vim.fn.filereadable(primary_path) == 1 then
		server_path = primary_path
	else
		-- Second try: Check common plugin installation paths
		local fallback_paths = {
			vim.fn.stdpath("data") .. "/site/pack/*/start/abc-lsp.nvim/preview-server/dist/server.js",
			vim.fn.stdpath("data") .. "/site/pack/*/opt/abc-lsp.nvim/preview-server/dist/server.js",
			vim.fn.stdpath("config") .. "/plugged/abc-lsp.nvim/preview-server/dist/server.js", -- vim-plug
			vim.fn.stdpath("config") .. "/pack/*/start/abc-lsp.nvim/preview-server/dist/server.js",
		}

		for _, path_pattern in ipairs(fallback_paths) do
			local expanded_paths = vim.fn.glob(path_pattern, false, true)
			if #expanded_paths > 0 then
				server_path = expanded_paths[1]
				break
			end
		end
	end

	-- Check if we found a valid server path
	if not server_path or vim.fn.filereadable(server_path) == 0 then
		vim.notify("ABC Preview Server not found. Please check installation.", vim.log.levels.ERROR)
		return nil
	end

	-- Start server as background job
	M.server_job_id = vim.fn.jobstart("node " .. server_path .. " --port=" .. M.server_port, {
		on_stdout = function(_, data)
			if data and #data > 0 then
				-- Process server output
				for _, line in ipairs(data) do
					if line and line ~= "" then
						local success, message = pcall(vim.fn.json_decode, line)
						if success then
							if message.type == "serverInfo" then
								-- Server reported actual port
								M.server_port = message.port
								vim.notify("ABC Preview Server started on port " .. M.server_port, vim.log.levels.INFO)
							elseif message.type == "click" then
								M.handle_click(message)
							end
						end
					end
				end
			end

			-- Call the custom stdout callback if set
			if M.stdout_callback then
				M.stdout_callback(data)
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				for _, line in ipairs(data) do
					if line and line ~= "" then
						vim.notify("ABC Preview Server: " .. line, vim.log.levels.INFO)
					end
				end
			end
		end,
		on_exit = function()
			M.server_job_id = nil
			vim.notify("ABC Preview Server stopped", vim.log.levels.INFO)
		end,
		detach = 1,
	})

	if M.server_job_id <= 0 then
		vim.notify("Failed to start ABC Preview Server", vim.log.levels.ERROR)
		return nil
	end

	return M.server_port
end

--- Stop the preview server
function M.stop_server()
	if M.server_job_id then
		vim.fn.jobstop(M.server_job_id)
		M.server_job_id = nil
	end
end

--- Send content to the server
---@param path string Absolute file path
---@param content string ABC notation content
---@return boolean Success status
function M.send_content(path, content)
	if not M.server_job_id then
		return false
	end

	local message = vim.fn.json_encode({
		type = "content",
		path = path,
		content = content,
	})

	vim.fn.chansend(M.server_job_id, message .. "\n")
	return true
end

--- Send configuration to the server
---@param config_options table Configuration options
---@return boolean Success status
function M.send_config(config_options)
	if not M.server_job_id then
		return false
	end

	local message = vim.fn.json_encode({
		type = "config",
		config = config_options,
	})

	vim.fn.chansend(M.server_job_id, message .. "\n")
	return true
end

--- Handle click events from the preview
---@param message table Message with startChar and endChar
function M.handle_click(message)
	local bufnr = vim.api.nvim_get_current_buf()
	local start_pos = vim.api.nvim_buf_get_offset(bufnr, 0) + message.startChar
	local end_pos = vim.api.nvim_buf_get_offset(bufnr, 0) + message.endChar

	-- Convert byte positions to line/column
	local start_line, start_col = M.byte_to_pos(bufnr, start_pos)
	local end_line, end_col = M.byte_to_pos(bufnr, end_pos)

	-- Set cursor position and selection
	vim.api.nvim_win_set_cursor(0, { start_line + 1, start_col })

	-- Create visual selection
	vim.cmd("normal! v")
	vim.api.nvim_win_set_cursor(0, { end_line + 1, end_col })
end

--- Convert byte position to line/column
---@param bufnr number Buffer number
---@param byte_pos number Byte position
---@return number, number Line and column
function M.byte_to_pos(bufnr, byte_pos)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local current_pos = 0

	for i, line in ipairs(lines) do
		local line_length = #line + 1 -- +1 for newline
		if current_pos + line_length > byte_pos then
			return i - 1, byte_pos - current_pos
		end
		current_pos = current_pos + line_length
	end

	-- Fallback to end of buffer
	return #lines - 1, #lines[#lines]
end

--- Get preview URL for a buffer
---@param bufnr number|nil Buffer number (defaults to current buffer)
---@return string|nil URL or nil if not previewed
function M.get_preview_url(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	if not M.server_job_id then
		return nil
	end

	local info = M.previewed_buffers[bufnr]
	if not info then
		return nil
	end

	return "http://localhost:" .. M.server_port .. "/" .. info.slug
end

--- Open preview in browser
---@param bufnr number|nil Buffer number (defaults to current buffer)
function M.open_preview(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()

	-- Get or create buffer info
	local info = get_buffer_info(bufnr)

	-- Start server if not running
	local port = M.start_server()
	if not port then
		return
	end

	-- Get current buffer content
	local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

	-- Send content to server
	M.send_content(info.path, content)

	-- Send configuration
	local options = config.options.preview or {}
	M.send_config(options)

	-- Only open browser if not already opened
	if not info.opened then
		local url = "http://localhost:" .. port .. "/" .. info.slug
		local cmd

		if vim.fn.has("mac") == 1 then
			cmd = "open"
		elseif vim.fn.has("unix") == 1 then
			cmd = "xdg-open"
		elseif vim.fn.has("win32") == 1 then
			cmd = "start"
		end

		if cmd then
			vim.fn.jobstart(cmd .. " " .. url, { detach = true })
			info.opened = true
		else
			vim.notify("Unable to open browser automatically. Please open: " .. url, vim.log.levels.INFO)
		end
	end
end

--- Reopen preview in browser for current buffer
function M.reopen_preview()
	local bufnr = vim.api.nvim_get_current_buf()
	local info = M.previewed_buffers[bufnr]

	if not info then
		vim.notify("No preview opened for this buffer. Use :AbcPreview first.", vim.log.levels.WARN)
		return
	end

	if not M.server_job_id then
		vim.notify("Preview server not running. Use :AbcPreview first.", vim.log.levels.WARN)
		return
	end

	local url = "http://localhost:" .. M.server_port .. "/" .. info.slug
	local cmd

	if vim.fn.has("mac") == 1 then
		cmd = "open"
	elseif vim.fn.has("unix") == 1 then
		cmd = "xdg-open"
	elseif vim.fn.has("win32") == 1 then
		cmd = "start"
	end

	if cmd then
		vim.fn.jobstart(cmd .. " " .. url, { detach = true })
	else
		vim.notify("Unable to open browser automatically. Please open: " .. url, vim.log.levels.INFO)
	end
end

--- Update preview with current buffer content
function M.update_preview()
	local bufnr = vim.api.nvim_get_current_buf()
	local info = M.previewed_buffers[bufnr]

	-- Only update if this buffer has been previewed
	if not info then
		return
	end

	local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	M.send_content(info.path, content)
end

--- Clean up buffer from server
---@param bufnr number Buffer number
function M.cleanup_buffer(bufnr)
	local info = M.previewed_buffers[bufnr]

	if not info then
		return
	end

	if M.server_job_id then
		local message = vim.fn.json_encode({
			type = "cleanup",
			path = info.path,
		})
		vim.fn.chansend(M.server_job_id, message .. "\n")
	end

	-- Remove from tracking
	M.previewed_buffers[bufnr] = nil
end

--- Send cursor position to the server
---@return boolean Success status
function M.send_cursor_position()
	if not M.server_job_id then
		return false
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0) -- Returns {row, col}
	local line = cursor[1] - 1 -- Convert to 0-indexed
	local col = cursor[2]

	-- Calculate character position
	local char_pos = vim.api.nvim_buf_get_offset(bufnr, line) + col

	local message = vim.fn.json_encode({
		type = "cursorMove",
		position = char_pos,
	})

	vim.fn.chansend(M.server_job_id, message .. "\n")
	return true
end

--- Set up autocommands for live preview
function M.setup_autocommands()
	local augroup = vim.api.nvim_create_augroup("AbcPreview", { clear = true })

	-- Update preview on buffer change
	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = augroup,
		pattern = "*.abc",
		callback = function()
			M.update_preview()
		end,
	})

	-- Track cursor movement
	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		group = augroup,
		pattern = "*.abc",
		callback = function()
			-- Debounce to avoid too many updates
			if M.cursor_timer then
				vim.fn.timer_stop(M.cursor_timer)
			end
			M.cursor_timer = vim.fn.timer_start(100, function()
				M.send_cursor_position()
			end)
		end,
	})

	-- Clean up on buffer delete
	vim.api.nvim_create_autocmd("BufDelete", {
		group = augroup,
		pattern = "*.abc",
		callback = function(args)
			M.cleanup_buffer(args.buf)
		end,
	})

	-- Clean up server on exit
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = augroup,
		callback = function()
			M.stop_server()
		end,
	})
end

return M
