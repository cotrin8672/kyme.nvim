local M = {}

---@param chunks kyme.VisualChunk[]
---@return string
local function chunks_text(chunks)
	local parts = {}

	for _, chunk in ipairs(chunks) do
		parts[#parts + 1] = chunk.text
	end

	return table.concat(parts)
end

---@param preview? kyme.VisualPreview
---@return table?
local function to_preview(preview)
	if not preview then
		return nil
	end

	return {
		text = table.concat(preview.lines, "\n"),
		ft = preview.ft,
	}
end

---@param item kyme.PickerTaskItem
---@return table
local function to_item(item)
	return {
		text = chunks_text(item.visual.chunks),
		task = item.task,
		visual = item.visual,
		preview = to_preview(item.preview),
	}
end

---@param item table
---@return kyme.Task?
local function item_task(item)
	return item and item.task or nil
end

---@param item kyme.PickerExecutionItem
---@return table
local function to_execution_item(item)
	return {
		text = chunks_text(item.visual.chunks),
		execution_id = item.execution.id,
		execution = item.execution,
		visual = item.visual,
		preview = to_preview(item.preview),
	}
end

---@param item table
---@return table[]
local function item_format(item)
	local ret = {}

	for _, chunk in ipairs(item.visual.chunks) do
		if chunk.hl then
			ret[#ret + 1] = { chunk.text, chunk.hl }
		else
			ret[#ret + 1] = { chunk.text }
		end
	end

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

---@param items kyme.PickerTaskItem[]
---@param done fun(result?: kyme.PickerResult)
---@param opts table
---@return table
local function task_picker_source(items, done, opts)
	return vim.tbl_deep_extend("force", {
		source = "kyme_tasks",
		title = opts.title or "Kyme Tasks",
		items = vim.tbl_map(to_item, items),
		format = item_format,
		preview = "preview",
		confirm = function(picker, item)
			confirm_task(picker, item, done)
		end,
	}, opts.picker or {})
end

---@param items kyme.PickerExecutionItem[]
---@param actions kyme.ExecutionPickerActions
---@param opts table
---@return table
local function execution_picker_source(items, actions, opts)
	local stop_key = execution_stop_key(opts)

	return vim.tbl_deep_extend("force", {
		source = "kyme_executions",
		title = opts.execution_title or "Kyme Executions",
		items = vim.tbl_map(to_execution_item, items),
		format = item_format,
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
		---@param items kyme.PickerTaskItem[]
		---@param done fun(result?: kyme.PickerResult)
		pick_task = function(items, done)
			Snacks.picker(task_picker_source(items, done, opts))
		end,

		---@param items kyme.PickerExecutionItem[]
		---@param actions kyme.ExecutionPickerActions
		pick_execution = function(items, actions)
			Snacks.picker(execution_picker_source(items, actions, opts))
		end,
	}
end

return M
