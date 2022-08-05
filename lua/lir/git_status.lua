local a = require'plenary.async_lib'
local async_void = a.async_void
local async = a.async
local await = a.await
local lir = require'lir'
local config = require'lir.git_status.config'
local git = require'lir.git_status.git'
local Path = require('plenary.path')

local sep = Path.path.sep

local M = {}



---comment
---@param bufnr number
---@param lnum number
---@param us string
---@param them string
local set_virtual_text = async(function(bufnr, lnum, us, them)
  local texts = {}
  table.insert(texts, { '[', 'LirGitStatusBracket' })

  local indicator = us..them

  if indicator:match('DD|AU|UD|UA|DU|AA|UU') then
    table.insert(texts, { indicator, 'LirGitStatusUnmerged' })

  elseif indicator == '??' then
    table.insert(texts, { '??', 'LirGitStatusUntracked' })

  elseif indicator == '!!' then
    table.insert(texts, { '!!', 'LirGitStatusIgnored' })
  else
    table.insert(texts, { us, 'LirGitStatusIndex' })
    table.insert(texts, { them, 'LirGitStatusWorktree' })
  end

  table.insert(texts, { ']', 'LirGitStatusBracket' })

  -- vim.api を実行できるまで待機
  await(a.scheduler())
  if vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_set_virtual_text(bufnr, -1, lnum - 1, texts, {})
  end
end)



--- パスとステータスを返す
---@param line string
---@return string
---@return string
local parse_status = function(line)
  local status = line:sub(1, 2)
  local res = vim.split(line:sub(4), ' %-> ')
  return res[#res], status
end




--- str が patterns にマッチするか？
---@param str string
---@param patterns string[]
---@return boolean
local match = function(str, patterns)
  for _, pattern in ipairs(patterns) do
    if str:match(pattern) then
      return true
    end
  end
  return false
end



M.refresh = async_void(function()
  local ctx = lir.get_context()
  -- windows の場合、末尾に \ がついてしまうため、それの対応
  -- \ を / にする
  local cwd = ctx.dir:gsub(sep .. '$', ''):gsub(sep, '/')
  local bufnr = vim.api.nvim_get_current_buf()

  local root = await(git.get_root(cwd))
  if root == nil then
    return
  end

  local results = await(git.get_status(root, { cwd }))
  if results == nil then
    return
  end

  -- root からの cwd の パス
  local rel_cwd = cwd:sub(#root+2)

  -- 完了したディレクトリのリスト
  local dirs = {}
  for i, entry in ipairs(ctx.files) do
    entry.git = entry.git or {}
    dirs[i] = { entry = entry }
  end

  local all_ignored = false

  for _, line in ipairs(results) do
    local path, status = parse_status(line)

    if status == '!!' and (#path < #rel_cwd or path == rel_cwd) then
      -- All files in this folder are ignored
      all_ignored = true
      break
    end

    if not path:match('^' .. vim.pesc(rel_cwd)) then
      goto continue
    end

    -- '/path/to/sample_dir/hoge.lua'
    --           ^^^^^^^^^^
    -- もし、 path/to が cwd だとすると
    -- sample_dir が value となる
    local trunc_path = path:sub(#rel_cwd + 1):match('^/?(.-)/?$')
    local value = trunc_path:match('^([^/]+)')
    if value == nil then
      goto continue
    end

    local exact_match = trunc_path == value

    -- 行番号を取得
    local lnum = ctx:indexof(value)
    if lnum == nil then
      goto continue
    end

    if not ctx.files[lnum].is_dir or (exact_match and status == '!!') then
      local us = status:sub(1, 1)
      local them = status:sub(2, 2)
      ctx.files[lnum].git.status = us .. them
      await(set_virtual_text(bufnr, lnum, us, them))

    else
      -- ディレクトリ

      local dic = dirs[lnum]

      -- form fean-git-status.vim
      if not dic.us
          and match(status, {'[MARC][ MD]', 'D[ RC]'}) then
        dic.us = '-'
      end

      if not dic.them
          and match(status, {
            '%?%?',
            '[ MARC][MD]',
            '[ D][RC]',
            'DD|DU|UD|UU|UA|AA|AU',
          }) then
        dic.them = '-'
      end

    end

::continue::

  end

  -- ディレクトリのステータスを表示
  for lnum, status in ipairs(dirs) do
    local us, them
    if all_ignored then
      us, them = '!', '!'
    else
      us = status.us or ' '
      them = status.them or ' '
    end

    if us ~= ' ' or them ~= ' ' then
      status.entry.git.status = us .. them
      await(set_virtual_text(bufnr, lnum, us, them))
    end
  end
end)



local setup_highlight = function()
  vim.cmd [[highlight default link LirGitStatusBracket Comment]]
  vim.cmd [[highlight default link LirGitStatusIndex Special]]
  vim.cmd [[highlight default link LirGitStatusWorktree WarningMsg]]
  vim.cmd [[highlight default link LirGitStatusUnmerged ErrorMsg]]
  vim.cmd [[highlight default link LirGitStatusUntracked Comment]]
  vim.cmd [[highlight default link LirGitStatusIgnored Comment]]
end



local define_autocmds = function()
  vim.cmd [[augroup LirGitStatus]]
  vim.cmd [[  autocmd!]]
  vim.cmd [[  autocmd FileType lir lua require'lir.git_status'.refresh()]]
  vim.cmd [[augroup END]]
end


M.setup = function(prefs)
  config.set_default_values(prefs)
  define_autocmds()
  setup_highlight()
end


return M
