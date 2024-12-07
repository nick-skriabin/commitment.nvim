local M = {}
local function custom_write()
    -- Get the current buffer number
    local bufnr = vim.api.nvim_get_current_buf()

    -- Get the current buffer's filename
    local filename = vim.api.nvim_buf_get_name(bufnr)

    -- Check if the buffer is modified
    if vim.bo.modified then
        -- Perform your custom write logic
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

        -- Example: Write to file
        local file = io.open(filename, "w")
        if file then
            file:write(table.concat(lines, "\n"))
            file:close()

            -- Clear the modified flag
            vim.bo.modified = false

            -- Optional: Notify about successful write
            vim.notify("File written: " .. filename, vim.log.levels.INFO)
        else
            vim.notify("Failed to write file: " .. filename, vim.log.levels.ERROR)
        end
    end
end

return M
