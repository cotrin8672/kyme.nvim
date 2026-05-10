# kyme.nvim

Neovim 向けの、小さな provider ベースのタスクランナープラグインです。

Kyme は core を薄く保ちます。source がタスクを集め、picker がタスクを選ばせ、runner が選ばれたタスクを実行します。

English: [README.md](README.md)

## 特徴

- provider ベースのタスク収集、選択、実行
- 組み込みの mise source provider
- 組み込みの snacks.nvim picker provider
- 組み込みの toggleterm.nvim runner provider
- argv 形式のタスクコマンド
- タスク説明とコマンドの Markdown preview

## 設計思想

Kyme は、依存を少なく保ちつつ、設定可能なタスクランナーを目指しています。

Kyme は特定の picker、terminal、task format を core に固定せず、タスク収集、タスク選択、タスク実行の provider interface を定義します。

基本方針は次の通りです。

- 特定の UI / terminal プラグインに core を依存させない
- タスク選択は picker provider を通してユーザー各位の fuzzy finder に委ねる
- タスクはバックグラウンドで実行する
- エラー parse や quickfix 連携を core の実行フローに固定しない
- タスクを追加する source provider interface を定義し、複数の task format を取り込めるようにする
- window や状態表示の判断を core から分離する

現在の組み込み provider は、`mise` source、`snacks.nvim` picker、`toggleterm.nvim` runner です。

Kyme は小さな execution registry を持ち、バックグラウンドタスクを picker provider 経由で一覧表示、open、stop できます。エラー parse、quickfix 連携、より高度な状態 UI は core の実行フローには固定していません。

## 必要要件

- Neovim 0.10+
- 任意 provider:
  - 組み込み source provider 用の mise
  - 組み込み picker provider 用の folke/snacks.nvim
  - 組み込み runner provider 用の akinsho/toggleterm.nvim

## インストール

lazy.nvim の例:

```lua
{
  'cotrin8672/kyme.nvim',
  dependencies = {
    'folke/snacks.nvim',
    'akinsho/toggleterm.nvim',
  },
  opts = function()
    local kyme = require('kyme')

    return {
      sources = {
        kyme.mise(),
      },
      picker = kyme.snacks(),
      runner = kyme.toggleterm(),
    }
  end,
  keys = {
    {
      '<leader>pt',
      function()
        require('kyme').pick_task()
      end,
      desc = 'Pick task',
    },
  },
}
```

## 使い方

```lua
local kyme = require('kyme')

kyme.setup({
  sources = {
    kyme.mise(),
  },
  picker = kyme.snacks(),
  runner = kyme.toggleterm(),
})

vim.keymap.set('n', '<leader>pt', function()
  kyme.pick_task()
end, { desc = 'Pick task' })
```

## Provider Model

Kyme には 4 種類の provider があります。

### SourceProvider

source はタスクを非同期に収集します。

```lua
---@class kyme.SourceProvider
---@field collect fun(done: fun(tasks: kyme.Task[]))
```

### PickerProvider

picker は 1 つ以上のタスクを選択します。

```lua
---@class kyme.PickerProvider
---@field pick_task fun(items: kyme.PickerTaskItem[], done: fun(result?: kyme.PickerResult))
---@field pick_execution? fun(items: kyme.PickerExecutionItem[], actions: kyme.ExecutionPickerActions)
```

### VisualProvider

visual provider は task / execution を picker の label と preview に変換します。

```lua
---@class kyme.VisualProvider
---@field task_item fun(task: kyme.Task): kyme.VisualItem
---@field task_preview fun(task: kyme.Task): kyme.VisualPreview?
---@field execution_item fun(execution: kyme.Execution): kyme.VisualItem
---@field execution_preview fun(execution: kyme.Execution): kyme.VisualPreview?
```

### RunnerProvider

runner は選択されたタスクを実行します。

```lua
---@class kyme.RunnerProvider
---@field start fun(task: kyme.Task, ctx: kyme.ExecutionCtx, hooks: kyme.RunnerHooks): kyme.ExecutionHandle
```

## Task Shape

```lua
---@class kyme.Task
---@field id string
---@field name string
---@field command string[] argv-style command
---@field desc? string
---@field source? kyme.TaskSource
```

`command` は常に argv 形式です。provider は shell string ではなく、次のような構造化された command を返すことを推奨します。

```lua
{ 'mise', 'run', 'build' }
```

## 組み込み Provider

### mise Source

次のコマンドからタスクを収集します。

```sh
mise tasks --json
```

### snacks Picker

snacks.nvim でタスクを表示します。item は次の形式で表示されます。

```text
󰦕 mise: task-name
```

preview にはタスクの説明と command が Markdown で表示されます。

execution picker の stop key はデフォルトで `<M-s>` です。複数選択されている場合は選択中の execution をすべて止め、未選択の場合は現在 item に fallback します。次のように変更できます。

```lua
picker = require('kyme').snacks({
  execution_stop_key = '<C-s>',
})
```

### toggleterm Runner

toggleterm.nvim を使って、terminal window を即座に開かずにタスクを実行します。タスク開始時には通知を送ります。

## TODO

以下はまだ大まかなロードマップであり、今後の設計にあわせて変更される可能性があります。

- 現在の provider 指向の execution model の上に、任意の quickfix / status 連携を追加できるようにする
- CI と自動テストを拡充する
- タスクの開始、完了、失敗などのライフサイクルイベントに対するフックを指定できるようにする
