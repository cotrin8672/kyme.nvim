local M = {}

---@param item table
---@return kyme.Task
local function to_task(item)
	return {
		id = "mise:" .. item.name,
		name = item.name,
		command = { "mise", "run", item.name },
		desc = item.description,
		source = {
			provider = "mise",
			path = item.source,
		},
		preview = {
			lines = item.run,
			ft = "sh",
		},
		metadata = item,
	}
end

---@param stdout string
---@return kyme.Task[]
local function parse(stdout)
	local decoded = vim.json.decode(stdout)
	local tasks = {}

	for _, item in ipairs(decoded) do
		table.insert(tasks, to_task(item))
	end

	return tasks
end

---@param spec kyme.ProviderSpec<kyme.SourceProvider>
---@return kyme.SourceProvider
function M.create(spec)
	return {
		name = spec[1],

		---@param done fun(tasks: kyme.Task[])
		collect = function(done)
			vim.system({ "mise", "tasks", "--json" }, { text = true }, function(result)
				if result.code ~= 0 then
					vim.schedule(function()
						vim.notify(result.stderr, vim.log.levels.ERROR)
						done({})
					end)
					return
				end

				local tasks = parse(result.stdout)
				vim.schedule(function()
					done(tasks)
				end)
			end)
		end,
	}
end

return M
