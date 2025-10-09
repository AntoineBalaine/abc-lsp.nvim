---@class AbcMode
---@field abc_insert_active boolean
local Abc = {}

local key_corresponds = {
	["é"] = "f",
	p = "g",
	o = "a",
	v = "b",
	d = "c'",
	l = "d'",
	j = "e'",
	--
	u = "F",
	i = "G",
	e = "A",
	t = "B",
	s = "c",
	r = "d",
	n = "e",
	--
	y = "F,",
	x = "G,",
	k = "A,",
	q = "B,",
	g = "C",
	h = "D",
	f = "E",
}
Abc.abc_insert_active = false

local function update_statuseline()
	-- Trigger lualine refresh
	if package.loaded["lualine"] then
		require("lualine").refresh()
	end
end

function Abc.enter_abc_insert()
	Abc.abc_insert_active = true
	for key, value in pairs(key_corresponds) do
		vim.api.nvim_buf_set_keymap(0, "i", key, value, { noremap = true, silent = true })
		-- sharp note
		vim.api.nvim_buf_set_keymap(0, "i", "<C-" .. key .. ">", "^" .. value, { noremap = true, silent = true })
		-- flat note
		vim.api.nvim_buf_set_keymap(0, "i", "<A-" .. key .. ">", "_" .. value, { noremap = true, silent = true })
	end
	_G.abc_mode_active = true
	update_statuseline()
	vim.cmd("startinsert")
end

function Abc.exit_abc_insert()
	Abc.abc_insert_active = false
	for key, _ in pairs(key_corresponds) do
		pcall(function()
			vim.api.nvim_buf_del_keymap(0, "i", key)
		end)
		pcall(function()
			vim.api.nvim_buf_del_keymap(0, "i", "<C-" .. key .. ">")
		end)
		pcall(function()
			vim.api.nvim_buf_del_keymap(0, "i", "<A-" .. key .. ">")
		end)
	end

	_G.abc_mode_active = false
	update_statuseline()
end

_G.abc_mode = Abc

-- go to insert mode with `m`
vim.api.nvim_buf_set_keymap(
	0,
	"n",
	"m",
	":lua _G.abc_mode.enter_abc_insert()<CR>",
	{ noremap = true, silent = true, desc = "go to insert mode with `m`" }
)

vim.api.nvim_buf_set_keymap(
	0,
	"n",
	"l",
	":lua o<CR>:lua _G.abc_mode.enter_abc_insert()<CR>",
	{ noremap = true, silent = true, desc = "New line below and enter ABCINSERT mode" }
)

vim.api.nvim_buf_set_keymap(
	0,
	"n",
	"O",
	":lua O<CR>:lua _G.abc_mode.enter_abc_insert()<CR>",
	{ noremap = true, silent = true, desc = "New line above and enter ABCINSERT mode" }
)

local bufnr = vim.api.nvim_get_current_buf()
vim.api.nvim_create_augroup("ABCInsert_" .. bufnr, { clear = true })
vim.api.nvim_create_autocmd("InsertLeave", {
	group = "ABCInsert_" .. bufnr,
	buffer = bufnr,
	callback = function()
		_G.abc_mode.exit_abc_insert()
	end,
})
