--- Git utils
local Git = {}

--- Checks if the current CWD is a git repo
--- @return boolean
function Git.is_git_repo()
    local cwd = vim.fn.getcwd()
    local git_dir = vim.fn.system("cd " .. cwd .. " && git rev-parse --show-toplevel")
    return git_dir ~= ""
end

--- Checks if the git tree is clean
--- @return boolean
function Git.git_tree_is_clean()
    local cwd = vim.fn.getcwd()
    local changed_files = vim.fn.system("cd " .. cwd .. " && git status --porcelain | wc -l | awk '$1=$1'")
    return changed_files == ""
end

--- Checks if the commit message is useless
--- Uses a list of the most common useless commit messages
--- @return boolean
function Git.is_useless_commit()
    local useless_commits = require("commitment.useless_commit_messages")
    local commit_message = vim.fn.system("cd " .. vim.fn.getcwd() .. " && git show -s --format=%s")

    for _, message in ipairs(useless_commits) do
        local commit_lowercase = commit_message:lower()
        local message_lowercase = message:lower()

        -- if commit_lowercase:find(message_lowercase) then
        if commit_lowercase == message_lowercase then
            return true
        end
    end

    return false
end

return Git