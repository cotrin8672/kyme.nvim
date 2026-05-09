local M = {}

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
