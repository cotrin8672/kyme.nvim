local state = require("kyme.state")
local config = require("kyme.config")

local M = {}

---@return string
local function next_execution_id()
	state.next_execution_id = state.next_execution_id + 1
	return tostring(state.next_execution_id)
end

---@return kyme.ExecutionCtx
local function makeExecuteCtx()
	return {
		cwd = vim.fn.getcwd(),
		bufnr = vim.api.nvim_get_current_buf(),
		winid = vim.api.nvim_get_current_win(),
	}
end

function M.setup(opts)
	config.set(opts)

	local cfg = config.get()
	state.pickerProvider = cfg.picker.module.create(cfg.picker.opts)
	state.runnerProvider = cfg.runner.module.create(cfg.runner.opts)
	state.sourceProviders = {}

	for _, sourceFactory in ipairs(cfg.sources) do
		local sourceProvider = sourceFactory.module.create(sourceFactory.opts)
		table.insert(state.sourceProviders, sourceProvider)
	end
end

---@param task kyme.Task
---@return kyme.Execution?
function M.run(task)
	local execution = {
		id = next_execution_id(),
		task = task,
		status = "running",
		started_at = os.time(),
	}

	local ctx = makeExecuteCtx()

	local ok, handle_or_err = pcall(function()
		return state.runnerProvider.start(task, ctx, {
			on_exit = function(code)
				vim.schedule(function()
					execution.ended_at = os.time()
					execution.exit_code = code

					if execution._stopping then
						execution.status = "stopped"
					elseif code == 0 then
						execution.status = "succeeded"
					else
						execution.status = "failed"
					end
				end)
			end,
		})
	end)

	if not ok then
		vim.notify(("kyme: failed to start task %s: %s"):format(task.name, handle_or_err), vim.log.levels.ERROR)
		return nil
	end

	execution._handle = handle_or_err
	state.executions[execution.id] = execution
	table.insert(state.execution_order, execution.id)

	vim.notify(("Started %s"):format(task.name), vim.log.levels.INFO)

	return execution
end

function M.pick_task()
	M.collect(function(tasks)
		state.pickerProvider.pick_task(tasks, function(result)
			if not result then
				return
			end

			for _, task in ipairs(result.tasks) do
				M.run(task)
			end
		end)
	end)
end

---@param done? fun(tasks: kyme.Task[])
function M.collect(done)
	state.tasks = {}

	local sources = state.sourceProviders
	if #sources == 0 then
		if done then
			done(state.tasks)
		end

		return
	end

	local remaining = #sources

	local function finish()
		remaining = remaining - 1
		if remaining == 0 and done then
			done(state.tasks)
		end
	end

	for _, sourceProvider in ipairs(sources) do
		sourceProvider.collect(function(tasks)
			vim.list_extend(state.tasks, tasks or {})
			finish()
		end)
	end
end

return M
