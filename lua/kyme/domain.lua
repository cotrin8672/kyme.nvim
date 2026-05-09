---@class kyme.Task
---@field id string
---@field name string
---@field command string[] argv-style command
---@field desc? string
---@field source? kyme.TaskSource
---@field preview? kyme.TaskPreview
---@field tags? string[]
---@field metadata? table

---@class kyme.TaskSource
---@field provider string
---@field path? string
---@field line? integer

---@class kyme.TaskPreview
---@field lines? string[]
---@field ft? string

---@class kyme.ProviderBase
---@field name string

---@class kyme.SourceProvider: kyme.ProviderBase
---@field collect fun(done: fun(tasks: kyme.Task[]))

---@class kyme.ExecutionCtx
---@field cwd string
---@field bufnr integer
---@field winid integer

---@class kyme.RunnerProvider: kyme.ProviderBase
---@field start fun(task: kyme.Task, ctx: kyme.ExecutionCtx, hooks: kyme.RunnerHooks): kyme.ExecutionHandle

---@class kyme.RunnerHooks
---@field on_exit fun(code: integer)

---@class kyme.PickerProvider: kyme.ProviderBase
---@field pick_task fun(tasks: kyme.Task[], done: fun(result?: kyme.PickerResult))
---@field pick_execution? fun(executions: kyme.Execution[], actions: kyme.ExecutionPickerActions)

---@class kyme.ExecutionPickerActions
---@field open fun(id: string)
---@field stop fun(id: string)

---@class kyme.PickerResult
---@field tasks kyme.Task[]

---@class kyme.ProviderModule<T>
---@field create fun(spec: kyme.ProviderSpec<T>): T

---@class kyme.ProviderSpec<T>
---@field [1] string
---@field opts? table
---@field module? string

---@class kyme.Execution
---@field id string
---@field task kyme.Task
---@field status kyme.ExecutionStatus
---@field started_at integer
---@field ended_at? integer
---@field exit_code? integer
---@field _handle? kyme.ExecutionHandle
---@field _stopping? boolean

---@alias kyme.ExecutionStatus
---| "running"
---| "succeeded"
---| "failed"
---| "stopped"

---@class kyme.ExecutionHandle
---@field open? fun()
---@field stop? fun()

---@class kyme.Config
---@field sources kyme.ProviderSpec<kyme.SourceProvider>[]
---@field picker kyme.ProviderSpec<kyme.PickerProvider>?
---@field runner kyme.ProviderSpec<kyme.RunnerProvider>?
