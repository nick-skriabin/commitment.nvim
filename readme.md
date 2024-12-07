<h1 align="center">✨commitment.nvim✨</h1>

We all know often commits are good. But we forget to do them.
Meet commitment.nvim, a plugin that helps you always remember to commit.

## Features

- Operates on either number of saves or time interval
- When reached writes limit or a timeout, shows a reminder
- Prevent useless commit messages by using a list of the common generic
  uninformative commit messages
- Hardcore mode: Prevents writes to file until changes are committed. It will
  react to either of the restrictions above.

## Installation

Install with your favorite plugin manager.

### Lazy

```lua
{
  "whaledev/commitment.nvim",
  opts = {}
}
```

### Packer

```lua
use {
  "whaledev/commitment.nvim",
  config = function()
    require("commitment").setup()
  end,
}
```

### Vim-Plug

```vim
Plug 'whaledev/commitment.nvim'
```

### Default config

```lua
require("commitment").setup({
  -- Regular message. Shown when writes limit is reached or timer fired.
  message = "Don't forget to git commit!",
  -- Message shown when writes are prevented.
  message_write_prevent = "You shall not write!",
  -- Message shown when useless commit message is detected.
  message_useless_commit = "That's not a very useless commit message, mind rephrasing it?",
  -- Prevents writes to file until changes are committed.
  stop_on_write = false,
  -- Prevent writes to file when useless commit message is detected.
  stop_on_useless_commit = false,
  -- Number of writes before asking to commit.
  writes_number = 30,
  -- Interval in minutes to check git tree for changes.
  check_interval = -1,
})
```