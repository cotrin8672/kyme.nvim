---@class kyme.Task
---@field id string
---@field name string
---@field desc? string
---@field command string[] argv-style command
---@field source? kyme.TaskSource

---@class kyme.TaskSource
---@field provider string
---@field path? string
---@field line? integer

---@class kyme.ProviderBase

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
---@field pick_task fun(items: kyme.PickerTaskItem[], done: fun(result?: kyme.PickerResult))
---@field pick_execution? fun(items: kyme.PickerExecutionItem[], actions: kyme.ExecutionPickerActions)

---@class kyme.VisualProvider: kyme.ProviderBase
---@field task_item fun(task: kyme.Task): kyme.VisualItem
---@field task_preview fun(task: kyme.Task): kyme.VisualPreview?
---@field execution_item fun(task: kyme.Execution): kyme.VisualItem
---@field execution_preview fun(task: kyme.Execution): kyme.VisualPreview?

---@class kyme.VisualItem
---@field chunks kyme.VisualChunk[]

---@class kyme.VisualChunk
---@field text string
---@field hl? string

---@class kyme.VisualPreview
---@field lines string[]
---@field ft? string

---@class kyme.PickerTaskItem
---@field task kyme.Task
---@field visual kyme.VisualItem
---@field preview? kyme.VisualPreview

---@class kyme.PickerExecutionItem
---@field execution kyme.Execution
---@field visual kyme.VisualItem
---@field preview? kyme.VisualPreview

---@class kyme.ExecutionPickerActions
---@field open fun(id: string)
---@field stop fun(id: string)

---@class kyme.PickerResult
---@field tasks kyme.Task[]

---@class kyme.ProviderModule<T>
---@field create fun(opts?: table): T

---@class kyme.ProviderFactory<T>
---@field module kyme.ProviderModule<T>
---@field opts? table

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
---@field sources kyme.ProviderFactory<kyme.SourceProvider>[]
---@field picker kyme.ProviderFactory<kyme.PickerProvider>?
---@field runner kyme.ProviderFactory<kyme.RunnerProvider>?
---@field visual kyme.ProviderFactory<kyme.VisualProvider>?
