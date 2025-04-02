---@class AbcInstall
local M = {}

-- Check if a command exists
local function command_exists(cmd)
  local handle = io.popen("command -v " .. cmd .. " >/dev/null 2>&1 && echo 'true' || echo 'false'")
  if not handle then return false end

  local result = handle:read("*a"):gsub("%s+", "")
  handle:close()
  return result == "true"
end

-- Check if Node.js is installed
function M.check_node()
  if not command_exists("node") then
    vim.notify(
      "Node.js is required for ABC preview server. Please install Node.js and try again.",
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

-- Check if npm is installed
function M.check_npm()
  if not command_exists("npm") then
    vim.notify(
      "npm is required for ABC preview server. Please install npm and try again.",
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

-- Get the plugin root directory
function M.get_plugin_root()
  local source = debug.getinfo(1, "S").source:sub(2)
  return vim.fn.fnamemodify(source, ":h:h:h")
end

-- Check if dependencies are installed
function M.check_dependencies()
  local plugin_root = M.get_plugin_root()
  local server_dir = plugin_root .. "/preview-server"
  local node_modules = server_dir .. "/node_modules"

  if vim.fn.isdirectory(node_modules) == 0 then
    return false
  end

  -- Check for key dependencies
  local express_dir = node_modules .. "/express"
  local ws_dir = node_modules .. "/ws"

  return vim.fn.isdirectory(express_dir) == 1 and vim.fn.isdirectory(ws_dir) == 1
end

-- Install dependencies
function M.install_dependencies()
  if not M.check_node() or not M.check_npm() then
    return false
  end

  local plugin_root = M.get_plugin_root()
  local server_dir = plugin_root .. "/preview-server"

  vim.notify("Installing ABC preview server dependencies...", vim.log.levels.INFO)

  -- Run npm install
  local cmd = "cd " .. server_dir .. " && npm install --production"
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    vim.notify("Failed to run npm install", vim.log.levels.ERROR)
    return false
  end

  local result = handle:read("*a")
  local success = handle:close()

  if not success then
    vim.notify("Failed to install dependencies: " .. result, vim.log.levels.ERROR)
    return false
  end

  vim.notify("ABC preview server dependencies installed successfully", vim.log.levels.INFO)
  return true
end

-- Build the TypeScript code
function M.build_typescript()
  if not M.check_node() or not M.check_npm() then
    return false
  end

  local plugin_root = M.get_plugin_root()
  local server_dir = plugin_root .. "/preview-server"

  vim.notify("Building ABC preview server...", vim.log.levels.INFO)

  -- Run npm run build
  local cmd = "cd " .. server_dir .. " && npm run build"
  local handle = io.popen(cmd .. " 2>&1")
  if not handle then
    vim.notify("Failed to run build script", vim.log.levels.ERROR)
    return false
  end

  local result = handle:read("*a")
  local success = handle:close()

  if not success then
    vim.notify("Failed to build TypeScript: " .. result, vim.log.levels.ERROR)
    return false
  end

  vim.notify("ABC preview server built successfully", vim.log.levels.INFO)
  return true
end

-- Run the full installation process
function M.run()
  if not M.check_dependencies() then
    local choice = vim.fn.confirm(
      "ABC preview server dependencies not found. Install now?",
      "&Yes\n&No", 1
    )

    if choice == 1 then
      if M.install_dependencies() then
        M.build_typescript()
      end
    else
      vim.notify(
        "Dependencies not installed. Preview functionality will not work. " ..
        "See README for manual installation instructions.",
        vim.log.levels.WARN
      )
    end
  end
end

-- Expose a function for plugin managers to call
function M.install()
  M.install_dependencies()
  M.build_typescript()
end

return M
