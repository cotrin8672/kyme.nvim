local M = {}

---@param opts kyme.Config
function M.setup(opts)
	require("kyme.core").setup(opts)
end

---@param done? fun(tasks: kyme.Task[])
function M.collect(done)
	require("kyme.core").collect(done)
end

function M.pick()
	require("kyme.core").pick()
end

return M
