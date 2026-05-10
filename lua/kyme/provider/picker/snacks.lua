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

local source_icons = {
	mise = "󰦕",
}

local status_hl = {
	running = "DiagnosticInfo",
	succeeded = "DiagnosticOk",
	failed = "DiagnosticError",
	stopped = "DiagnosticWarn",
}

---@param source string
---@param name string
---@return string
local function task_text(source, name)
	if source == "" then
		return name
	end

	local text = ("%s: %s"):format(source, name)
	local icon = source_icons[source]

	return icon and ("%s %s"):format(icon, text) or text
end

---@param task kyme.Task
---@return table
local function to_item(task)
	local source = task.source and task.source.provider or ""
	local text = task_text(source, task.name)

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

---@param execution kyme.Execution
---@return string
local function execution_preview_text(execution)
	local lines = {
		("# %s"):format(execution.task.name),
		"",
		"## Execution",
		("- ID: %s"):format(execution.id),
		("- Status: %s"):format(execution.status),
		("- Exit code: %s"):format(execution.exit_code ~= nil and tostring(execution.exit_code) or "-"),
		"",
		"## Command",
		"```sh",
		command_text(execution.task.command),
		"```",
	}

	return table.concat(lines, "\n")
end

---@param execution kyme.Execution
---@return table
local function to_execution_item(execution)
	return {
		text = ("#%s %s"):format(execution.id, execution.task.name),
		execution_id = execution.id,
		execution = execution,
		preview = {
			text = execution_preview_text(execution),
			ft = "markdown",
		},
	}
end

---@param item table
---@return table[]
local function execution_format(item)
	local execution = item.execution
	local source = execution.task.source and execution.task.source.provider or ""
	local icon = source_icons[source]
	local icon_hl = status_hl[execution.status] or "Special"
	local ret = {}

	if icon then
		ret[#ret + 1] = { icon, icon_hl }
		ret[#ret + 1] = { " " }
	end

	ret[#ret + 1] = { ("#%s "):format(execution.id), "SnacksPickerIdx" }
	ret[#ret + 1] = { execution.task.name }

	return ret
end

---@param item table
---@return string?
local function item_execution_id(item)
	return item and item.execution_id or nil
end

---@param picker table
---@param item table?
---@param done fun(result?: kyme.PickerResult)
local function confirm_task(picker, item, done)
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

---@param picker table
---@param item table?
---@param actions kyme.ExecutionPickerActions
local function confirm_execution(picker, item, actions)
	local execution_id = item_execution_id(item)

	picker:close()

	if execution_id then
		vim.schedule(function()
			actions.open(execution_id)
		end)
	end
end

---@param picker table
---@param item table?
---@param actions kyme.ExecutionPickerActions
local function stop_execution(picker, item, actions)
	local selected = picker:selected({ fallback = true })
	local stopped = {}

	for _, selected_item in ipairs(selected) do
		local execution_id = item_execution_id(selected_item)
		if execution_id and not stopped[execution_id] then
			stopped[execution_id] = true
			actions.stop(execution_id)
		end
	end

	if not next(stopped) then
		local execution_id = item_execution_id(item)
		if execution_id then
			actions.stop(execution_id)
		end
	end
end

---@param opts table
---@return string
local function execution_stop_key(opts)
	return opts.execution_stop_key or "<M-s>"
end

---@param tasks kyme.Task[]
---@param done fun(result?: kyme.PickerResult)
---@param opts table
---@return table
local function task_picker_source(tasks, done, opts)
	return vim.tbl_deep_extend("force", {
		source = "kyme_tasks",
		title = opts.title or "Kyme Tasks",
		items = vim.tbl_map(to_item, tasks),
		format = "text",
		preview = "preview",
		confirm = function(picker, item)
			confirm_task(picker, item, done)
		end,
	}, opts.picker or {})
end

---@param executions kyme.Execution[]
---@param actions kyme.ExecutionPickerActions
---@param opts table
---@return table
local function execution_picker_source(executions, actions, opts)
	local stop_key = execution_stop_key(opts)

	return vim.tbl_deep_extend("force", {
		source = "kyme_executions",
		title = opts.execution_title or "Kyme Executions",
		items = vim.tbl_map(to_execution_item, executions),
		format = execution_format,
		preview = "preview",
		confirm = function(picker, item)
			confirm_execution(picker, item, actions)
		end,
		actions = {
			stop_execution = function(picker, item)
				stop_execution(picker, item, actions)
			end,
		},
		win = {
			input = {
				keys = {
					[stop_key] = { "stop_execution", mode = { "n", "i" } },
				},
			},
			list = {
				keys = {
					[stop_key] = "stop_execution",
				},
			},
		},
	}, opts.execution_picker or {})
end

---@param opts? table
---@return kyme.PickerProvider
function M.create(opts)
	opts = opts or {}

	return {
		name = "snacks",

		---@param tasks kyme.Task[]
		---@param done fun(result?: kyme.PickerResult)
		pick_task = function(tasks, done)
			Snacks.picker(task_picker_source(tasks, done, opts))
		end,

		---@param executions kyme.Execution[]
		---@param actions kyme.ExecutionPickerActions
		pick_execution = function(executions, actions)
			Snacks.picker(execution_picker_source(executions, actions, opts))
		end,
	}
end

return M
