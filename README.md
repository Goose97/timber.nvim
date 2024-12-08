# timber.nvim

Insert log statements blazingly fast and capture log results inline 🪵

https://github.com/user-attachments/assets/6bbcb1ab-45a0-45f3-a03a-1d0780219362

## Table of contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
  - [lazy.nvim](#lazy.nvim)
  - [packer.nvim](#mini.deps)
  - [mini.deps](#mini.deps)
- [Setup](#setup)
- [Showcases](#showcases)

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

### mini.deps

```lua
local MiniDeps = require("mini.deps");

MiniDeps.add({
    source = "Goose97/timber.nvim",
})

require("timber").setup({
    -- Configuration here, or leave empty to use defaults
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

Detailed information on how to configure keymaps can be found in [`:h timber.nvim-config.keymaps`](https://github.com/Goose97/timber.nvim/blob/a2faec8a7525d49a2e033ce54246cd50a4fb9021/doc/timber.nvim.txt#L500).

To insert plain log statements, time tracking log statements, etc, see [RECIPES](https://github.com/Goose97/timber.nvim/blob/main/doc/RECIPES.md#advanced-logging-use-cases) guide for keymap inspiration.

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

The log statements can be inserted via APIs. See [`:h timber.nvim-actions.api`](https://github.com/Goose97/timber.nvim/blob/a2faec8a7525d49a2e033ce54246cd50a4fb9021/doc/timber.nvim.txt#L145) for more information.

#### Customize log statements

The content of the log statement can be customized via templates. `timber.nvim` supports some special placeholders which will be replaced after inserting:

- `%log_target`: the log target text
- `%line_number`: the line number of the log target.

See [`:h timber.nvim-config.log-templates`](https://github.com/Goose97/timber.nvim/blob/a2faec8a7525d49a2e033ce54246cd50a4fb9021/doc/timber.nvim.txt#L456) for more information.

```lua
local opts = {
    log_templates = {
        default = {
            lua = [[print("LOG %log_target ON LINE %line_number", %log_target)]],
        },
    },
}

require("timber").setup(opts)
```

Out of the box, timber.nvim provides [default templates](https://github.com/Goose97/timber.nvim/blob/main/lua/timber/config.lua) for all supported languages.

### Clear log statements

Clear all log statements in the current buffer:

```lua
require("timber.actions").clear_log_statements({ global = false })
```

or from all buffers:

```lua
require("timber.actions").clear_log_statements({ global = true })
```

### Comment log statements

Comment/uncomment all log statements in the current buffer:

```lua
require("timber.actions").toggle_comment_log_statements({ global = false })
```

or from all buffers:

```lua
require("timber.actions").toggle_comment_log_statements({ global = true })
```

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

See [`:h timber.nvim-watchers`](https://github.com/Goose97/timber.nvim/blob/a2faec8a7525d49a2e033ce54246cd50a4fb9021/doc/timber.nvim.txt#L261) for more information.

## Configuration

<details>
<summary><strong>Default configuration</strong></summary>

```lua
{
  log_templates = {
    default = {
      javascript = [[console.log("%log_target", %log_target)]],
      typescript = [[console.log("%log_target", %log_target)]],
      jsx = [[console.log("%log_target", %log_target)]],
      tsx = [[console.log("%log_target", %log_target)]],
      lua = [[print("%log_target", %log_target)]],
      ruby = [[puts("%log_target #{%log_target}")]],
      elixir = [[IO.inspect(%log_target, label: "%log_target")]],
      go = [[log.Printf("%log_target: %v\n", %log_target)]],
      rust = [[println!("%log_target: {:#?}", %log_target);]],
      python = [[print("%log_target", %log_target)]],
      c = [[printf("%log_target: %s\n", %log_target);]],
      cpp = [[std::cout << "%log_target: " << %log_target << std::endl;]],
    },
  },
  batch_log_templates = {
    default = {
      javascript = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      typescript = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      jsx = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      tsx = [[console.log({ %repeat<"%log_target": %log_target><, > })]],
      lua = [[print(string.format("%repeat<%log_target=%s><, >", %repeat<%log_target><, >))]],
      ruby = [[puts("%repeat<%log_target: #{%log_target}><, >")]],
      elixir = [[IO.inspect({ %repeat<%log_target><, > })]],
      go = [[log.Printf("%repeat<%log_target: %v><, >\n", %repeat<%log_target><, >)]],
      rust = [[println!("%repeat<%log_target: {:#?}><, >", %repeat<%log_target><, >);]],
      python = [[print(%repeat<"%log_target", %log_target><, >)]],
      c = [[printf("%repeat<%log_target: %s><, >\n", %repeat<%log_target><, >);]],
      cpp = [[std::cout %repeat<<< "%log_target: " << %log_target>< << "\n  " > << std::endl;]],
    },
  },
  -- Controls the flash highlight after a log statement is inserted
  -- or a log target is added to a batch
  highlight = {
    on_insert = true,
    on_add_to_batch = true,
    duration = 500,
  },
  keymaps = {
    -- Set to false to disable the default keymap for specific actions
    -- insert_log_below = false,
    insert_log_below = "glj",
    insert_log_above = "glk",
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
    preview_snippet_length = 32,
  },
}
```

</details>

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
