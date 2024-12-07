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

return M
