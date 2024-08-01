local files = require("overseer.files")
local M = {}

---Get the primary language for the workspace
---TODO this is VERY incomplete at the moment
---@return string|nil
M.get_workspace_language = function()
  if files.any_exists("setup.py", "setup.cfg", "pyproject.toml", "mypy.ini") then
    return "python"
  elseif files.any_exists("tsconfig.json") then
    return "typescript"
  elseif files.any_exists("package.json") then
    return "javascript"
  end
  -- TODO java
  -- TODO powershell
end

---@param dir string
---@return nil|string
local function find_tasks_file(dir)
  local vscode_dirs =
    vim.fs.find(".vscode", { upward = true, type = "directory", path = dir, limit = math.huge })

  for _, vscode_dir in ipairs(vscode_dirs) do
    local tasks_file = files.join(vscode_dir, "tasks.json")
    if files.exists(tasks_file) then
      return tasks_file
    end
  end
end

---@param dir string
---@return nil|string
local function find_workspace_file(dir)
  local vscode_dirs = vim.fs.find(function(name, path)
    return name:match(".*%.code%-workspace")
  end, { upward = true, type = "file", path = dir, limit = math.huge })

  return vscode_dirs[1]
end

---@param cwd string
---@param dir string
---@return nil|table
M.get_tasks_file = function(cwd, dir)
  local workspace_file = find_workspace_file(cwd)

  if workspace_file then
    local ret = {}
    local defn = M.load_tasks_file(workspace_file)
    local folders = {}
    for _, v in ipairs(defn.folders) do
      if type(v) == "string" then
        table.insert(folders, v)
      else
        if v.path then
          table.insert(folders, v.path)
        end
      end
    end
    for _, v in ipairs(folders) do
      local tasks_file = files.join(cwd, v, ".vscode", "tasks.json")
      if files.exists(tasks_file) then
        table.insert(ret, tasks_file)
      end
    end
    return ret
  end
  local ret = {}
  -- Look for the tasks file relative to the cwd and only then fall back to searching from the dir
  local cwd_tasks = find_tasks_file(cwd)
  if cwd_tasks then
    table.insert(ret, cwd_tasks)
  end
  local dir_tasks = find_tasks_file(dir)
  if dir_tasks then
    table.insert(ret, dir_tasks)
  end
  return ret
end

---@param tasks_file string
---@return table
M.load_tasks_file = function(tasks_file)
  return files.load_json_file(tasks_file)
end

return M
