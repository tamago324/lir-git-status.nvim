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




--- cwd の git status を返す
---@param cwd string
---@return table
M.get_status = async(function(cwd)
  local err, res = await(command({
    command = 'git',
    args = {
      'status',
      '--porcelain',
      '-u'
    },
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
