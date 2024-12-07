-- commitment.nvim - Never forget to git commit!
-- MIT License Copyright (c) 2024 Nick Skriabin (a.k.a. Whaledev)
--
-- Often commits are good. But we forget to do them. This plugin helps you remember to do them.
--
-- What this plugin does:
-- - Operates on either number of saves or time interval
-- - Hardcore mode: Prevents writes to file until changes are committed
-- - When reached writes limit or a timeout, shows a reminder
--
-- Configuration:
--
-- - prevent_write: boolean, default: false
-- - writes_number: number, default: 3
-- - check_interval: number, default: -1 (disabled)
-- - message: string, default: "Don't forget to git commit!"
-- - message_write_prevent: string, default: "You shall not write!"
local utils = require("commitment.utils")
local git = require("commitment.git")

local writes_count = 0
local locked = false

local M = {}

local default_opts = {
    -- Regular message. Shown when writes limit is reached or timer fired.
    message = "Don't forget to git commit!",
    -- Message shown when writes are prevented.
    message_write_prevent = "You shall not write!",
    -- Prevents writes to file until changes are committed.
    prevent_write = false,
    -- Number of writes before asking to commit.
    writes_number = 30,
    -- Interval in minutes to check git tree for changes.
    check_interval = -1,
}

local function custom_write(args)
    vim.api.nvim_exec_autocmds("BufWritePre", {
        buffer = 0,
    })

    if locked then
        return
    end

    -- Get the current buffer number
    local bufnr = vim.api.nvim_get_current_buf()

    -- Get the current buffer's filename
    local filename = vim.api.nvim_buf_get_name(bufnr)

    -- Check if this is a forced write
    local force = vim.v.cmdbang == 1

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

local function notifier()
    local last_notification_time = 0
    local debounce_interval = 500 -- 500 milliseconds
    local M = {}

    function M.notify(message)
        local current_time = vim.loop.hrtime() / 1e6 -- convert to milliseconds
        local time_diff = current_time - last_notification_time

        if time_diff > debounce_interval then
            utils.notify(message)
        end
        last_notification_time = current_time
    end

    return M
end

local function check_write(opts, notify) end

local function setup_write_prevent_autocmd(opts)
    local notify = notifier().notify

    utils.autocmd({ "BufWriteCmd" }, {
        group = utils.autogroup("commitment-preven", true),
        callback = custom_write,
    })
end

local function get_message(opts)
    local extra_message = opts.prevent_write and locked and "\n(writing to file disabled)" or ""
    return (opts.prevent_write and opts.message_write_prevent or opts.message) .. extra_message
end

local function setup_watcher_autocmd(opts)
    local n = notifier()
    utils.autocmd({ "BufWritePre" }, {
        group = utils.autogroup("commitment-watch", true),
        callback = function()
            local clean = git.git_tree_is_clean()
            local exceeded_writes = writes_count > opts.writes_number

            if not clean and exceeded_writes then
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
