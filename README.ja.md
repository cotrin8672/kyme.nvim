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

バックグラウンドタスクの状態表示、一覧表示、quickfix 連携などは現在 core には含めていません。

## 必要要件

- Neovim 0.10+
- 任意 provider:
  - 組み込み source provider 用の mise
  - 組み込み picker provider 用の folke/snacks.nvim
  - 組み込み runner provider 用の akinsho/toggleterm.nvim

## インストール

lazy.nvim の例:

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

## 使い方

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

Kyme には 3 種類の provider があります。

### SourceProvider

source はタスクを非同期に収集します。

~~~lua
---@class kyme.SourceProvider
---@field name string
---@field collect fun(done: fun(tasks: kyme.Task[]))
~~~

### PickerProvider

picker は 1 つ以上のタスクを選択します。

~~~lua
---@class kyme.PickerProvider
---@field name string
---@field pick fun(tasks: kyme.Task[], done: fun(result?: kyme.PickerResult))
~~~

### RunnerProvider

runner は選択されたタスクを実行します。

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

`command` は常に argv 形式です。provider は shell string ではなく、次のような構造化された command を返すことを推奨します。

~~~lua
{ 'mise', 'run', 'build' }
~~~

## 組み込み Provider

### mise Source

次のコマンドからタスクを収集します。

~~~sh
mise tasks --json
~~~

### snacks Picker

snacks.nvim でタスクを表示します。item は次の形式で表示されます。

~~~text
mise: task-name
~~~

preview にはタスクの説明と command が Markdown で表示されます。

### toggleterm Runner

toggleterm.nvim を使って、terminal window を即座に開かずにタスクを実行します。タスク開始時には通知を送ります。

## TODO

以下はまだ大まかなロードマップであり、今後の設計にあわせて変更される可能性があります。

- 実行中タスクの管理も、現在の provider 指向のモデルと同じように扱えるようにする
- CI と自動テストを拡充する
- タスクの開始、完了、失敗などのライフサイクルイベントに対するフックを指定できるようにする
- preview 生成を、より独立した provider interface として切り出す
