local M = {}

---@type kyme.Config
local config = {
	sources = {},
	picker = nil,
	runner = nil,
}

function M.set(opts)
	config = opts
end

function M.get()
	return config
end

return M
