# timber.nvim

Insert log statements blazingly fast and capture log results inline 🪵

https://github.com/user-attachments/assets/6bbcb1ab-45a0-45f3-a03a-1d0780219362

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Setup](#setup)
- [Usage](#usage)
- [Comparison with other plugins](#comparison-with-other-plugins)
- [Misc](#misc)

## Features

- Quickly insert log statements
  - Automatically capture the log targets and log position using Treesitter
  - Customizable log templates
- Support batch log statements (multiple log target statements)
- Dot-repeat actions
- Support various languages:
  - Javascript (include JSX)
  - Typescript (include JSX)
  - Lua
  - Ruby
  - Elixir
  - Golang
  - Rust
  - Python
  - C
  - C++
  - Java
  - C#
  - Odin
  - Bash
  - Swift
  - Kotlin
  - Scala
  - [Fallback for others](#fallback-for-non-treesitter-languages)

## Requirements

- [Neovim 0.10+](https://github.com/neovim/neovim/releases)
- [Recommended] [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter): to support languages, users need to install appropriate Treesitter parsers. `nvim-treesitter` provides an easy interface to manage them.
- [Optional] [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim): required for log statements search feature.

## Installation

timber.nvim supports multiple plugin managers

<details>
<summary><strong>lazy.nvim</strong></summary>

```lua
{
    "Goose97/timber.nvim",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    config = function()
        require("timber").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end
}
```
</details>

<details>
<summary><strong>packer.nvim</strong></summary>

```lua
use({
    "Goose97/timber.nvim",
    tag = "*", -- Use for stability; omit to use `main` branch for the latest features
    config = function()
        require("timber").setup({
            -- Configuration here, or leave empty to use defaults
        })
    end
})
```
</details>

<details>
<summary><strong>mini.deps</strong></summary>

```lua
local MiniDeps = require("mini.deps");

MiniDeps.add({
    source = "Goose97/timber.nvim",
})

require("timber").setup({
    -- Configuration here, or leave empty to use defaults
})
```
</details>

## Setup

You will need to call `require("timber").setup()` to intialize the plugin. You can pass in a configuration table to customize the plugin.

<details>
<summary><strong>Default configuration</strong></summary>

```lua
{
    log_templates = {
        default = {
            -- Templates with auto_import: when inserting a log statement, the import line is inserted automatically
            -- Applies to batch log statements as well
            -- javascript = {
            --   [[logger.info('hello world')]],
            --   auto_import = [[const logger = require('pino')()]]
            -- }
            javascript = [[console.log("%log_target", %log_target)]],
            typescript = [[console.log("%log_target", %log_target)]],
            astro = [[console.log("%log_target", %log_target)]],
            vue = [[console.log("%log_target", %log_target)]],
            jsx = [[console.log("%log_target", %log_target)]],
            tsx = [[console.log("%log_target", %log_target)]],
            lua = [[print("%log_target", %log_target)]],
            luau = [[print("%log_target", %log_target)]],
            ruby = [[puts("%log_target #{%log_target}")]],
            elixir = [[IO.inspect(%log_target, label: "%log_target")]],
            go = [[log.Printf("%log_target: %v\n", %log_target)]],
            rust = [[println!("%log_target: {:#?}", %log_target);]],
            python = [[print(f"{%log_target=}")]],
            c = [[printf("%log_target: %s\n", %log_target);]],
            cpp = [[std::cout << "%log_target: " << %log_target << std::endl;]],
            java = [[System.out.println("%log_target: " + %log_target);]],
            c_sharp = [[Console.WriteLine($"%log_target: {%log_target}");]],
            odin = [[fmt.printfln("%log_target: %v", %log_target)]],
            swift = [[print("%log_target:", %log_target)]],
            kotlin = [[println("%log_target: ${%log_target}")]],
            scala = [[println(s"%log_target: ${%log_target}")]],
        },
        plain = {
            javascript = [[console.log("%insert_cursor")]],
            typescript = [[console.log("%insert_cursor")]],
            astro = [[console.log("%insert_cursor")]],
            vue = [[console.log("%insert_cursor")]],
            jsx = [[console.log("%insert_cursor")]],
            tsx = [[console.log("%insert_cursor")]],
            lua = [[print("%insert_cursor")]],
            luau = [[print("%insert_cursor")]],
            ruby = [[puts("%insert_cursor")]],
            elixir = [[IO.puts(%insert_cursor)]],
            go = [[log.Printf("%insert_cursor")]],
            rust = [[println!("%insert_cursor");]],
            python = [[print(f"%insert_cursor")]],
            c = [[printf("%insert_cursor \n");]],
            cpp = [[std::cout << "%insert_cursor" << std::endl;]],
            java = [[System.out.println("%insert_cursor");]],
            c_sharp = [[Console.WriteLine("%insert_cursor");]],
            odin = [[fmt.println("%insert_cursor")]],
            swift = [[print("%insert_cursor")]],
            kotlin = [[println("%insert_cursor")]],
            scala = [[println("%insert_cursor")]],
        },
    },
    batch_log_templates = {
        default = {
            javascript = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
            typescript = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
            astro = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
            vue = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
            jsx = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
            tsx = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
            lua = [[print(string.format("%repeat<%log_target=%s><, >", %repeat<%log_target><, >))]],
            luau = [[print(`%repeat<%log_target={%log_target}><, >`)]],
            ruby = [[puts("%repeat<%log_target: #{%log_target}><, >")]],
            elixir = [[IO.inspect({ %repeat<%log_target><, > })]],
            go = [[log.Printf("%repeat<%log_target: %v><, >\n", %repeat<%log_target><, >)]],
            rust = [[println!("%repeat<%log_target: {:#?}><, >", %repeat<%log_target><, >);]],
            python = [[print(f"%repeat<{%log_target=}><, >")]],
            c = [[printf("%repeat<%log_target: %s><, >\n", %repeat<%log_target><, >);]],
            cpp = [[std::cout %repeat<<< "%log_target: " << %log_target>< << "\n  " > << std::endl;]],
            java = [[System.out.printf("%repeat<%log_target=%s><, >%n", %repeat<%log_target><, >);]],
            c_sharp = [[Console.WriteLine($"%repeat<%log_target: {%log_target}><, >");]],
            odin = [[fmt.printfln("%repeat<%log_target: %v><, >", %repeat<%log_target><, >)]],
            swift = [[print("%repeat<%log_target: %log_target><, >")]],
            kotlin = [[println("%repeat<%log_target=${%log_target}><, >")]],
            scala = [[println(s"%repeat<%log_target=${%log_target}><, >")]],
        },
    },
    template_placeholders = {
        filename = function()
          return vim.fn.expand("%:t")
        end,
        -- Custom placeholder. For example, this can be used in log templates as %truncated_line
        -- truncated_line = function(ctx)
        --   local line = ctx.log_target:start()
        --   return nvim_buf_get_lines(0, line - 1, line, false)[1]:sub(1, 16)
        -- end,
    },
    -- The string to search for when deleting or commenting log statements
    -- Can be used in log templates as %log_marker placeholder
    log_marker = "🪵",
    -- Controls the flash highlight
    highlight = {
        -- After a log statement is inserted
        on_insert = true,
        -- After a log target is added to a batch
        on_add_to_batch = true,
        -- After a log entry is shown/jumped to in the summary panel
        on_summary_show_entry = true,
        -- The duration of the flash highlight
        duration = 500,
    },
    keymaps = {
        -- Set to false to disable the default keymap for specific actions
        -- insert_log_below = false,
        insert_log_below = "glj",
        insert_log_above = "glk",
        insert_plain_log_below = "glo",
        insert_plain_log_above = "gl<S-o>",
        insert_batch_log = "glb",
        add_log_targets_to_batch = "gla",
        insert_log_below_operator = "g<S-l>j",
        insert_log_above_operator = "g<S-l>k",
        insert_batch_log_operator = "g<S-l>b",
        add_log_targets_to_batch_operator = "g<S-l>a",
    },
    -- Set to false to disable all default keymaps
    default_keymaps_enabled = true,
    log_watcher = {
        enabled = false,
        sources = {},
        -- The length of the preview snippet display as extmarks
        preview_snippet_length = 32,
    },
    log_summary = {
        -- Keymaps for the summary window
        keymaps = {
            -- Set to false to disable the default keymap for specific actions
            -- show_entry = false,
            show_entry = "<CR>",
            jump_to_entry = "o",
            next_entry = "]]",
            prev_entry = "[[",
            close = "q",
        },
        -- Set to false to disable all default keymaps in the summary window
        default_keymaps_enabled = true,
        -- Customize the summary window
        win = {
            -- Control the width of the summary window
            -- They can be a single integer (number of columns)
            -- or a float from 0 to 1 (percentage of the current window width e.g. 0.4 for 40%)
            -- or an array of mixed types
            -- width = {60, 0.4} means "the lesser of 60 columns and 40% of the current window width"
            width = { 60, 0.4 },
            -- Determines where the summary window will be opened: left, right
            position = "left",
            -- Customize the window options
            opts = {},
        },
    },
}
```

</details>

### Keymaps

The default configuration comes with a set of default keymaps:

| Action | Keymap | Description |
| -      | -      | -           |
| insert_log_below | glj | Insert a log statement below the cursor |
| insert_log_above | glk | Insert a log statement above the cursor |
| insert_plain_log_below | glo | Insert a plain log statement below the cursor |
| insert_plain_log_above | gl\<S-o\> | Insert a plain log statement above the cursor |
| add_log_targets_to_batch | gla | Add a log target to the batch |
| insert_batch_log | glb | Insert a batch log statement |

To include context in log statements, insert time tracking log statements, etc, see [RECIPES](https://github.com/Goose97/timber.nvim/blob/main/doc/RECIPES.md#advanced-logging-use-cases) guide for keymap inspiration.

## Usage

<details>
<summary><strong>Insert log statements</strong></summary>

There are two kinds of log statements:

1. Single log statements: log statements that may or may not capture single log target
2. Batch log statements: log statements that capture multiple log targets

These examples use the default configuration. The `|` denotes the cursor position.

```help
    Old text                    Command         New text
    --------------------------------------------------------------------------------------------
    local str = "H|ello"        glj             local str = "Hello"
                                                print("str", str)
    --------------------------------------------------------------------------------------------
    foo(st|r)                   glk             print("str", str)
                                                foo(str)
    --------------------------------------------------------------------------------------------
    foo(st|r, num)              vi(glb          foo(str, num)
                                                print(string.format("str=%s, num=%s", str, num))
```

</details>

<details>
<summary><strong>Customize log statements</strong></summary>

The content of the log statement can be customized via templates. `timber.nvim` supports some special placeholders which will be replaced after inserting:

- `%log_target`: the log target text
- `%line_number`: the line number of the log target
- `%filename`: the name of the current file

```lua
local opts = {
    log_templates = {
        default = {
            lua = [[print("LOG %log_target ON LINE %filename:%line_number", %log_target)]],
        },
    },
}

require("timber").setup(opts)
```

Out of the box, `timber.nvim` provides [default templates](https://github.com/Goose97/timber.nvim/blob/main/lua/timber/config.lua) for all supported languages.

</details>

<details>
<summary><strong>Clear/comment log statements</strong></summary>

To use these features, you need to configure `log_marker`. The default is 🪵. This `log_marker` will be search/grep to find the log statement lines. Make sure to include it in your log templates. A convenient way to do it is using the `%log_marker` placeholder:

```lua

opts = {
    log_templates = {
        default = {
            lua = [[print("%log_marker " .. %log_target)]],
        },
    },
    log_marker = "🪵", -- Or any other string, e.g: MY_LOG
}
```

Clear all log statements in the current buffer:

```lua
require("timber.actions").clear_log_statements({ global = false })
```

or comment all log statements in the current buffers (call this again will uncomment them):

```lua
require("timber.actions").toggle_comment_log_statements({ global = false })
```

Use `global = true` to perform the action on all files. `timber.nvim` uses grep to find all log statements in your project. For this to work, you need to make sure your `grepprg` is suitable. The search comand will be invoked as: `<grepprg> <log_marker>`. These are some recommendations, ranking from most to least recommended:

```lua
vim.o.grepprg = "rg --vimgrep --no-heading --smart-case" -- Use ripgrep
vim.o.grepprg = "git grep --line-number --column" -- Use git
vim.o.grepprg = "grep --line-number --with-filename -R --exclude-dir=.git" -- Use grep
```

</details>

<details>
<summary><strong>Search log statements</strong></summary>

Similar to clear/comment log statements feature, you need to configure `log_marker`. `timber.nvim` uses `telescope.nvim` to search log statements:

```lua
require("timber.actions").search_log_statements()
```
</details>

<details>
<summary><strong>Capture log output</strong></summary>

`timber.nvim` can monitor multiple sources and capture the log output. For example, a common use case is to capture the log output from a test runner or from a log file.

Here's an example configuration:

```lua
require("timber").setup({
    log_templates = {
        default = {
            lua = [[print("%watcher_marker_start" .. %log_target .. "%watcher_marker_end")]],
        },
    },
    log_watcher = {
        enabled = true,
        -- A table of source id and source configuration
        sources = {
            log_file = {
                type = "filesystem",
                name = "Log file",
                path = "/tmp/debug.log",
            },
            neotest = {
                -- Test runner
                type = "neotest",
                name = "Neotest",
            },
        },
    }
})

-- Configure neotest consumer if source neotest is used
require("neotest").setup({
    consumers = {
        timber = require("timber.watcher.sources.neotest").consumer,
    },
})
```

The configuration does two things:

1. It adds the watcher marker placeholders to the log template. These markers help us extract the log results from the sources. For example, the log statement can print to stdout something like this: `🪵ZGH|Hello World|ZGH`. Notice the log content `Hello World` flanked by two markers.
2. It enables the log watcher and configures the log watcher to monitor two sources: a file and the [neotest](https://github.com/nvim-neotest/neotest) test run output.

After the log results are captured, a snippet of the log result will be displayed inline next to the log statement. You can also see the full log content inside a floating window using `require("timber.buffers").open_float()`

![image](https://github.com/user-attachments/assets/e2ea2765-f43d-4ca2-91b5-a02d07f9a4ce)

See how to setup syntax highlighting for the float buffer in [RECIPES](https://github.com/Goose97/timber.nvim/blob/main/doc/RECIPES.md#pretty-captured-log-buffer).

</details>

<details>
<summary><strong>Show log output summary</strong></summary>

You can view the captured log output in a split window:

```lua
require("timber.summary").open({ focus = true })
```

https://github.com/user-attachments/assets/469cd456-f4a3-4d20-833c-ea1be908776c

The summary window will show all captured log entries in chronological order. You can view or jump to the log statement line using `o` or `<CR>` with the default mappings.

The summary window has the following keymaps:

| Action | Keymap | Description |
| -      | -      | -           |
| show_entry | \<CR\> | Show the buffer contains the log entry |
| jump_to_entry | o | Same as show_entry, but also move cursor to the location |
| next_entry | ]] | Jump to next log entry in the summary window |
| prev_entry | [[ | Jump to prev log entry in the summary window |
| close | q | Close the summary window |
| show_help | ? | Show the keymaps for the summary window |

</details>

## Comparison with other plugins

<details>
<summary><strong>timber.nvim</strong></summary>

- Pros:
    - Capture log target using Treesitter. This makes inserting log statements more accurate.

    ```lua
    if (
        foo > bar and
        -- print("foo", foo) - ❌ Non-Treesitter plugin will insert here
        bar > baz
    ) then
        -- print("foo", foo) - ✅ timber.nvim will insert here
    end
    ```

    - Insert multiple log statements at once using visual mode
    - Capture multiple log targets in a single statement. This makes log output more readable and organized.
    - Can capture log output and display it inline or in a floating window

- Cons:
    - Treesitter requires hand-written queries for each languages. It does not support all languages out of the box.
    - Must install Treesitter parser for each language

</details>

<details>
<summary><strong>debugprint.nvim</strong></summary>

[Repo](https://github.com/andrewferrier/debugprint.nvim)

- More mature plugin: support more languages and has fallback heuristic for non-supported languages.
- Has more features: prompt users to choose expressions to print, print in insert mode
- Logging mechanism does not use Treesitter as much as timber.nvim

</details>

<details>
<summary><strong>nvim-chainsaw</strong></summary>

[Repo](https://github.com/chrisgrieser/nvim-chainsaw)

- Comes with many built-in commands: objectLog, typeLog, assertLog, etc
- Logging mechanism does not use Treesitter as much as timber.nvim

</details>

<details>
<summary><strong>printer.nvim</strong></summary>

[Repo](https://github.com/rareitems/printer.nvim)

- Support only `below` log position or put the log statement into yank register
- Does not use Treesitter to power log
</details>

<details>
<summary><strong>logsitter.nvim</strong></summary>

[Repo](https://github.com/gaelph/logsitter.nvim)

- Use Treesitter to power log
- Limited support for languages: only Javascript like, Golang, Lua, Python, Swift
- Log statements customization is limited: can only specify the log prefix and separator
</details>


## Misc

### Highlight groups

<details>
<summary>Click to see all highlight groups</summary>

<!-- hl_start -->

| Highlight Group | Default Group | Description |
| ----------------------------- | ----------------------- | ------------------------------ |
| **Timber.Insert** | _Search_ | Flash highlight when insert log statements |
| **Timber.AddToBatch** | _Search_ | Flash highlight when add log targets to batch |
| **Timber.LogStatement** | _none_ | Log statement line |
| **Timber.LogPlaceholderSnippet** | _DiagnosticVirtualTextInfo_ | Captured log output snippet |
| **Timber.LogPlaceholderTime** | _none_ | Captured log output time |
| **Timber.FloatingWindowEntrySeparator** | _FloatBorder_ | Horizontal separator between entries in the floating window |
| **Timber.SummaryEntryHeader** | _none_ | Entry header in the summary window |
| **Timber.SummaryEntryBodyHighlighted** | _PmenuSel_ | Highlighted entry body in the summary window |
| **Timber.SummaryJumpToLine** | _Search_ | Flash highlight when jump to line in the summary window |

<!-- hl_end -->

</details>

### Fallback for non-Treesitter languages

In case the language does not have a Treesitter parser, the plugin will fallback to use a simple capture mechanism for the `%log_target` placeholder:

1. In normal mode, capture the current word under cursor
2. In visual mode, capture the selection range

### Tips

It's common for languages to have syntax to access fields from an object/instance. For example, in Lua, we have `foo.bar`
or `foo["bar"]`. It introduces a problem: we have more than one potential log targets. Consider this case (`|` denotes
the cursor position):

  ```
  local foo = ba|r.baz["baf"]
  ```

`bar`, `bar.baz`, and `bar.baz["baf"]` are all sensible choices here, what should we choose? `timber.nvim` applies some
[heuristic](https://github.com/Goose97/timber.nvim/blob/main/doc/HOW-IT-WORKS.md#Heuristic) to choose the target.

A good rule of thumb is placing your cursor in last part of the field access chain if you want to log it.

```
local foo = ba|r.baz.baf --> print("bar", bar)
local foo = bar.ba|z.baf --> print("bar.baz", bar.baz)
local foo = bar.baz.ba|f --> print("bar.baz.baf", bar.baz.baf)
```

### Contributing

Any contributions are highly welcome. If you want to support new languages or extend functionalities of existing languages,
please read [this documentation](https://github.com/Goose97/timber.nvim/blob/main/doc/HOW-IT-WORKS.md) about the internal of
`timber.nvim` first. For bug reports, feature requests, or discussions, please file a [Github issue](https://github.com/Goose97/timber.nvim/issues).
