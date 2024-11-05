# timber.nvim

Insert log statements blazingly fast and capture log results inline 🪵

https://github.com/user-attachments/assets/6bbcb1ab-45a0-45f3-a03a-1d0780219362

## Features

- Quickly insert log statements
  - Automatically capture the log targets and log position using Treesitter
  - Customizable log templates
- Support batch log statements (multiple log target statements)
- Dot-repeat actions
- Support various languages: Javascript, Typescript, Lua, ...

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

## Usage

The core operation of `timber.nvim` inserting log statements. There are two kinds of log statements:

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
    -- Template: [[print("LOG %line_number %identifier", %identifier)]]
    local foo = 1
    print("LOG 1 foo", foo)
```

## Configuration

The default configuration is found [here](https://github.com/Goose97/timber.nvim/blob/main/doc/timber.nvim.txt). To initialize the plugin, call `require("timber").setup` with the desired options.

See [`:h timber.nvim-config`](https://github.com/Goose97/timber.nvim/blob/main/doc/timber.nvim.txt) for more information.
