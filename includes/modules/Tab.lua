---@diagnostic disable: param-type-mismatch

---@class GuiCallback : function

--------------------------------------
-- Tab Struct
--------------------------------------
---@ignore
---@class Tab : ClassMeta<Tab>
---@field private m_name string
---@field private m_selected_subtab Tab
---@field private m_callback? GuiCallback
---@field private m_subtabs? table<string, Tab>
---@field private m_grid_layout? GridRenderer
---@field private m_has_error boolean
---@overload fun(name: string, drawable?: GuiCallback, subtabs?: Tab) : Tab
local Tab = Class("Tab")

---@param name string
---@param drawable? GuiCallback
---@param subtabs? Tab[]
---@return Tab
function Tab.new(name, drawable, subtabs)
    return setmetatable(
        {
            m_name      = name,
            m_callback  = drawable,
            m_subtabs   = subtabs or {},
            m_has_error = false
        },
        Tab
    )
end

---@param name string
---@param drawable? GuiCallback
---@param subtabs? Tab[]
---@return Tab
function Tab:RegisterSubtab(name, drawable, subtabs)
    assert((type(name) == "string" and #name > 0),
        "Attempt to register a new tab with no name."
    )

    local subtab = Tab(name, drawable, subtabs)
    self.m_subtabs[name] = subtab
    return subtab
end

---@param drawable GuiCallback
function Tab:RegisterGUI(drawable)
    if (type(drawable) ~= "function") then
        return
    end

    if (self:HasGUI()) then
        log.fwarning("Tab %s already had a GUI callback. Did you mean to overwrite it?", self:GetName())
    end

    self.m_callback = drawable
end

---@return boolean
function Tab:HasGUI()
    return (type(self.m_callback) == "function")
end

---@return boolean
function Tab:HasSubtabs()
    return next(self.m_subtabs) ~= nil
end

---@return boolean
function Tab:HasGridLayout()
    return self.m_grid_layout ~= nil
end

---@param name string
---@return Tab?
function Tab:GetSubtab(name)
    return self.m_subtabs[name]
end

---@return string
function Tab:GetName()
    return self.m_name
end

---@return GuiCallback
function Tab:GetGUICallback()
    return self.m_callback
end

---@return table<string, Tab>
function Tab:GetSubtabs()
    return self.m_subtabs
end

---@return GridRenderer|nil
function Tab:GetGridRenderer()
    return self.m_grid_layout
end

---@param columns? number
---@param padding_x? number
---@param padding_y? number
---@return GridRenderer
function Tab:GetOrCreateGrid(columns, padding_x, padding_y)
    if (not self.m_grid_layout) then
        self.m_grid_layout = GridRenderer.new(
            columns or 5,
            padding_x or 25,
            padding_y or 25
        )
    end

    return self.m_grid_layout
end

function Tab:RemoveGrid()
    self.m_grid_layout = nil
end

function Tab:RemoveGUI()
    self.m_callback = nil
end

---@param label string
---@param gvar_key string -- A key to insert into GVars (global variables)
---@param on_enable? function
---@param on_disable? function
---@param meta? CommandMeta
function Tab:AddBoolCommand(label, gvar_key, on_enable, on_disable, meta)
    if (type(label) ~= "string" or type(gvar_key) ~= "string") then
        error("AddBoolCommand requires a label and global variable key string.")
    end

    meta = meta or {}
    self:GetOrCreateGrid():AddCheckbox(
        label,
        gvar_key,
        {
            persistent = true,
            tooltip = meta.description,
            onClick = function()
                if (GVars[gvar_key] and type(on_enable) == "function") then
                    on_enable()
                end
                if (not GVars[gvar_key] and type(on_disable) == "function") then
                    on_disable()
                end
            end,
        }
    )

    if (not CommandExecutor) then
        return
    end

    local command_name = label:lower():gsub("%s+", "_")
    CommandExecutor:RegisterCommand(command_name, function()
        GVars[gvar_key] = not GVars[gvar_key]

        if (GVars[gvar_key] and type(on_enable) == "function") then
            on_enable()
        end

        if (not GVars[gvar_key] and type(on_disable) == "function") then
            on_disable()
        end

        CommandExecutor:notify(
            "%s %s",
            label,
            GVars[gvar_key] and "Enabled" or "Disabled"
        )
    end, meta)
end

---@param label string
---@param gvar_key string -- A key to insert into GVars (global variables)
---@param callback function
---@param on_disable? function
---@param meta? CommandMeta
function Tab:AddLoopedCommand(label, gvar_key, callback, on_disable, meta)
    if (type(label) ~= "string" or type(gvar_key) ~= "string") then
        error("AddBoolCommand requires a label and global variable key string.")
    end

    meta = meta or {}
    local command_name = label:lower():gsub("%s+", ""):trim()
    local suspended_thread = not GVars[gvar_key]
    local thread = ThreadManager:CreateNewThread(command_name:upper(), callback, suspended_thread)

    local function toggle()
        if GVars[gvar_key] then
            if thread then thread:Resume() end
        else
            if thread then thread:Suspend() end
            if on_disable then on_disable() end
        end

        CommandExecutor:notify(
            "%s %s.",
            label,
            GVars[gvar_key] and "Enabled" or "Disabled"
        )
    end

    self:GetOrCreateGrid():AddCheckbox(
        label,
        gvar_key,
        {
            persistent = true,
            tooltip = meta.description,
            onClick = toggle,
        }
    )

    if (not CommandExecutor) then
        return
    end

    local command_callback = function()
        GVars[gvar_key] = not GVars[gvar_key]
        toggle()
    end

    CommandExecutor:RegisterCommand(command_name, command_callback, meta)
end

function Tab:Notify(fmt, ...)
    local msg = (... ~= nil) and _F(fmt, ...) or fmt
    Toast:ShowMessage(self:GetName(), msg, false, 5)
end

function Tab:DrawInternal()
    if (not self.m_callback) then
        return
    end

    if (self.m_has_error) then
        ImGui.Text(_F("Tab %s has crashed. Please contact the developer.", self.m_name))
    end

    local ok, err = pcall(self.m_callback)
    if (not ok) then
        log.fwarning("[%s]: Callback error: %s", self.m_name, err)
        self.m_has_error = true
        return
    end
end

function Tab:Draw()
    if (table.getlen(self.m_subtabs) == 0) then
        self:DrawInternal()
        return
    end

    ImGui.BeginTabBar(_F("##sutab_selector%s", self.m_name))
    if (ImGui.BeginTabItem(self.m_name)) then
        self:DrawInternal()
        ImGui.EndTabItem()
    end

    for name, tab in pairs(self.m_subtabs) do
        if (ImGui.BeginTabItem(name)) then
            tab:Draw()
            ImGui.EndTabItem()
        end
    end
    ImGui.EndTabBar()
end

return Tab
