-- # commitment.nvim - Never forget to git commit!
-- MIT License Copyright (c) 2024 Nick Skriabin (a.k.a. Whaledev)
--
-- Often commits are good. But we forget to do them. This plugin helps you remember to do them.
--
-- ## What this plugin does:
-- - Operates on either number of saves or time interval
-- - Hardcore mode: Prevents writes to file until changes are committed
-- - When reached writes limit or a timeout, shows a reminder
--
-- ## Installation:
--
-- ### Lazy
-- ```lua
-- {
--   "whaledev/commitment.nvim",
--   opts = {}
-- }
-- ```
--
-- ### Packer
-- ```lua
-- use {
--   "whaledev/commitment.nvim",
--   config = function()
--     require("commitment").setup()
--   end,
-- }
-- ```
--
-- ### Vim-Plug
-- ```vim
-- Plug 'whaledev/commitment.nvim'
-- ```
--
-- ### Default config
-- ```lua
-- require("commitment").setup({
--   -- Regular message. Shown when writes limit is reached or timer fired.
--   message = "Don't forget to git commit!",
--   -- Message shown when writes are prevented.
--   message_write_prevent = "You shall not write!",
--   -- Message shown when useless commit message is detected.
--   message_useless_commit = "That's not a very useless commit message, mind rephrasing it?",
--   -- Prevents writes to file until changes are committed.
--   stop_on_write = false,
--   -- Prevent writes to file when useless commit message is detected.
--   stop_on_useless_commit = false,
--   -- Number of writes before asking to commit.
--   writes_number = 30,
--   -- Interval in minutes to check git tree for changes.
--   check_interval = -1,
-- })
-- ```
local utils = require("commitment.utils")
local git = require("commitment.git")

local default_opts = {
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
}

local writes_count = 0
local locked = false

-- Module start
local M = {}

-- Handles writing to file
-- Will prevent writes to file if `locked` is true
-- Outputs the default message if written successfully
local function custom_write(args)
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

-- Notify with a debounce
local function notifier()
    local last_notification_time = 0
    local debounce_interval = 500 -- 500 milliseconds
    local L = {}

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

local function setup_write_prevent_autocmd(opts)
    local notify = notifier().notify

    utils.autocmd({ "BufWriteCmd" }, {
        group = utils.autogroup("commitment-preven", true),
        callback = custom_write,
    })
end

local function get_message(opts, alt)
    local extra_message = opts.prevent_write and locked and "\n(writing to file disabled)" or ""
    local main_message = opts.prevent_write and opts.message_write_prevent or opts.message
    if alt then
        main_message = opts.message_useless_commit
    end
    return (opts.prevent_write and opts.message_write_prevent or opts.message) .. extra_message
end

local function setup_watcher_autocmd(opts)
    local n = notifier()
    utils.autocmd({ "BufWritePre" }, {
        group = utils.autogroup("commitment-watch", true),
        callback = function()
            local clean = git.git_tree_is_clean()
            local exceeded_writes = writes_count > opts.writes_number

            if clean and git.is_dumb_commit() then
                n.notify(get_message(opts))
            elseif not clean and exceeded_writes then
                locked = true
                n.notify(get_message(opts))
            elseif clean then
                writes_count = 0
                locked = false
            end
            writes_count = writes_count + 1
        end,
    })
end

-- runs every opt.check_interval minutes
local function run_scheduled(opts)
    local n = notifier()
    vim.defer_fn(function()
        local clean = git.git_tree_is_clean()
        if not clean then
            n.notify(get_message(opts))
            locked = true
        else
            locked = false
        end
        run_scheduled(opts)
    end, opts.check_interval * 60 * 1000)
end

-- Merges opts with default_opts
local function deep_merge_opts(opts)
    local merged_opts = {}
    for k, v in pairs(default_opts) do
        merged_opts[k] = v
    end
    for k, v in pairs(opts) do
        merged_opts[k] = v
    end
    return merged_opts
end

function M.setup(opts)
    opts = deep_merge_opts(opts)
    if not git.is_git_repo() then
        return
    end

    if opts.prevent_write then
        setup_write_prevent_autocmd(opts)
    end

    if opts.check_interval == -1 then
        setup_watcher_autocmd(opts)
        return
    else
        run_scheduled(opts)
    end
end

return M
