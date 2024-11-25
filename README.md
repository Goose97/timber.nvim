# timber.nvim

Insert log statements blazingly fast and capture log results inline 🪵

https://github.com/user-attachments/assets/6bbcb1ab-45a0-45f3-a03a-1d0780219362

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

## Requirements

- [Neovim 0.10+](https://github.com/neovim/neovim/releases)
- [Recommended] [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter): to support languages, users need to install appropriate Treesitter parsers. `nvim-treesitter` provides an easy interface to manage them.

## Installation

Install this plugin using your favorite plugin manager, and then call `require("timber").setup()`.

### [lazy.nvim](https://github.com/folke/lazy.nvim)

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

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

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

## Keymaps

The default configuration comes with a set of default keymaps:

| Action | Keymap | Description |
| -      | -      | -           |
| insert_log_below | glj | Insert a log statement below the cursor |
| insert_log_above | glk | Insert a log statement above the cursor |
| add_log_targets_to_batch | gla | Add a log target to the batch |
| insert_batch_log | glb | Insert a batch log statement |

Detailed information on how to configure keymaps can be found in [`:h timber.nvim-config.keymaps`](https://github.com/Goose97/timber.nvim/blob/main/doc/timber.nvim.txt).

See [RECIPES](https://github.com/Goose97/timber.nvim/blob/main/doc/RECIPES.md) guide for more keymap inspiration.

## Usage

### Insert log statements

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
                                                print(string.format("foo=%s, num=%s", foo, num))
```

The log statements can be inserted via APIs. See [`:h timber.nvim-actions.api`](https://github.com/Goose97/timber.nvim/blob/main/doc/timber.nvim.txt) for more information.

The content of the log statement is specified via templates. See [`:h timber.nvim-config.log-templates`](https://github.com/Goose97/timber.nvim/blob/main/doc/timber.nvim.txt) for more information.

```lua
    -- Template: [[print("LOG %line_number %log_target", %log_target)]]
    local foo = 1
    print("LOG 1 foo", foo)
```

### Clear log statements

Clear all log statements in the current buffer:

```lua
    require("timber.actions").clear_log_statements({ global = false })
```

or from all buffers:

```lua
    require("timber.actions").clear_log_statements({ global = true })
```

Be aware of [potential limitations](https://github.com/Goose97/timber.nvim/blob/main/doc/timber.nvim.txt).

### Capture log results

`timber.nvim` can monitor multiple sources and capture the log results. For example, a common use case is to capture the log results from a test runner or from a log file.

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
        sources = {
            {
                type = "filesystem",
                name = "Log file",
                path = "/tmp/debug.log",
            },
            {
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

![Screenshot 2024-11-12 at 22 01 34](https://github.com/user-attachments/assets/844cec52-3ecf-4b7b-ac67-b7280f882f73)

See [`:h timber.nvim-watchers`](https://github.com/Goose97/timber.nvim/blob/main/doc/timber.nvim.txt) for more information.

## Configuration

The default configuration is found [here](https://github.com/Goose97/timber.nvim/blob/main/doc/timber.nvim.txt). To initialize the plugin, call `require("timber").setup` with the desired options.

See [`:h timber.nvim-config`](https://github.com/Goose97/timber.nvim/blob/main/doc/timber.nvim.txt) for more information.

## Tips

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

## Contributing

Any contributions are highly welcome. If you want to support new languages or extend functionalities of existing languages,
please read [this documentation](https://github.com/Goose97/timber.nvim/blob/main/doc/HOW-IT-WORKS.md) about the internal of
`timber.nvim` first. For bug reports, feature requests, or discussions, please file a [Github issue](https://github.com/Goose97/timber.nvim/issues).
