if (not Backend or (Backend:GetAPIVersion() ~= eAPIVersion.L54)) then
    return
end

---@alias LogLevel string
---|"trace"
---|"debug"
---|"info"
---|"warning"
---|"error"

---@class LoggerOptions struct
---@field level? LogLevel
---@field use_colors? boolean
---@field use_timestamp? boolean
---@field use_caller? boolean
---@field file? string
---@field max_size? number

local LEVELS <const> = {
    trace   = 0,
    debug   = 1,
    info    = 2,
    warning = 3,
    error   = 4
}

local LEVEL_LABELS <const> = {
    [0] = "TRACE",
    [1] = "DEBUG",
    [2] = "INFO",
    [3] = "WARNING",
    [4] = "ERROR"
}

local COLORS <const> = {
    trace   = "\27[37m",
    debug   = "\27[36m",
    info    = "\27[32m",
    warning = "\27[33m",
    error   = "\27[31m",
    reset   = "\27[0m"
}

---@param path string
local function mkdir(path)
    local isNT = package.config:sub(1, 1) == "\\"
    local cmd = isNT and ("mkdir \"%s\""):format(path) or ("mkdir -p '%s'"):format(path)
    os.execute(cmd)
end

---@return string
local function get_timestamp()
    ---@diagnostic disable-next-line
    return os.date("%Y-%m-%d %H:%M:%S")
end

---@param stack_depth? number
---@return string
local function get_caller_info(stack_depth)
    stack_depth = stack_depth or 12
    local info = debug.getinfo(stack_depth, "nSl")

    while (not info or not info.currentline or not info.name) do
        if (stack_depth <= 1) then
            break
        end

        stack_depth = stack_depth - 1
        info = debug.getinfo(stack_depth, "nSl")
    end

    if (not info) then
        return "?"
    end

    local src = info.short_src or "?"
    local line = info.currentline or "?"
    local name = info.name

    if (name) then
        return _F("%s:%d in function %s", src, line, name)
    else
        return _F("%s:%d", src, line)
    end
end


--------------------------------
--Class: Logger
--------------------------------
-- Do not use this in YimMenu. It will not load.
---@class Logger
---@field name? string
---@field level? integer
---@field use_colors? boolean
---@field use_timestamp? boolean
---@field use_caller? boolean
---@field file_path? string
---@field file? string
---@field max_size? number
local Logger = {}
Logger.__index = Logger

-- ### Constructor
--
-- Optional params:
--[[

    level:         (string)  -- logging level: "trace"|"debug"|"info"|"warning"|"error"
    use_colors:    (boolean) -- Change the console color for each logging level. ANSI colors must be enabled on Windows.
    file:          (string)  -- File path to wrtie logs
    max_size:      (number)  -- File size (bytes) before rotating
    use_timestamp: (boolean) -- Prepend timestamps (defaults to true)
    use_caller:    (boolean) -- Show caller info (defaults to true)
]]
---@param name string
---@param options? LoggerOptions
---@return Logger
function Logger.new(name, options)
    options = options or {}

    local instance = {
        name = name or "Logger",
        level = LEVELS[options.level or "debug"] or LEVELS.debug,
        use_timestamp = options.use_timestamp ~= false,
        use_caller = options.use_caller ~= false,
        use_colors = options.use_colors or false,
        file_path = options.file or nil,
        max_size = options.max_size or nil
    }

    return setmetatable(instance, Logger)
end

---@param level string
function Logger:setLevel(level)
    self.level = LEVELS[level] or self.level
end

---@param level string
---@return boolean
function Logger:shouldLog(level)
    return LEVELS[level] >= self.level
end

---@param level string
---@param msg any
---@param trace_info string
function Logger:format(level, msg, trace_info)
    local parts = {}

    if self.use_timestamp then
        table.insert(parts, "[" .. get_timestamp() .. "]")
    end

    table.insert(parts, "[" .. self.name .. "]")
    table.insert(parts, "[" .. LEVEL_LABELS[LEVELS[level]] .. "]")

    if self.use_caller then
        table.insert(parts, "[" .. trace_info .. "]")
    end

    table.insert(parts, tostring(msg))
    return table.concat(parts, " ")
end

---@param line string
function Logger:writeToFile(line)
    if not self.file_path then
        return
    end

    local ok, f = pcall(io.open, self.file_path, "a")
    if not ok or not f then
        return
    end

    if self.max_size then
        local size = f:seek("end")

        if size and size > self.max_size then
            f:close()

            local backup_dir = "./log_backup"
            mkdir(backup_dir)

            local timestamp = get_timestamp():gsub("[: ]", "_")
            local new_name = _F("backup_%s.log", timestamp)
            local new_path = backup_dir .. "/" .. new_name

            os.rename(self.file_path, new_path)
            f = io.open(self.file_path, "w")
        end
    end

    if not f then
        return
    end

    f:write(line .. "\n")
    f:flush()
    f:close()
end

---@param level string
---@param message any
function Logger:log(level, message)
    if not self:shouldLog(level) then
        return
    end

    local trace_info = get_caller_info()
    local line = self:format(level, message, trace_info)

    if self.use_colors then
        local color = COLORS[level] or ""
        print(color .. line .. COLORS.reset)
    else
        print(line)
    end

    self:writeToFile(line)
end

---@param level string
---@param fmt any
---@param ... any
function Logger:logf(level, fmt, ...)
    if not self:shouldLog(level) then
        return
    end

    local ok, msg = pcall(_F, fmt, ...)

    if not ok then
        msg = "<formatting error!> " .. tostring(msg)
    end

    self:log(level, msg)
end

---@param msg any
function Logger:trace(msg)
    self:log("trace", msg)
end

---@param msg any
function Logger:debug(msg)
    self:log("debug", msg)
end

---@param msg any
function Logger:info(msg)
    self:log("info", msg)
end

---@param msg any
function Logger:warning(msg)
    self:log("warning", msg)
end

---@param msg any
function Logger:error(msg)
    self:log("error", msg)
end

---@param fmt any
---@param ... any
function Logger:ftrace(fmt, ...)
    self:logf("trace", fmt, ...)
end

---@param fmt any
---@param ... any
function Logger:fdebug(fmt, ...)
    self:logf("debug", fmt, ...)
end

---@param fmt any
---@param ... any
function Logger:finfo(fmt, ...)
    self:logf("info", fmt, ...)
end

---@param fmt any
---@param ... any
function Logger:fwarning(fmt, ...)
    self:logf("warning", fmt, ...)
end

---@param fmt any
---@param ... any
function Logger:ferror(fmt, ...)
    self:logf("error", fmt, ...)
end

return Logger
