---@class AbcExport
local M = {}

---@type AbcPreview
local preview = require("abc_lsp.preview")

--- Handler for export completion messages
---@param message table Message with export status
local function handle_export_completion(message)
	if message.type == "exportComplete" then
		vim.notify("Export completed: " .. message.path, vim.log.levels.INFO)
	elseif message.type == "exportError" then
		vim.notify("Export error: " .. message.error, vim.log.levels.ERROR)
	end
end

--- Set up the export completion handler
local function setup_export_handler()
	-- Only set up once
	if M.export_handler_setup then
		return
	end

	-- Add handler to preview stdout callback
	local original_stdout = preview.stdout_callback
	preview.stdout_callback = function(data)
		if original_stdout then
			original_stdout(data)
		end

		-- Process export messages
		if data and #data > 0 then
			for _, line in ipairs(data) do
				if line and line ~= "" then
					local success, message = pcall(vim.fn.json_decode, line)
					if success and (message.type == "exportComplete" or message.type == "exportError") then
						handle_export_completion(message)
					end
				end
			end
		end
	end

	M.export_handler_setup = true
end

--- Export as HTML
function M.export_html()
	-- Ensure server is running
	if not preview.server_job_id then
		preview.start_server()
		if not preview.server_job_id then
			vim.notify("Failed to start preview server for export", vim.log.levels.ERROR)
			return
		end
	end

	-- Set up export handler if not already done
	setup_export_handler()

	-- Get current buffer content
	local bufnr = vim.api.nvim_get_current_buf()
	local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

	-- Send content to server
	preview.send_content(content)

	-- Get current file path
	local file_path = vim.fn.expand("%:p")
	local export_path = file_path .. ".html"

	-- Request export
	local message = vim.fn.json_encode({
		type = "requestExport",
		format = "html",
		path = export_path,
	})

	vim.fn.chansend(preview.server_job_id, message .. "\n")
	vim.notify("Exporting HTML to " .. export_path, vim.log.levels.INFO)
end

--- Export as SVG
function M.export_svg()
	-- Ensure server is running
	if not preview.server_job_id then
		preview.start_server()
		if not preview.server_job_id then
			vim.notify("Failed to start preview server for export", vim.log.levels.ERROR)
			return
		end
	end

	-- Set up export handler if not already done
	setup_export_handler()

	-- Get current buffer content
	local bufnr = vim.api.nvim_get_current_buf()
	local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

	-- Send content to server
	preview.send_content(content)

	-- Get current file path
	local file_path = vim.fn.expand("%:p")
	local export_path = file_path .. ".svg"

	-- Request export
	local message = vim.fn.json_encode({
		type = "requestExport",
		format = "svg",
		path = export_path,
	})

	vim.fn.chansend(preview.server_job_id, message .. "\n")
	vim.notify("Exporting SVG to " .. export_path, vim.log.levels.INFO)
end

--- Open print preview
function M.print_preview()
	-- Ensure server is running
	if not preview.server_job_id then
		preview.start_server()
		if not preview.server_job_id then
			vim.notify("Failed to start preview server for print preview", vim.log.levels.ERROR)
			return
		end
	end

	-- Get current buffer content
	local bufnr = vim.api.nvim_get_current_buf()
	local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")

	-- Send content to server
	preview.send_content(content)

	-- Open print preview URL
	local url = "http://localhost:" .. preview.server_port .. "/print"
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

return M
