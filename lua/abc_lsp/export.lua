local M = {}
local preview = require('abc_lsp.preview')
local config = require('abc_lsp.config')

-- Export as HTML
function M.export_html()
  -- Ensure server is running
  if not preview.server_job_id then
    preview.start_server()
    if not preview.server_job_id then
      vim.notify('Failed to start preview server for export', vim.log.levels.ERROR)
      return
    end
  end

  -- Get current buffer content
  local bufnr = vim.api.nvim_get_current_buf()
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')

  -- Send content to server
  preview.send_content(content)

  -- Get current file path
  local file_path = vim.fn.expand('%:p')
  local export_path = file_path .. '.html'

  -- Request SVG from server
  local message = vim.fn.json_encode({
    type = 'requestExport',
    format = 'html',
    path = export_path
  })

  vim.fn.chansend(preview.server_job_id, message .. '\n')

  vim.notify('Exporting HTML to ' .. export_path, vim.log.levels.INFO)
end

-- Export as SVG
function M.export_svg()
  -- Ensure server is running
  if not preview.server_job_id then
    preview.start_server()
    if not preview.server_job_id then
      vim.notify('Failed to start preview server for export', vim.log.levels.ERROR)
      return
    end
  end

  -- Get current buffer content
  local bufnr = vim.api.nvim_get_current_buf()
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')

  -- Send content to server
  preview.send_content(content)

  -- Get current file path
  local file_path = vim.fn.expand('%:p')
  local export_path = file_path .. '.svg'

  -- Request SVG from server
  local message = vim.fn.json_encode({
    type = 'requestExport',
    format = 'svg',
    path = export_path
  })

  vim.fn.chansend(preview.server_job_id, message .. '\n')

  vim.notify('Exporting SVG to ' .. export_path, vim.log.levels.INFO)
end

-- Open print preview
function M.print_preview()
  -- Ensure server is running
  if not preview.server_job_id then
    preview.start_server()
    if not preview.server_job_id then
      vim.notify('Failed to start preview server for print preview', vim.log.levels.ERROR)
      return
    end
  end

  -- Get current buffer content
  local bufnr = vim.api.nvim_get_current_buf()
  local content = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), '\n')

  -- Send content to server
  preview.send_content(content)

  -- Open print preview URL
  local url = 'http://localhost:' .. preview.server_port .. '/print'
  local cmd

  if vim.fn.has('mac') == 1 then
    cmd = 'open'
  elseif vim.fn.has('unix') == 1 then
    cmd = 'xdg-open'
  elseif vim.fn.has('win32') == 1 then
    cmd = 'start'
  end

  if cmd then
    vim.fn.jobstart(cmd .. ' ' .. url, { detach = true })
  else
    vim.notify('Unable to open browser automatically. Please open: ' .. url, vim.log.levels.INFO)
  end
end

return M
