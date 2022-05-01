local a = require'plenary.async_lib'
local async = a.async
local await = a.await
local Job = require'plenary.job'
local logger = require('plenary.log')

local config = require'lir.git_status.config'

local M = {}


--- コマンドを実行する
---@param opts table
---@param callback function
---@return table err
---@return table results 結果のリスト
local command = a.wrap(function(opts, callback)
  local results = {}
  local err = {}

  Job:new({
    command = opts.command,
    args = opts.args,
    cwd = opts.cwd,

    on_stdout = function(_, data)
      table.insert(results, data)
    end,

    on_stderr = function(_, data)
      table.insert(err, data)
    end,

    on_exit = function(_, data)
      if #err ~= 0 then
        callback(err, nil)
        return
      end
      callback(nil, results)
    end

  }):start()
end, 2)





--- cwd に対応する git repository の root を取得する
---@param cwd string
---@return string? root Git root directory
M.get_root = async(function(cwd)
  local err, res = await(command({
    command = 'git',
    args = {
      'rev-parse',
      '--show-toplevel'
    },
    cwd = cwd,
  }))

  if err then
    if config.get('debug') then
      logger.error('git_root', err)
    end
    return nil
  end

  return res[1]
end)

---Check if status for untracked files is enabled for a given git repo.
---@param cwd string git top-level
---@return boolean
M.show_untracked = async(function(cwd)
  local err, res = await(command({
    command = 'git',
    args = {
      'config',
      '--type=bool',
      'status.showUntrackedFiles',
    },
    cwd = cwd,
  }))

  if err then
    if config.get('debug') then
      logger.error('show_untracked', err)
    end
    return nil
  end

  return vim.trim(res[1] or "") ~= "false"
end)



--- cwd の git status を返す
---@param cwd string
---@param paths string[]
---@return table
M.get_status = async(function(cwd, paths)
  local show_untracked = await(M.show_untracked(cwd))
  local args = {
    'status',
    '--porcelain',
  }

  if show_untracked and config.get('show_ignored') then
    table.insert(args, '--ignored=matching')
  end

  if type(paths) == 'table' then
    args[#args+1] = '--'
    for _, path in ipairs(paths) do
      args[#args+1] = path
    end
  end

  local err, res = await(command({
    command = 'git',
    args = args,
    cwd = cwd
  }))

  if err then
    if config.get('debug') then
      logger.error('git_root', err)
    end
    return nil
  end

  return res
end)

return M
