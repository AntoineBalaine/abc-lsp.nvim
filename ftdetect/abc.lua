vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.abc",
  callback = function()
    vim.bo.filetype = "abc"
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.abcx",
  callback = function()
    vim.bo.filetype = "abc"
  end,
})
