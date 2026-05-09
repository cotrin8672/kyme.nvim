local M = {}

local modules = {
	source = {
		mise = "kyme.provider.source.mise",
	},
	picker = {
		snacks = "kyme.provider.picker.snacks",
	},
	runner = {
		toggleterm = "kyme.provider.runner.toggleterm",
	},
}

---@generic T : kyme.ProviderBase
---@param kind "source"|"picker"|"runner"
---@param spec kyme.ProviderSpec<T>
---@return T
local function resolve(kind, spec)
	if not spec then
		error(("kyme: missing %s provider spec"):format(kind))
	end

	local name = spec[1]
	local modname = spec.module or modules[kind][name]
	if not modname then
		error(("kyme: unknown %s provider: %s"):format(kind, name))
	end

	---@type kyme.ProviderModule
	local mod = require(modname)

	return mod.create(spec)
end

---@param spec kyme.ProviderSpec<kyme.SourceProvider>
---@return kyme.SourceProvider
function M.source(spec)
	return resolve("source", spec)
end

---@param spec kyme.ProviderSpec<kyme.PickerProvider>
---@return kyme.PickerProvider
function M.picker(spec)
	return resolve("picker", spec)
end

---@param spec kyme.ProviderSpec<kyme.RunnerProvider>
---@return kyme.RunnerProvider
function M.runner(spec)
	return resolve("runner", spec)
end

return M
