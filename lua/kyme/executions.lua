local state = require("kyme.state")

local M = {}

---@param visual kyme.VisualProvider
---@param execution kyme.Execution
---@return kyme.PickerExecutionItem
local function make_execution_item(visual, execution)
	return {
		execution = execution,
		visual = visual.execution_item(execution),
		preview = visual.execution_preview(execution),
	}
end

---@return kyme.Execution[]
function M.list()
	local executions = {}

	for _, id in ipairs(state.execution_order) do
		local execution = state.executions[id]
		if execution then
			table.insert(executions, execution)
		end
	end

	return executions
end

---@param id string
---@return kyme.Execution?
function M.get(id)
	return state.executions[id]
end

---@param id string
---@return boolean, string?
function M.open(id)
	local execution = M.get(id)
	if not execution then
		return false, "execution not found"
	end

	local handle = execution._handle
	if not handle or not handle.open then
		return false, "execution is not openable"
	end

	handle.open()
	return true
end

---@param id string
---@return boolean, string?
function M.stop(id)
	local execution = M.get(id)
	if not execution then
		return false, "execution not found"
	end

	if execution.status ~= "running" then
		return false, "execution is not running"
	end

	local handle = execution._handle
	if not handle or not handle.stop then
		return false, "execution is not stoppable"
	end

	execution._stopping = true
	handle.stop()
	return true
end

function M.pick_execution()
	local picker = state.pickerProvider

	if not picker or not picker.pick_execution then
		vim.notify("kyme: execution picker is not supported by current picker provider", vim.log.levels.WARN)
		return
	end

	local items = vim.tbl_map(function(execution)
		return make_execution_item(state.visualProvider, execution)
	end, M.list())

	picker.pick_execution(items, {
		open = function(id)
			local ok, err = M.open(id)
			if not ok and err then
				vim.notify(err, vim.log.levels.WARN)
			end
		end,

		stop = function(id)
			local ok, err = M.stop(id)
			if not ok and err then
				vim.notify(err, vim.log.levels.WARN)
			end
		end,
	})
end

return M
