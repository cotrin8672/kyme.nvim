local h = require("tests.helpers")

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

return {
	{
		name = "snacks picker prefixes mise tasks with icon",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create({ "snacks" })

			with_snacks_picker(function(captured)
				provider.pick_task({
					{
						id = "mise:build",
						name = "build",
						command = { "mise", "run", "build" },
						source = {
							provider = "mise",
						},
					},
				}, function() end)

				h.same("󰦕 mise: build", captured().items[1].text)
			end)
		end,
	},
	{
		name = "snacks picker keeps non-mise source labels unchanged",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create({ "snacks" })

			with_snacks_picker(function(captured)
				provider.pick_task({
					{
						id = "pnpm:test",
						name = "test",
						command = { "pnpm", "test" },
						source = {
							provider = "pnpm",
						},
					},
				}, function() end)

				h.same("pnpm: test", captured().items[1].text)
			end)
		end,
	},
	{
		name = "snacks picker keeps tasks without source unchanged",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create({ "snacks" })

			with_snacks_picker(function(captured)
				provider.pick_task({
					{
						id = "custom",
						name = "custom",
						command = { "echo", "custom" },
					},
				}, function() end)

				h.same("custom", captured().items[1].text)
			end)
		end,
	},
	{
		name = "snacks execution picker prefixes mise icon and highlights status",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create({ "snacks" })

			with_snacks_picker(function(captured)
				provider.pick_execution({
					{
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
					},
				}, {
					open = function() end,
					stop = function() end,
				})

				local item = captured().items[1]
				h.same("#1 [running] build", item.text)
				h.same({
					{ "󰦕", "Special" },
					{ " " },
					{ "#1 ", "SnacksPickerIdx" },
					{ "[running] ", "DiagnosticInfo" },
					{ "build" },
				}, captured().format(item))
			end)
		end,
	},
	{
		name = "snacks execution picker maps terminal statuses to highlights",
		fn = function()
			local provider = require("kyme.provider.picker.snacks").create({ "snacks" })

			with_snacks_picker(function(captured)
				provider.pick_execution({
					{
						id = "1",
						status = "succeeded",
						task = { id = "test:ok", name = "ok", command = { "echo", "ok" } },
					},
					{
						id = "2",
						status = "failed",
						task = { id = "test:fail", name = "fail", command = { "false" } },
					},
					{
						id = "3",
						status = "stopped",
						task = { id = "test:stop", name = "stop", command = { "sleep", "10" } },
					},
				}, {
					open = function() end,
					stop = function() end,
				})

				local opts = captured()
				h.same("[succeeded] ", opts.format(opts.items[1])[2][1])
				h.same("DiagnosticOk", opts.format(opts.items[1])[2][2])
				h.same("[failed] ", opts.format(opts.items[2])[2][1])
				h.same("DiagnosticError", opts.format(opts.items[2])[2][2])
				h.same("[stopped] ", opts.format(opts.items[3])[2][1])
				h.same("DiagnosticWarn", opts.format(opts.items[3])[2][2])
			end)
		end,
	},
}
