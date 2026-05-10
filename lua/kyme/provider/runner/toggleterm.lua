local M = {}

---@param command string[]
---@return string
local function shell_command(command)
	return table.concat(vim.tbl_map(vim.fn.shellescape, command), " ")
end

---@param opts? table
---@return kyme.RunnerProvider
function M.create(opts)
	opts = opts or {}

	return {
		---@param task kyme.Task
		---@param ctx kyme.ExecutionCtx
		---@param hooks kyme.RunnerHooks
		---@return kyme.ExecutionHandle
		start = function(task, ctx, hooks)
			local Terminal = require("toggleterm.terminal").Terminal

			local term = Terminal:new(vim.tbl_deep_extend("force", {
				cmd = shell_command(task.command),
				dir = ctx.cwd,
				hidden = true,
				direction = "float",
				display_name = task.name,
				on_exit = function(_, _, code)
					hooks.on_exit(code)
				end,
			}, opts.terminal or {}))

			term:spawn()

			return {
				open = function()
					term:open()
				end,

				stop = function()
					term:shutdown()
				end,
			}
		end,
	}
end

return M
