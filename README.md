# kyme.nvim

A small provider-based task runner for Neovim.

Kyme keeps the core thin: sources collect tasks, pickers let you choose one or more tasks, and runners execute the selected tasks.

日本語版: [README.ja.md](README.ja.md)

## Features

- Provider-based task collection, selection, and execution
- Built-in mise source provider
- Built-in snacks.nvim picker provider
- Built-in toggleterm.nvim runner provider
- argv-style task commands
- Markdown preview for task descriptions and commands

## Philosophy

Kyme is built as a configurable task runner with few core dependencies.

The core idea is to avoid hard-coding one picker, one terminal, or one task format into the plugin. Kyme defines provider interfaces for task collection, task selection, and task execution.

This means:

- Keep the core independent from optional UI and terminal plugins
- Let users use their own fuzzy finder through a picker provider
- Run tasks in the background
- Keep error parsing and quickfix integration outside the core runner flow
- Define a source provider interface so tasks from different formats can be added
- Keep window and status UI decisions outside the core

The current built-in providers are `mise` as a source, `snacks.nvim` as a picker, and `toggleterm.nvim` as a runner.

## Requirements

- Neovim 0.10+
- Optional providers:
  - mise for the built-in source provider
  - folke/snacks.nvim for the built-in picker provider
  - akinsho/toggleterm.nvim for the built-in runner provider

## Installation

With lazy.nvim:

~~~lua
{
  'cotrin8672/kyme.nvim',
  dependencies = {
    'folke/snacks.nvim',
    'akinsho/toggleterm.nvim',
  },
  opts = {
    sources = {
      { 'mise' },
    },
    picker = { 'snacks' },
    runner = { 'toggleterm' },
  },
  keys = {
    {
      '<leader>pt',
      function()
        require('kyme').pick()
      end,
      desc = 'Pick task',
    },
  },
}
~~~

## Usage

~~~lua
require('kyme').setup({
  sources = {
    { 'mise' },
  },
  picker = { 'snacks' },
  runner = { 'toggleterm' },
})

vim.keymap.set('n', '<leader>pt', function()
  require('kyme').pick()
end, { desc = 'Pick task' })
~~~

## Provider Model

Kyme has three provider types.

### SourceProvider

A source collects tasks and returns them asynchronously.

~~~lua
---@class kyme.SourceProvider
---@field name string
---@field collect fun(done: fun(tasks: kyme.Task[]))
~~~

### PickerProvider

A picker selects one or more tasks.

~~~lua
---@class kyme.PickerProvider
---@field name string
---@field pick fun(tasks: kyme.Task[], done: fun(result?: kyme.PickerResult))
~~~

### RunnerProvider

A runner executes a selected task.

~~~lua
---@class kyme.RunnerProvider
---@field name string
---@field execute fun(task: kyme.Task, ctx: kyme.ExecutionCtx)
~~~

## Task Shape

~~~lua
---@class kyme.Task
---@field id string
---@field name string
---@field command string[] argv-style command
---@field desc? string
---@field source? kyme.TaskSource
---@field preview? kyme.TaskPreview
---@field tags? string[]
---@field metadata? table
~~~

command is always argv-style. Providers should prefer structured commands like:

~~~lua
{ 'mise', 'run', 'build' }
~~~

instead of shell strings.

## Built-in Providers

### mise Source

Collects tasks from:

~~~sh
mise tasks --json
~~~

### snacks Picker

Shows tasks with snacks.nvim. Items are displayed as:

~~~text
mise: task-name
~~~

The preview shows the task description and command in Markdown.

### toggleterm Runner

Runs tasks through toggleterm.nvim without opening the terminal window immediately. It sends a notification when a task starts.

## TODO

These items are still rough roadmap notes and may change as the plugin evolves.

- Manage running tasks through the same provider-oriented model
- Expand CI and automated test coverage
- Add hooks for task lifecycle events such as start, completion, and failure
- Split preview generation into a more independent provider interface
