-----------------------------
-- Private
-----------------------------
local defaults_values = {
  debug = false,
  show_ignored = false
}


-----------------------------
-- Export
-----------------------------

local config = {}
config.values = {}

---@param opts table
function config.set_default_values(opts)
  config.values = vim.tbl_deep_extend('force', defaults_values, opts or {})
end

---get value
---@param key string
---@return any
function config.get(key)
  return config.values[key]
end

return config
