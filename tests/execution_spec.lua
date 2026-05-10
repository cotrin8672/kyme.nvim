local h = require("tests.helpers")

local kyme = require("kyme")
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
	state.visualProvider = nil
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
		name = "public built-in provider helpers return provider factories",
		fn = function()
			local source = kyme.mise({ source = true })
			local picker = kyme.snacks({ picker = true })
			local runner = kyme.toggleterm({ runner = true })
			local visual = kyme.default_visual({ visual = true })

			h.same(require("kyme.provider.source.mise"), source.module)
			h.same({ source = true }, source.opts)
			h.same(require("kyme.provider.picker.snacks"), picker.module)
			h.same({ picker = true }, picker.opts)
			h.same(require("kyme.provider.runner.toggleterm"), runner.module)
			h.same({ runner = true }, runner.opts)
			h.same(require("kyme.provider.visual.default"), visual.module)
			h.same({ visual = true }, visual.opts)
		end,
	},
	{
		name = "core.setup creates providers from factories",
		fn = function()
			reset_state()

			local source_opts
			local picker_opts
			local runner_opts
			local visual_opts

			local source_provider = {
				name = "source",
				collect = function(done)
					done({})
				end,
			}
			local picker_provider = {
				name = "picker",
				pick_task = function() end,
			}
			local runner_provider = {
				name = "runner",
				start = function() end,
			}
			local visual_provider = {
				task_item = function() end,
				task_preview = function() end,
				execution_item = function() end,
				execution_preview = function() end,
			}

			core.setup({
				sources = {
					{
						module = {
							create = function(opts)
								source_opts = opts
								return source_provider
							end,
						},
						opts = { source = true },
					},
				},
				picker = {
					module = {
						create = function(opts)
							picker_opts = opts
							return picker_provider
						end,
					},
					opts = { picker = true },
				},
				runner = {
					module = {
						create = function(opts)
							runner_opts = opts
							return runner_provider
						end,
					},
					opts = { runner = true },
				},
				visual = {
					module = {
						create = function(opts)
							visual_opts = opts
							return visual_provider
						end,
					},
					opts = { visual = true },
				},
			})

			h.same({ source = true }, source_opts)
			h.same({ picker = true }, picker_opts)
			h.same({ runner = true }, runner_opts)
			h.same({ visual = true }, visual_opts)
			h.same({ source_provider }, state.sourceProviders)
			h.same(picker_provider, state.pickerProvider)
			h.same(runner_provider, state.runnerProvider)
			h.same(visual_provider, state.visualProvider)
		end,
	},
	{
		name = "core.setup replaces source providers",
		fn = function()
			reset_state()

			local function setup_with(source)
				core.setup({
					sources = {
						{
							module = {
								create = function()
									return source
								end,
							},
						},
					},
					picker = {
						module = {
							create = function()
								return { name = "picker", pick_task = function() end }
							end,
						},
					},
					runner = {
						module = {
							create = function()
								return { name = "runner", start = function() end }
							end,
						},
					},
				})
			end

			local first = { name = "first", collect = function() end }
			local second = { name = "second", collect = function() end }

			setup_with(first)
			setup_with(second)

			h.same({ second }, state.sourceProviders)
		end,
	},
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
			state.visualProvider = require("kyme.provider.visual.default").create()
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

				h.same(state.executions["1"], picked[1].execution)
				h.truthy(picked[1].visual)
				h.truthy(picked[1].preview)
				h.same(true, open_called)
				h.same(true, stop_called)
			end)
		end,
	},
}
