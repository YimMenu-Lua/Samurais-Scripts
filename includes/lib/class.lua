---@diagnostic disable: undefined-doc-name

---@generic T
---@class ClassMeta<T>
---@field new? fun(...): T
---@field init? fun(self: T, ...): T
---@field extend fun(self: T, subclassName: string): T
---@field super fun(self: T): ClassMeta<T>
---@field isinstance fun(self: any, class: any): boolean
---@field notify fun(_, fmt: string, ...?: any) : nil

-- All class-level helper methods use lowercase: new, init, extend, serialize, isinstance, super, etc.
--
-- This avoids clashing with PascalCase global utils and class methods and ensures style consistency.
---@generic T
---@param name string Class name
---@param base T? Optional: Parent class (inheritance)
---@param size? integer Optional: sizeof class
---@return ClassMeta<T>
function Class(name, base, size)
    size = size or SizeOf(GenericClass)

    local cls = { m_size = size }
    cls.__index = cls
    cls.__name = name
    cls.__type = name

    -- optional inheritance
    if (base) then
        -- so I have to manually copy base metamethods? https://www.youtube.com/watch?v=AxkZJmi-5xc
        for k, v in pairs(base) do
            if k:match("^__") and cls[k] == nil then
                cls[k] = v
            end
        end

        cls.__base = base
    end

    -- classes can be initialized directly without explicitly calling the constructor.
    setmetatable(
        cls,
        {
            __call = function(c, ...)
                local instance

                if base then
                    if base.new then
                        instance = base.new(...)
                    elseif base.init then
                        instance = base:init(...)
                    end
                end

                if c.new then
                    instance = c.new(...)
                elseif c.init then
                    instance = c:init(...)
                else
                    instance = {}
                end

                if (type(instance) == "table") then
                    instance.__type = c.__type
                    setmetatable(instance, c)
                end

                return instance
            end,
            __index = base,
        }
    )

    function cls:super()
        return self.__base or self
    end

    ---@param sub_ame string
    ---@param sub_size? integer
    function cls:extend(sub_ame, sub_size)
        return Class(sub_ame, self, sub_size)
    end

    ---@param of any
    function cls:isinstance(of)
        return IsInstance(self, of)
    end

    if (Serializer and type(cls.serialize) == "function" and type(cls.deserialize) == "function") then
        local typename = cls.__type:lower():trim()
        if not Serializer.class_types[typename] then
            Serializer:RegisterNewType(typename, cls.serialize, cls.deserialize)
        end
    end

    -- If ToastNotifier is available, calls `ToastNotifier:ShowMessage`. Otherwise logs to console.
    function cls:notify(fmt, ...)
        local msg = (... ~= nil) and string.format(fmt, ...) or fmt
        local caller = name:gsub("_", " "):titlecase()

        if (Toast) then
            Toast:ShowMessage(caller, msg, false, 5)
        else
            log.info("[" .. caller .. "]: " .. msg)
        end
    end

    return cls
end
