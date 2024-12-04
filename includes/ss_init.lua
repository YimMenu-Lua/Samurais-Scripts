---@diagnostic disable

local basePath = 'includes/'
local packages = {
  'lib/Translations',
  'data/objects',
  'data/actions',
  'data/refs',
  'classes/atArray',
  'classes/vector2',
  'classes/vector3',
}

for _, package in pairs(packages) do
  require(string.format("%s%s", basePath, package))
end
