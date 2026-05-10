local M = {}

---@param opts? table
---@return kyme.ProviderFactory<kyme.SourceProvider>
function M.mise(opts)
	return require("kyme.provider").factory(require("kyme.provider.source.mise"), opts)
end

---@param opts? table
---@return kyme.ProviderFactory<kyme.PickerProvider>
function M.snacks(opts)
	return require("kyme.provider").factory(require("kyme.provider.picker.snacks"), opts)
end

---@param opts? table
---@return kyme.ProviderFactory<kyme.RunnerProvider>
function M.toggleterm(opts)
	return require("kyme.provider").factory(require("kyme.provider.runner.toggleterm"), opts)
end

---@param opts? table
---@return kyme.ProviderFactory<kyme.VisualProvider>
function M.default_visual(opts)
	return require("kyme.provider").factory(require("kyme.provider.visual.default"), opts)
end

---@param opts kyme.Config
function M.setup(opts)
	require("kyme.core").setup(opts)
end

---@param done? fun(tasks: kyme.Task[])
function M.collect(done)
	require("kyme.core").collect(done)
end

function M.pick_task()
	require("kyme.core").pick_task()
end

function M.pick_execution()
	require("kyme.executions").pick_execution()
end

return M
