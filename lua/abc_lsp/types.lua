---@meta

---@class AbcConfig
---@field defaults table Default configuration options
---@field defaults.server table Server configuration
---@field defaults.server.cmd string[]|nil Path to the ABC LSP server executable
---@field defaults.server.settings table Server settings
---@field defaults.server.capabilities table Additional server capabilities
---@field defaults.preview table Preview configuration
---@field defaults.preview.auto_open boolean Auto-open preview when opening an ABC file
---@field defaults.preview.port number Port for the preview server
---@field defaults.preview.options table Rendering options
---@field defaults.preview.options.responsive boolean Responsive rendering
---@field defaults.preview.options.print boolean Print mode
---@field defaults.preview.options.oneSvgPerLine boolean One SVG per line
---@field defaults.preview.options.showDebug boolean Show debug information
---@field defaults.preview.options.jazzchords boolean Jazz chords
---@field defaults.preview.options.visualTranspose number Visual transpose
---@field defaults.preview.options.showTransposedSource boolean Show transposed source
---@field defaults.export table Export configuration
---@field defaults.export.default_directory string|nil Default directory for exports
---@field options table Runtime options (populated by setup)

---@class AbcServer
---@field client_id number|nil LSP client ID
---@field server_running boolean Whether the server is running
---@field start function Start the ABC LSP server
---@field stop function Stop the ABC LSP server
---@field restart function Restart the ABC LSP server
---@field attach_to_buffer function Attach to a buffer
---@field is_running function Check if the server is running
---@field get_client_id function Get the client ID

---@class AbcPreview
---@field server_job_id number|nil Server job ID
---@field server_port number Server port
---@field start_server function Start the preview server
---@field stop_server function Stop the preview server
---@field send_content function Send content to the server
---@field send_config function Send configuration to the server
---@field handle_click function Handle click events from the preview
---@field byte_to_pos function Convert byte position to line/column
---@field open_preview function Open preview in browser
---@field update_preview function Update preview with current buffer content
---@field setup_autocommands function Set up autocommands for live preview

---@class AbcExport
---@field export_html function Export as HTML
---@field export_svg function Export as SVG
---@field print_preview function Open print preview

---@class AbcInstall
---@field check_node function Check if Node.js is installed
---@field check_npm function Check if npm is installed
---@field get_plugin_root function Get the plugin root directory
---@field check_dependencies function Check if dependencies are installed
---@field install_dependencies function Install dependencies
---@field build_typescript function Build the TypeScript code
---@field run function Run the full installation process
---@field install function Expose a function for plugin managers to call

---@class AbcCommands
---@field register_buffer_commands function Register buffer-specific commands

---@class AbcLsp
---@field setup function Setup function to initialize the plugin
---@field create_autocommands function Create autocommands for the plugin
---@field start_server function Start the ABC LSP server
---@field stop_server function Stop the ABC LSP server
---@field restart_server function Restart the ABC LSP server
---@field open_preview function Open ABC preview
---@field stop_preview function Stop ABC preview server
---@field export_html function Export ABC as HTML
---@field export_svg function Export ABC as SVG
---@field print_preview function Open print preview

return {}
