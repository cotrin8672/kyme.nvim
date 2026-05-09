local state = require("kyme.state")
local config = require("kyme.config")
local resolver = require("kyme.resolver")

local M = {}

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
	state.pickerProvider = resolver.picker(cfg.picker)
	state.runnerProvider = resolver.runner(cfg.runner)
end

function M.pick()
	M.collect(function(tasks)
		state.pickerProvider.pick(tasks, function(result)
			if not result then
				return
			end

			local ctx = makeExecuteCtx()
			for _, task in ipairs(result.tasks) do
				state.runnerProvider.execute(task, ctx)
			end
		end)
	end)
end

---@param done? fun(tasks: kyme.Task[])
function M.collect(done)
	state.tasks = {}

	local sources = config.get().sources
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

	for _, sourceSpecs in ipairs(sources) do
		---@type kyme.SourceProvider
		local source = resolver.source(sourceSpecs)

		source.collect(function(tasks)
			vim.list_extend(state.tasks, tasks or {})
			finish()
		end)
	end
end

return M
