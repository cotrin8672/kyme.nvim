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
---@field execute fun(task: kyme.Task, ctx: kyme.ExecutionCtx)

---@class kyme.PickerProvider: kyme.ProviderBase
---@field pick fun(tasks: kyme.Task[], done: fun(result?: kyme.PickerResult))

---@class kyme.PickerResult
---@field tasks kyme.Task[]

---@class kyme.ProviderModule<T>
---@field create fun(spec: kyme.ProviderSpec<T>): T

---@class kyme.ProviderSpec<T>
---@field [1] string
---@field opts? table
---@field module? string

---@class kyme.Config
---@field sources kyme.ProviderSpec<kyme.SourceProvider>[]
---@field picker kyme.ProviderSpec<kyme.PickerProvider>?
---@field runner kyme.ProviderSpec<kyme.RunnerProvider>?
