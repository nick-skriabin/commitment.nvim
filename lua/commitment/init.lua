--- # commitment.nvim - Never forget to git commit!
--- MIT License Copyright (c) 2024 Nick Skriabin (a.k.a. Whaledev)
---
--- Often commits are good. But we forget to do them. This plugin helps you remember to do them.
---
--- ## What this plugin does:
--- - Operates on either number of saves or time interval
--- - Hardcore mode: Prevents writes to file until changes are committed
--- - When reached writes limit or a timeout, shows a reminder
---
--- ## Installation:
---
--- ### Lazy
--- @usage >lua
--- {
---   "whaledev/commitment.nvim",
---   opts = {}
--- }
--- <
---
--- ### Packer
--- @usage >lua
--- use {
---   "whaledev/commitment.nvim",
---   config = function()
---     require("commitment").setup()
---   end,
--- }
--- <
---
--- ### Vim-Plug
--- @usage >vim
--- Plug 'whaledev/commitment.nvim'
--- <
---
--- ### Default config
--- ```lua
--- require("commitment").setup({
---   -- Regular message. Shown when writes limit is reached or timer fired.
---   message = "Don't forget to git commit!",
---   -- Message shown when writes are prevented.
---   message_write_prevent = "You shall not write!",
---   -- Message shown when useless commit message is detected.
---   message_useless_commit = "That's not a very useless commit message, mind rephrasing it?",
---   -- Prevents writes to file until changes are committed.
---   stop_on_write = false,
---   -- Prevent writes to file when useless commit message is detected.
---   stop_on_useless_commit = false,
---   -- Number of writes before asking to commit.
---   writes_number = 30,
---   -- Interval in minutes to check git tree for changes.
---   check_interval = -1,
--- })
--- ```
local utils = require("commitment.utils")
local git = require("commitment.git")

local default_opts = {
    --- Regular message. Shown when writes limit is reached or timer fired.
    message = "Don't forget to git commit!",
    --- Message shown when writes are prevented.
    message_write_prevent = "You shall not write!",
    --- Message shown when useless commit message is detected.
    message_useless_commit = "That's not a very useful commit message, mind rephrasing it?",
    --- Prevents writes to file until changes are committed.
    stop_on_write = false,
    --- Prevent writes to file when useless commit message is detected.
    stop_on_useless_commit = false,
    --- Number of writes before asking to commit.
    writes_number = 30,
    --- Interval in minutes to check git tree for changes.
    check_interval = -1,
}

WRITES_COUNT = 0
local locked = false

--- Module start
local M = {
    config = default_opts,
}

--- Handles writing to file
--- Will prevent writes to file if `locked` is true
--- Outputs the default message if written successfully
--- @private
---
local function custom_write()
    vim.api.nvim_exec_autocmds("BufWritePre", {
        buffer = 0,
    })

    -- Get the current buffer number
    local bufnr = vim.api.nvim_get_current_buf()

    -- Get the current buffer's filename
    local filename = vim.api.nvim_buf_get_name(bufnr)

    -- Check if this is a forced write
    local force = vim.v.cmdbang == 1

    local file_has_changes = git.file_has_changes(filename)

    if locked and (vim.bo.modified or file_has_changes) then
        return
    end

    -- Check if the buffer is modified
    if vim.bo.modified or force then
        -- Perform your custom write logic
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local line_count = #lines

        -- Get relative path
        local relative_path = filename:sub(#vim.fn.getcwd() + 2)

        -- Example: Write to file
        local file = io.open(filename, "w")
        vim.api.nvim_exec_autocmds("BufWrite", {
            buffer = bufnr,
        })
        if file then
            file:write(table.concat(lines, "\n"))
            file:close()

            -- Clear the modified flag
            vim.bo.modified = false
            local size = vim.fn.getfsize(filename)

            -- Optional: Notify about successful write
            vim.notify(string.format('"%s" %dL, %dB', relative_path, line_count, size), vim.log.levels.INFO)

            -- Trigger BufWritePost
            vim.api.nvim_exec_autocmds("BufWritePost", {
                buffer = bufnr,
            })
        else
            vim.notify("Failed to write file: " .. filename, vim.log.levels.ERROR)
        end
    end
end

--- Sets up an autocmd to prevent writing to the file
--- when `opts.prevent_write` is true.
--- @private
---
local function notifier()
    local last_notification_time = 0
    local debounce_interval = 500 -- 500 milliseconds
    local L = {}

    --- Sends a notification. Debounces the notifications
    --- within 500ms to prevent spamming.
    ---
    ---@param message string The message to be displayed.
    ---
    function L.notify(message)
        local current_time = vim.loop.hrtime() / 1e6 -- convert to milliseconds
        local time_diff = current_time - last_notification_time

        if time_diff > debounce_interval then
            utils.notify(message)
        end
        last_notification_time = current_time
    end

    return L
end

--- Sets up an autocmd to prevent writing to the file
--- when `opts.prevent_write` is true.
---
function M.setup_write_prevent_autocmd(self)
    utils.autocmd({ "BufWriteCmd" }, {
        group = utils.autogroup("commitment-preven", true),
        callback = custom_write,
    })
end

--- Gets the message to be displayed to the user
---
---@param alt boolean? Indicates that an alternative message should be used.
---
function M.get_message(self, alt)
    local opts = self.config
    local extra_message = opts.prevent_write and locked and "\n(writing to file disabled)" or ""
    local main_message = opts.prevent_write and opts.message_write_prevent or opts.message
    if alt then
        main_message = opts.message_useless_commit
    end
    return main_message .. extra_message
end

--- Sets up an autocmd to watch for changes in the git tree
--- it will notify the user if they exceeded the number of writes
--- or if the commit message is useless. It will also disable writing
--- to the file when `opts.prevent_write` is true.
---
function M.setup_watcher_autocmd(self)
    local n = notifier()
    utils.autocmd({ "BufWritePre" }, {
        group = utils.autogroup("commitment-watch", true),
        callback = function()
            local clean = git.git_tree_is_clean()
            local exceeded_writes = WRITES_COUNT > self.config.writes_number
            local useless = git.is_useless_commit()

            if clean and not useless then
                locked = false
                WRITE_COUNT = 0
            elseif (not clean and exceeded_writes) or (clean and useless) then
                locked = true
                n.notify(self:get_message(useless))
            end
            WRITES_COUNT = WRITES_COUNT + 1
        end,
    })
end

--- Runs the watcher with `opts.check_interval` interval in minutes
---
function M.run_scheduled(self)
    local n = notifier()
    vim.defer_fn(function()
        local clean = git.git_tree_is_clean()
        local useless = git.is_useless_commit()
        if not clean or useless then
            n.notify(self:get_message(useless))
            locked = true
        else
            locked = false
        end
        self:run_scheduled()
    end, self.config.check_interval * 60 * 1000)
end

--- Module setup
---
---@param config table|nil Module config table. See |commitment.config|.
---
---@usage >lua
---   require('commitment').setup() -- use default config
---   -- OR
---   require('commitment').setup({}) -- replace {} with your config table
--- <
function M.setup(self, config)
    if not git.is_git_repo() then
        return
    end
    self.config = utils.deep_merge_opts(config or {}, self.config)

    if self.config.prevent_write then
        self:setup_write_prevent_autocmd()
    end

    if self.config.check_interval == -1 then
        self.setup_watcher_autocmd()
        return
    else
        M:run_scheduled()
    end
end

M.git = git

return M
