local M = {}

M.autogroup = function(name, clear)
    local clear_group = true

    if clear == nil then
        clear_group = clear
    end

    return vim.api.nvim_create_augroup(name, { clear = clear_group })
end

M.autocmd = function(events, options)
    vim.api.nvim_create_autocmd(events, options)
end

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

return M
