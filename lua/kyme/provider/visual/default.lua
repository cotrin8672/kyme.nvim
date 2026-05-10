local M = {}

local source_icons = {
	mise = "\243\176\166\149",
}

local status_hl = {
	running = "DiagnosticInfo",
	succeeded = "DiagnosticOk",
	failed = "DiagnosticError",
	stopped = "DiagnosticWarn",
}

local function command_text(command)
	return table.concat(command, " ")
end

local function chunk(text, hl)
	return { text = text, hl = hl }
end

local function task_item(task)
	local source = task.source and task.source.provider or ""
	if source == "" then
		return { chunks = { chunk(task.name) } }
	end

	local icon = source_icons[source]
	local chunks = {}
	if icon then
		chunks[#chunks + 1] = chunk(icon .. " ")
	end
	chunks[#chunks + 1] = chunk(("%s: %s"):format(source, task.name))

	return {
		chunks = chunks,
	}
end

local function task_preview(task)
	local lines = {
		("# %s"):format(task.name),
		"",
	}

	if task.desc and task.desc ~= "" then
		vim.list_extend(lines, { "## Description", task.desc, "" })
	end

	vim.list_extend(lines, {
		"## Command",
		"```sh",
		command_text(task.command),
		"```",
	})

	return { lines = lines, ft = "markdown" }
end

local function execution_item(execution)
	local source = execution.task.source and execution.task.source.provider or ""
	local icon = source_icons[source]
	local chunks = {}

	if icon then
		chunks[#chunks + 1] = chunk(icon, status_hl[execution.status] or "Special")
		chunks[#chunks + 1] = chunk(" ")
	end

	chunks[#chunks + 1] = chunk(("#%s "):format(execution.id), "SnacksPickerIdx")
	chunks[#chunks + 1] = chunk(execution.task.name)
	return { chunks = chunks }
end

local function execution_preview(execution)
	return {
		lines = {
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
		},
		ft = "markdown",
	}
end

function M.create()
	return {
		task_item = task_item,
		task_preview = task_preview,
		execution_item = execution_item,
		execution_preview = execution_preview,
	}
end

return M
