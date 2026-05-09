local M = {}

---@param command string[]
---@return string
local function shell_command(command)
	return table.concat(vim.tbl_map(vim.fn.shellescape, command), " ")
end

---@param spec kyme.ProviderSpec<kyme.RunnerProvider>
---@return kyme.RunnerProvider
function M.create(spec)
	local opts = spec.opts or {}

	return {
		name = spec[1],

		---@param task kyme.Task
		---@param ctx kyme.ExecutionCtx
		execute = function(task, ctx)
			local Terminal = require("toggleterm.terminal").Terminal

			local term = Terminal:new(vim.tbl_deep_extend("force", {
				cmd = shell_command(task.command),
				dir = ctx.cwd,
				hidden = true,
				direction = "float",
				display_name = task.name,
			}, opts.terminal or {}))

			vim.notify(("Started task: %s"):format(task.name), vim.log.levels.INFO)
			term:spawn()
		end,
	}
end

return M
