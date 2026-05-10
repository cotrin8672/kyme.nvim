local M = {}

---@generic T : kyme.ProviderBase
---@param module kyme.ProviderModule<T>
---@param opts? table
---@return kyme.ProviderFactory<T>
function M.factory(module, opts)
	return {
		module = module,
		opts = opts,
	}
end

return M
