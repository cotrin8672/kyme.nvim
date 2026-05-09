local M = {}

---@type kyme.Task[]
M.tasks = {}

---@type kyme.SourceProvider[]
M.sourceProviders = {}

---@type kyme.PickerProvider
M.pickerProvider = nil

---@type kyme.RunnerProvider
M.runnerProvider = nil

return M
