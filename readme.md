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

## How it works

The plugin operates relies on the `git status` command and checks if the git tree is clean.

When in *writes count* mode, it will count the number of writes overall for all your buffers and
will notify you when you reach the limit of `writes_number` if the git tree is dirty.

In the *schedule* mode, it's basically the same except it will check the git tree every
`check_interval` minutes.

*Stop on useless commits* feature is comparing your last commit message withe a list of the most
common uninformative commit messages like "update", "fix", "wip", etc. and will ask you to
rephrase your commit message if it matches.

*Hardcore mode*, when enabled, will prevent you from saving your file until you commit all the
changes you have in a working tree right now. If `stop_on_useless_commit`, it will also prevent
you from saving until you fix the commit message.

## Installation

Install with your favorite plugin manager.

### Lazy

```lua
{
  "nick-skriabin/commitment.nvim",
  opts = {}
}
```

### Packer

```lua
use {
  "nick-skriabin/commitment.nvim",
  config = function()
    require("commitment").setup()
  end,
}
```

### Vim-Plug

```vim
Plug 'nick-skriabin/commitment.nvim'
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
