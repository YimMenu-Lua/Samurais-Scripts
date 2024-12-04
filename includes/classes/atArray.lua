---@diagnostic disable
---@meta
-- My shitty attempt at implementing YimMenu's `atArray` template class.
---@class atArray
atArray = {}
atArray.__index = atArray

function atArray:new()
  local instance = {
    m_data  = {},
    m_count = 0,
    m_size  = 0
  }
  setmetatable(instance, atArray)
  return instance
end

-- Expands the array size.
function atArray:expand()
  self.m_size = (self.m_size == 0) and 1 or (self.m_size * 2) -- If the size is bigger than 0, doble it. Otherwise, start from 1.
  for i = self.m_count + 1, self.m_size do
    self.m_data[i] = nil -- Set new elements to nil
  end
end

-- Adds a new value to the array.
--
-- If the current count reaches the allocated size, it calls `expand()` to double it.
function atArray:append(value)
  if self.m_count >= self.m_size then
    self:expand()
  end
  self.m_data[self.m_count + 1] = value
  self.m_count = self.m_count + 1
end

-- Retrieves an array element at the provided index.
--
-- Returns an error if the element doesn't exist.
function atArray:get(index)
  if index < 1 or index > self.m_count then
    error("Index out of bounds", 2)
  end
  return self.m_data[index]
end

-- Clears the array.
function atArray:clear()
  self.m_data  = {}
  self.m_count = 0
  self.m_size  = 0
end

-- Returns the array size.
function atArray:size()
  return self.m_count
end

-- Checks if the array contains the provided value.
function atArray:contains(value)
  for i = 1, self.m_count do
    if self.m_data[i] == value then
      return true
    end
  end
  return false
end

-- Prints the array size and all its elements to the console.
function atArray:print()
  log.debug("Array Size: " .. self:size())
  for i = 1, self.m_count do
    log.info(string.format("\t[%s]", i) .. tostring(self.m_data[i]))
  end
end
