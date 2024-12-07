<h1 align="center">commitment.nvim</h1>

We all know often commits are good. But we forget to do them.
Meet commitment.nvim, a plugin that helps you remember to commit.

## Features

- Operates on either number of saves or time interval
- Hardcore mode: Prevents writes to file until changes are committed
- When reached writes limit or a timeout, shows a reminder

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
  prevent_write = false,
  writes_number = 30,
  check_interval = -1,
  message = "Don't forget to git commit!",
  message_write_prevent = "You shall not write!",
})
```

## Configuration

- `prevent_write`: boolean, default: false
- `writes_number`: number, default: 3
- `check_interval`: number, default: -1 (disabled)
- `message`: string, default: "Don't forget to git commit!"
- `message_write_prevent`: string, default: "You shall not write!"
