local h = require("tests.helpers")

local core = require("kyme.core")
local executions = require("kyme.executions")
local state = require("kyme.state")

local task = {
	id = "test:ok",
	name = "ok",
	command = { "echo", "ok" },
}

local function reset_state()
	state.tasks = {}
	state.sourceProviders = {}
	state.pickerProvider = nil
	state.runnerProvider = nil
	state.executions = {}
	state.execution_order = {}
	state.next_execution_id = 0
end

local function with_vim_stubs(fn)
	local original_notify = vim.notify
	local original_schedule = vim.schedule
	local notifications = {}

	rawset(vim, "notify", function(message, level)
		table.insert(notifications, {
			message = message,
			level = level,
		})
	end)

	rawset(vim, "schedule", function(callback)
		callback()
	end)

	local ok, err = pcall(fn, notifications)

	rawset(vim, "notify", original_notify)
	rawset(vim, "schedule", original_schedule)

	if not ok then
		error(err, 0)
	end
end

return {
	{
		name = "core.run registers a running execution and updates succeeded on exit",
		fn = function()
			reset_state()

			local captured_hooks
			local open_called = false

			state.runnerProvider = {
				name = "test",
				start = function(started_task, _, hooks)
					h.same(task, started_task)
					captured_hooks = hooks

					return {
						open = function()
							open_called = true
						end,
					}
				end,
			}

			with_vim_stubs(function(notifications)
				local execution = core.run(task)

				h.truthy(execution)
				h.same("1", execution.id)
				h.same(task, execution.task)
				h.same("running", execution.status)
				h.same(execution, state.executions["1"])
				h.same({ "1" }, state.execution_order)
				h.same(execution, executions.list()[1])
				h.same("Started ok", notifications[1].message)

				local ok, err = executions.open("1")
				h.same(true, ok)
				h.same(nil, err)
				h.same(true, open_called)

				captured_hooks.on_exit(0)
				h.same("succeeded", execution.status)
				h.same(0, execution.exit_code)
				h.truthy(execution.ended_at)
			end)
		end,
	},
	{
		name = "core.run updates failed on non-zero exit",
		fn = function()
			reset_state()

			local captured_hooks

			state.runnerProvider = {
				name = "test",
				start = function(_, _, hooks)
					captured_hooks = hooks
					return {}
				end,
			}

			with_vim_stubs(function()
				local execution = core.run(task)

				captured_hooks.on_exit(2)

				h.same("failed", execution.status)
				h.same(2, execution.exit_code)
			end)
		end,
	},
	{
		name = "executions.stop marks stopping and updates stopped after runner exit",
		fn = function()
			reset_state()

			local captured_hooks
			local stop_called = false

			state.runnerProvider = {
				name = "test",
				start = function(_, _, hooks)
					captured_hooks = hooks

					return {
						stop = function()
							stop_called = true
							captured_hooks.on_exit(143)
						end,
					}
				end,
			}

			with_vim_stubs(function()
				local execution = core.run(task)
				local ok, err = executions.stop(execution.id)

				h.same(true, ok)
				h.same(nil, err)
				h.same(true, stop_called)
				h.same(true, execution._stopping)
				h.same("stopped", execution.status)
				h.same(143, execution.exit_code)
			end)
		end,
	},
	{
		name = "core.run leaves registry untouched when runner start fails",
		fn = function()
			reset_state()

			state.runnerProvider = {
				name = "test",
				start = function()
					error("boom")
				end,
			}

			with_vim_stubs(function(notifications)
				local execution = core.run(task)

				h.same(nil, execution)
				h.same({}, state.executions)
				h.same({}, state.execution_order)
				h.same(vim.log.levels.ERROR, notifications[1].level)
			end)
		end,
	},
	{
		name = "executions.pick_execution delegates to picker provider actions",
		fn = function()
			reset_state()

			local open_called = false
			local stop_called = false
			local picked

			state.executions["1"] = {
				id = "1",
				task = task,
				status = "running",
				started_at = os.time(),
				_handle = {
					open = function()
						open_called = true
					end,
					stop = function()
						stop_called = true
					end,
				},
			}
			state.execution_order = { "1" }
			state.pickerProvider = {
				name = "test",
				pick_execution = function(items, actions)
					picked = items
					actions.open("1")
					actions.stop("1")
				end,
			}

			with_vim_stubs(function()
				executions.pick_execution()

				h.same(state.executions["1"], picked[1])
				h.same(true, open_called)
				h.same(true, stop_called)
			end)
		end,
	},
}
