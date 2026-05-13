--- Task definition
---@class kyme.Task
---@field id string
---@field name string
---@field desc? string
---@field command string[] argv-style command
---@field source? kyme.TaskSource

---@class kyme.TaskSource
---@field name string
---@field path? string
---@field line? integer

--- Execution definition
---@class kyme.Execution
---@field id string
---@field task kyme.Task
---@field ctx kyme.ExecutionCtx
---@field status kyme.ExecutionStatus
---@field handle? kyme.ExecutionHandle
---@field started_at integer
---@field ended_at? integer
---@field exit_code? integer

---@class kyme.ExecutionCtx
---@field cwd string
---@field bufnr? integer

---@class kyme.ExecutionHandle
---@field open fun()
---@field stop fun()

---@alias kyme.ExecutionStatus
---| "running"
---| "succeeded"
---| "failed"
---| "stopping"
---| "stopped"

---@class kyme.AdapterBase

---@class kyme.SourceAdapter
---@field collect fun(): kyme.Task[]

---@class kyme.RunnerAdapter
---@field run fun(task: kyme.Task, hooks: kyme.RunnerHooks): kyme.Execution

---@class kyme.PickerAdapter
---@field pick_task fun(tasks: kyme.Task[]): kyme.Task
---@field pick_execution fun(executions: kyme.Execution[]): kyme.Execution

---@class kyme.ProviderBase

---@class kyme.SourceProvider: kyme.ProviderBase
---@field collect fun(): kyme.Task[]

---@class kyme.RunnerProvider: kyme.ProviderBase
---@field start fun(task: kyme.Task, ctx: kyme.ExecutionCtx, hooks: kyme.RunnerHooks): kyme.ExecutionHandle

---@class kyme.RunnerHooks
---@field on_exit fun(code: integer)

---@class kyme.PickerProvider: kyme.ProviderBase

---@class kyme.ProviderModule<T>
---@field create fun(opts?: table): T

---@class kyme.ProviderFactory<T>
---@field module kyme.ProviderModule<T>
---@field opts? table

---@class kyme.Config
---@field sources kyme.ProviderFactory<kyme.SourceProvider>[]
---@field picker kyme.ProviderFactory<kyme.PickerProvider>?
---@field runner kyme.ProviderFactory<kyme.RunnerProvider>?
