---@diagnostic disable: param-type-mismatch

---@class GuiCallback : function

--------------------------------------
-- Tab Struct
--------------------------------------
---@ignore
---@class Tab : ClassMeta<Tab>
---@field private m_name string
---@field private m_selected_tab_name string
---@field private m_callback? GuiCallback
---@field private m_subtabs? table<string, Tab>
---@field private m_grid_layout? GridRenderer
---@field private m_has_error boolean
---@field private m_traceback string
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

---@return number
function Tab:GetTabCount()
	return table.getlen(self.m_subtabs)
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
		local spacing = ImGui.GetStyle().ItemSpacing
		self.m_grid_layout = GridRenderer.new(
			columns or 1,
			padding_x or spacing.x,
			padding_y or spacing.y
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
---@param noCommand? boolean
---@param isTranslatorLabel? boolean If you want to pass a translator key as the label, provide it as is without the `_T` function and set this to true.
function Tab:AddBoolCommand(label, gvar_key, on_enable, on_disable, meta, noCommand, isTranslatorLabel)
	if (type(label) ~= "string" or type(gvar_key) ~= "string") then
		error("AddBoolCommand requires a label and global variable key string.")
	end

	local function onClick(value)
		if (type(value) ~= "boolean") then
			return
		end

		if (value and type(on_enable) == "function") then
			on_enable()
		elseif (not value and type(on_disable) == "function") then
			on_disable()
		end
	end

	meta = meta or {}
	self:GetOrCreateGrid():AddCheckbox(
		label,
		gvar_key,
		{
			persistent = true,
			tooltip = meta.description,
			isTranslatorLabel = isTranslatorLabel,
			onClick = function()
				local v = table.get_nested_key(GVars, gvar_key)
				onClick(v)
			end,
		}
	)

	if (noCommand or not CommandExecutor or type(table.get_nested_key(GVars, gvar_key)) ~= "boolean") then
		return
	end

	local command_name = label:lower():gsub("%s+", "_")
	CommandExecutor:RegisterCommand(command_name, function()
		local v = table.get_nested_key(GVars, gvar_key)
		v = not v
		table.set_nested_key(GVars, gvar_key, v)
		onClick(v)
		CommandExecutor:notify(
			"%s %s",
			label,
			v and "Enabled" or "Disabled"
		)
	end, meta)
end

---@param label string
---@param gvar_key string -- A key to insert into GVars (global variables)
---@param callback function
---@param on_disable? function
---@param meta? CommandMeta
---@param noCommand? boolean
---@param isTranslatorLabel? boolean If you want to pass a translator key as the label, provide it as is without the `_T` function and set this to true.
function Tab:AddLoopedCommand(label, gvar_key, callback, on_disable, meta, noCommand, isTranslatorLabel)
	if (type(label) ~= "string" or type(gvar_key) ~= "string") then
		error("AddBoolCommand requires a label and global variable key string.")
	end

	meta = meta or {}
	local command_name = label:lower():gsub("%s+", ""):trim()
	local config_value = table.get_nested_key(GVars, gvar_key)
	local suspended_thread = not config_value
	local thread = ThreadManager:RegisterLooped(_F("SS_%s", command_name:upper()), callback, suspended_thread)

	local function toggle()
		local v = table.get_nested_key(GVars, gvar_key)
		if (table.get_nested_key(GVars, gvar_key)) then
			if thread then thread:Resume() end
		else
			if thread then thread:Suspend() end
			if on_disable then on_disable() end
		end

		if (not noCommand) then
			CommandExecutor:notify(
				"%s %s.",
				label,
				v and "Enabled" or "Disabled"
			)
		end
	end

	self:GetOrCreateGrid():AddCheckbox(
		label,
		gvar_key,
		{
			persistent = true,
			tooltip = meta.description,
			isTranslatorLabel = isTranslatorLabel,
			onClick = toggle,
		}
	)

	if (noCommand or not CommandExecutor) then
		return
	end

	local command_callback = function()
		local v = table.get_nested_key(GVars, gvar_key)
		table.get_nested_key(GVars, not v)
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
		ImGui.TextColored(0.8, 0.8, 0, 1, _F("Tab '%s' has crashed. Please contact the developer.", self.m_name))
		if (self.m_traceback) then
			ImGui.Spacing()
			ImGui.BulletText("Traceback most recent call:")
			ImGui.Indent()
			ImGui.TextColored(1, 0, 0, 1, self.m_traceback)
			ImGui.Unindent()
			if (ImGui.Button("Copy Trace")) then
				ImGui.SetClipboardText(self.m_traceback)
			end
		end
		return
	end

	local ok, err = pcall(self.m_callback)
	if (not ok) then
		log.fwarning("[%s]: Callback error: %s", self.m_name, err)
		self.m_has_error = true
		self.m_traceback = err
		return
	end
end

function Tab:Draw()
	if (not self:HasSubtabs()) then
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
			if (tab:HasSubtabs()) then
				ImGui.EndTabItem()
				ImGui.EndTabBar()
				tab:Draw()
				return
			end

			tab:DrawInternal()
			ImGui.EndTabItem()
		end
	end
	ImGui.EndTabBar()
end

return Tab
