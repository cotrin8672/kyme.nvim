local h = require("tests.helpers")

local function with_mise_system(result, fn)
	local original_system = vim.system
	local original_schedule = vim.schedule
	local original_notify = vim.notify
	local calls = {}
	local notifications = {}

	rawset(vim, "system", function(cmd, opts, on_exit)
		table.insert(calls, {
			cmd = cmd,
			opts = opts,
		})
		on_exit(result)
	end)

	rawset(vim, "schedule", function(callback)
		callback()
	end)

	rawset(vim, "notify", function(message, level)
		table.insert(notifications, {
			message = message,
			level = level,
		})
	end)

	local ok, err = pcall(fn, calls, notifications)

	rawset(vim, "system", original_system)
	rawset(vim, "schedule", original_schedule)
	rawset(vim, "notify", original_notify)

	if not ok then
		error(err, 0)
	end
end

local function collect(stdout)
	local provider = require("kyme.provider.source.mise").create()
	local collected

	with_mise_system({
		code = 0,
		stdout = stdout,
		stderr = "",
	}, function(calls)
		provider.collect(function(tasks)
			collected = tasks
		end)

		h.same({
			{
				cmd = { "mise", "tasks", "--json" },
				opts = { text = true },
			},
		}, calls, "mise provider should call mise tasks --json")
	end)

	return collected
end

return {
	{
		name = "mise source maps a task JSON item to a Kyme task",
		fn = function()
			local stdout = vim.json.encode({
				{
					name = "build",
					description = "Build project",
					source = "mise.toml",
					run = { "cargo build" },
				},
			})

			local tasks = collect(stdout)

			h.same(1, #tasks)
			h.same({
				id = "mise:build",
				name = "build",
				command = { "mise", "run", "build" },
				desc = "Build project",
				source = {
					provider = "mise",
					path = "mise.toml",
				},
				preview = {
					lines = { "cargo build" },
					ft = "sh",
				},
				metadata = {
					name = "build",
					description = "Build project",
					source = "mise.toml",
					run = { "cargo build" },
				},
			}, tasks[1])
		end,
	},
	{
		name = "mise source preserves multiple task order",
		fn = function()
			local stdout = vim.json.encode({
				{
					name = "build",
					run = { "cargo build" },
				},
				{
					name = "test",
					run = { "cargo test" },
				},
				{
					name = "lint",
					run = { "cargo clippy" },
				},
			})

			local tasks = collect(stdout)

			h.same(3, #tasks)
			h.same("build", tasks[1].name)
			h.same("test", tasks[2].name)
			h.same("lint", tasks[3].name)
			h.same({ "mise", "run", "build" }, tasks[1].command)
			h.same({ "mise", "run", "test" }, tasks[2].command)
			h.same({ "mise", "run", "lint" }, tasks[3].command)
		end,
	},
	{
		name = "mise source handles an empty task list",
		fn = function()
			local tasks = collect("[]")

			h.same({}, tasks)
		end,
	},
	{
		name = "mise source returns no tasks and notifies on command failure",
		fn = function()
			local provider = require("kyme.provider.source.mise").create()
			local collected

			with_mise_system({
				code = 1,
				stdout = "",
				stderr = "mise failed",
			}, function(_, notifications)
				provider.collect(function(tasks)
					collected = tasks
				end)

				h.same({}, collected)
				h.same({
					{
						message = "mise failed",
						level = vim.log.levels.ERROR,
					},
				}, notifications)
			end)
		end,
	},
}
