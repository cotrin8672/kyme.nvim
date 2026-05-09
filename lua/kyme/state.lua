local M = {}

---@type kyme.Task[]
M.tasks = {}

---@type kyme.SourceProvider[]
M.sourceProviders = {}

---@type kyme.PickerProvider
M.pickerProvider = nil

---@type kyme.RunnerProvider
M.runnerProvider = nil

---@type table<string, kyme.Execution>
M.executions = {}

---@type string[]
M.execution_order = {}

---@type integer
M.next_execution_id = 0

return M
