local h = require("tests.helpers")
local visual = require("kyme.provider.visual.default").create()

local function with_snacks_picker(fn)
	local original_snacks = rawget(_G, "Snacks")
	local captured

	rawset(_G, "Snacks", {
		picker = function(opts)
			captured = opts
		end,
	})

	local ok, err = pcall(fn, function()
		return captured
	end)

	rawset(_G, "Snacks", original_snacks)

	if not ok then
		error(err, 0)
	end
end

local function execution(id)
	return {
		id = id,
		status = "running",
		task = {
			id = "test:" .. id,
			name = "task-" .. id,
			command = { "echo", id },
		},
	}
end

local function task_item(task)
	return {
		task = task,
		visual = visual.task_item(task),
		preview = visual.task_preview(task),
	}
end

local function execution_item(item)
	return {
		execution = item,
		visual = visual.execution_item(item),
		preview = visual.execution_preview(item),
	}
end

return {
	{
		name = "snacks picker prefixes mise tasks with icon",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()

			with_snacks_picker(function(captured)
				provider.pick_task({
					task_item({
						id = "mise:build",
						name = "build",
						command = { "mise", "run", "build" },
						source = {
							provider = "mise",
						},
					}),
				}, function() end)

				h.same("󰦕 mise: build", captured().items[1].text)
			end)
		end,
	},
	{
		name = "snacks task picker uses kyme task source config",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()

			with_snacks_picker(function(captured)
				provider.pick_task({
					task_item({
						id = "custom",
						name = "custom",
						command = { "echo", "custom" },
					}),
				}, function() end)

				h.same("kyme_tasks", captured().source)
				h.truthy(captured().format)
				h.same("preview", captured().preview)
				h.truthy(captured().confirm)
			end)
		end,
	},
	{
		name = "snacks picker keeps non-mise source labels unchanged",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()

			with_snacks_picker(function(captured)
				provider.pick_task({
					task_item({
						id = "pnpm:test",
						name = "test",
						command = { "pnpm", "test" },
						source = {
							provider = "pnpm",
						},
					}),
				}, function() end)

				h.same("pnpm: test", captured().items[1].text)
			end)
		end,
	},
	{
		name = "snacks picker keeps tasks without source unchanged",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()

			with_snacks_picker(function(captured)
				provider.pick_task({
					task_item({
						id = "custom",
						name = "custom",
						command = { "echo", "custom" },
					}),
				}, function() end)

				h.same("custom", captured().items[1].text)
			end)
		end,
	},
	{
		name = "snacks execution picker prefixes mise icon and colors it by status",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()

			with_snacks_picker(function(captured)
				provider.pick_execution({
					execution_item({
						id = "1",
						status = "running",
						task = {
							id = "mise:build",
							name = "build",
							command = { "mise", "run", "build" },
							source = {
								provider = "mise",
							},
						},
					}),
				}, {
					open = function() end,
					stop = function() end,
				})

				local item = captured().items[1]
				h.same("\243\176\166\149 #1 build", item.text)
				h.same({
					{ "󰦕", "DiagnosticInfo" },
					{ " " },
					{ "#1 ", "SnacksPickerIdx" },
					{ "build" },
				}, captured().format(item))
			end)
		end,
	},
	{
		name = "snacks execution picker uses kyme execution source config",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()

			with_snacks_picker(function(captured)
				provider.pick_execution({
					execution_item(execution("1")),
				}, {
					open = function() end,
					stop = function() end,
				})

				h.same("kyme_executions", captured().source)
				h.same("preview", captured().preview)
				h.truthy(captured().format)
				h.truthy(captured().confirm)
				h.truthy(captured().actions.stop_execution)
			end)
		end,
	},
	{
		name = "snacks execution picker maps terminal statuses to icon highlights",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()

			with_snacks_picker(function(captured)
				provider.pick_execution({
					execution_item({
						id = "1",
						status = "succeeded",
						task = {
							id = "mise:ok",
							name = "ok",
							command = { "mise", "run", "ok" },
							source = { provider = "mise" },
						},
					}),
					execution_item({
						id = "2",
						status = "failed",
						task = {
							id = "mise:fail",
							name = "fail",
							command = { "mise", "run", "fail" },
							source = { provider = "mise" },
						},
					}),
					execution_item({
						id = "3",
						status = "stopped",
						task = {
							id = "mise:stop",
							name = "stop",
							command = { "mise", "run", "stop" },
							source = { provider = "mise" },
						},
					}),
				}, {
					open = function() end,
					stop = function() end,
				})

				local opts = captured()
				h.same("DiagnosticOk", opts.format(opts.items[1])[1][2])
				h.same("DiagnosticError", opts.format(opts.items[2])[1][2])
				h.same("DiagnosticWarn", opts.format(opts.items[3])[1][2])
			end)
		end,
	},
	{
		name = "snacks execution picker uses meta-s as default stop key",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()

			with_snacks_picker(function(captured)
				provider.pick_execution({
					execution_item({
						id = "1",
						status = "running",
						task = { id = "test:ok", name = "ok", command = { "echo", "ok" } },
					}),
				}, {
					open = function() end,
					stop = function() end,
				})

				h.same({ "stop_execution", mode = { "n", "i" } }, captured().win.input.keys["<M-s>"])
				h.same("stop_execution", captured().win.list.keys["<M-s>"])
				h.same(nil, captured().win.input.keys.s)
				h.same(nil, captured().win.list.keys.s)
			end)
		end,
	},
	{
		name = "snacks execution picker allows custom stop key",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create({
				execution_stop_key = "<C-s>",
			})

			with_snacks_picker(function(captured)
				provider.pick_execution({
					execution_item({
						id = "1",
						status = "running",
						task = { id = "test:ok", name = "ok", command = { "echo", "ok" } },
					}),
				}, {
					open = function() end,
					stop = function() end,
				})

				h.same({ "stop_execution", mode = { "n", "i" } }, captured().win.input.keys["<C-s>"])
				h.same("stop_execution", captured().win.list.keys["<C-s>"])
				h.same(nil, captured().win.input.keys["<M-s>"])
				h.same(nil, captured().win.list.keys["<M-s>"])
			end)
		end,
	},
	{
		name = "snacks execution picker stops selected executions",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()
			local stopped = {}

			with_snacks_picker(function(captured)
				provider.pick_execution({
					execution_item(execution("1")),
					execution_item(execution("2")),
					execution_item(execution("3")),
				}, {
					open = function() end,
					stop = function(execution_id)
						table.insert(stopped, execution_id)
					end,
				})

				local opts = captured()
				local picker = {
					selected = function()
						return { opts.items[1], opts.items[3], opts.items[3] }
					end,
				}

				opts.actions.stop_execution(picker, opts.items[2])

				h.same({ "1", "3" }, stopped)
			end)
		end,
	},
	{
		name = "snacks execution picker stop action falls back to current item",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create()
			local stopped = {}

			with_snacks_picker(function(captured)
				provider.pick_execution({
					execution_item(execution("1")),
					execution_item(execution("2")),
				}, {
					open = function() end,
					stop = function(execution_id)
						table.insert(stopped, execution_id)
					end,
				})

				local opts = captured()
				local picker = {
					selected = function()
						return {}
					end,
				}

				opts.actions.stop_execution(picker, opts.items[2])

				h.same({ "2" }, stopped)
			end)
		end,
	},
}
