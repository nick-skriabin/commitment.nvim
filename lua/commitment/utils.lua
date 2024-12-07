--- Collection of utility functions
local M = {}

--- Creates an augroup
---
---@param name string The name of the augroup.
---@param clear boolean? Whether to clear the group before creating it.
---
M.autogroup = function(name, clear)
    local clear_group = true

    if clear == nil then
        clear_group = clear == nil and true or clear
    end

    return vim.api.nvim_create_augroup(name, { clear = clear_group })
end

--- Creates an autocmd
---
---@param events string|string[] The events to be listened to.
---@param options table The options for the autocmd.
---
M.autocmd = function(events, options)
    vim.api.nvim_create_autocmd(events, options)
end

--- Notifies the user with a message
---
---@param msg string The message to be displayed.
---
function M.notify(msg)
    -- if snacks.nvim is available, use it
    if pcall(require, "snacks") then
        require("snacks").notify.warn(msg)
        return
    -- otherwise use noice.nvim
    elseif pcall(require, "notify") then
        require("notify").notify(msg, "warn")
        return
    end
    vim.notify(msg, "warn")
end

--- Merges two tables recursively
---
---@param t1 table
---@param t2 table
---
function M.deep_merge(self, t1, t2)
    for k, v in pairs(t2) do
        if (type(v) == "table") and (type(t1[k] or false) == "table") then
            self:merge(t1[k], t2[k])
        else
            t1[k] = v
        end
    end
    return t1
end

return M
