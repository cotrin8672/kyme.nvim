local M = {}

---@param command string[]
---@return string
local function command_text(command)
	return table.concat(command, " ")
end

---@param task kyme.Task
---@return string
local function preview_text(task)
	local lines = {
		("# %s"):format(task.name),
		"",
	}

	if task.desc and task.desc ~= "" then
		vim.list_extend(lines, {
			"## Description",
			task.desc,
			"",
		})
	end

	vim.list_extend(lines, {
		"## Command",
		"```sh",
		command_text(task.command),
		"```",
	})

	if task.preview and task.preview.lines and #task.preview.lines > 0 then
		vim.list_extend(lines, {
			"",
			"## Details",
		})
		vim.list_extend(lines, task.preview.lines)
	end

	return table.concat(lines, "\n")
end

---@param task kyme.Task
---@return table
local function to_item(task)
	local source = task.source and task.source.provider or ""
	local text = source ~= "" and ("%s: %s"):format(source, task.name) or task.name

	return {
		text = text,
		task = task,
		preview = {
			text = preview_text(task),
			ft = "markdown",
		},
	}
end

---@param item table
---@return kyme.Task?
local function item_task(item)
	return item and item.task or nil
end

---@param picker table
---@param item table?
---@param done fun(result?: kyme.PickerResult)
local function confirm(picker, item, done)
	local selected = picker:selected({ fallback = true })
	local tasks = {}

	for _, selected_item in ipairs(selected) do
		local task = item_task(selected_item)
		if task then
			table.insert(tasks, task)
		end
	end

	if #tasks == 0 then
		local task = item_task(item)
		if task then
			table.insert(tasks, task)
		end
	end

	picker:close()
	done(#tasks > 0 and { tasks = tasks } or nil)
end

---@param spec kyme.ProviderSpec<kyme.PickerProvider>
---@return kyme.PickerProvider
function M.create(spec)
	local opts = spec.opts or {}

	return {
		name = spec[1],

		---@param tasks kyme.Task[]
		---@param done fun(result?: kyme.PickerResult)
		pick = function(tasks, done)
			local items = vim.tbl_map(to_item, tasks)

			Snacks.picker(vim.tbl_deep_extend("force", {
				title = opts.title or "Kyme Tasks",
				items = items,
				format = "text",
				preview = "preview",
				confirm = function(picker, item)
					confirm(picker, item, done)
				end,
			}, opts.picker or {}))
		end,
	}
end

return M
