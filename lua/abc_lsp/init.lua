---@class AbcLsp
local M = {}

---@type AbcConfig
local abc_cfg = require("abc_lsp.config")
---@type AbcServer
local abc_srvr = require("abc_lsp.server")
---@type AbcPreview
local abc_preview = require("abc_lsp.preview")
---@type AbcInstall
local abc_install = require("abc_lsp.install")

--- Setup function to initialize the plugin
---@param opts table|nil Configuration options
function M.setup(opts)
	vim.lsp.set_log_level("debug")
	-- Merge user options with defaults
	opts = vim.tbl_deep_extend("force", abc_cfg.defaults, opts or {})

	-- Store the configuration
	abc_cfg.options = opts

	-- Check and install dependencies if needed
	abc_install.run()

	-- abc_srvr.start()

	-- Setup autocommands
	M.create_autocommands()

	-- Setup preview autocommands
	abc_preview.setup_autocommands()
end

--- Create autocommands for the plugin
function M.create_autocommands()
	local augroup = vim.api.nvim_create_augroup("AbcLsp", { clear = true })

	-- Attach to ABC files
	vim.api.nvim_create_autocmd("BufEnter", {
		group = augroup,
		pattern = { "*.abc", "*.abcx" },
		callback = function()
			-- Start the server if not already running
			if not abc_srvr.is_running() then
				abc_srvr.start()
			end

			-- Attach the LSP client to the buffer
			abc_srvr.attach_to_buffer(0)

			-- Handle preview on buffer enter
			local bufnr = vim.api.nvim_get_current_buf()
			local buf_info = abc_preview.previewed_buffers[bufnr]

			if abc_cfg.options.preview and abc_cfg.options.preview.auto_open then
				-- Auto-open preview if configured (won't re-open browser if already opened)
				abc_preview.open_preview()
			elseif buf_info then
				-- If preview was manually opened before, update content without opening browser
				abc_preview.update_preview()
			end
		end,
	})
end

--- Start the ABC LSP server
function M.start_server()
	abc_srvr.start()
end

--- Stop the ABC LSP server
function M.stop_server()
	abc_srvr.stop()
end

--- Restart the ABC LSP server
function M.restart_server()
	abc_srvr.restart()
end

--- Open ABC preview
function M.open_preview()
	abc_preview.open_preview()
end

--- Stop ABC preview server
function M.stop_preview()
	abc_preview.stop_server()
end

--- Export ABC as HTML
function M.export_html()
	---@type AbcExport
	local abc_export = require("abc_lsp.export")
	abc_export.export_html()
end

--- Export ABC as SVG
function M.export_svg()
	---@type AbcExport
	local abc_export = require("abc_lsp.export")
	abc_export.export_svg()
end

--- Open print preview
function M.print_preview()
	---@type AbcExport
	local abc_export = require("abc_lsp.export")
	abc_export.print_preview()
end

--- Install/rebuild preview server
function M.install()
	abc_install.install()
end

return M
