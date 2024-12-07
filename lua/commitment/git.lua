local M = {}

function M.is_git_repo()
    local cwd = vim.fn.getcwd()
    local git_dir = vim.fn.system("cd " .. cwd .. " && git rev-parse --show-toplevel")
    return git_dir ~= ""
end

function M.git_tree_is_clean()
    local cwd = vim.fn.getcwd()
    local changed_files = vim.fn.system("cd " .. cwd .. " && git status --porcelain | wc -l | awk '$1=$1'")
    return changed_files == ""
end

function M.file_has_changes(filename)
    local has_changes = vim.fn.system("cd " .. vim.fn.getcwd() .. " && git status --s " .. filename .. " | wc -l | awk '$1=$1'")
end

function M.is_dumb_commit()
    local useless_commits = require("commitment.useless_commit_messages")
    local commit_message = vim.fn.system("cd " .. vim.fn.getcwd() .. " && git show -s --format=%s")

    for _, message in ipairs(useless_commits) do
        if commit_message:find(message) then
            return true
        end
    end

    return false
end

return M
