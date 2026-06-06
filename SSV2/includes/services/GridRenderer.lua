-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


---@class GridItemParams
---@field onClick? function Callback to execute when the item is clicked
---@field onTrue? function Callback to execute when the item is enabled
---@field finalValue? number Exclusive to radio buttons
---@field buttonRepeat? boolean Exclusive to buttons
---@field persistent? boolean Whether the passe global key should be serialized to JSON
---@field isTranslatorLabel? boolean If you want to pass a translator key as the label, provide it as is without the `_T` function and set this to true.
---@field tooltip? string
---@field disabled? boolean
---@field global_table? table -- The table where this item's global variable exists (if using a local variable, make sure it lives in a table and pass it here)
---@field fineTuning? { callback: function, condition: boolean|fun(): boolean }

---@class GridItemCheckboxParams : GridItemParams
---@field finalValue nil
---@field buttonRepeat nil

---@class GridItemButtonParams : GridItemParams
---@field onClick function
---@field onTrue nil
---@field persistent nil
---@field finalValue nil

---@class GridItemRadioParams : GridItemParams
---@field finalValue number
---@field buttonRepeat nil
---@field onTrue nil


---@enum eGridItemType
local eGridItemType <const> = {
	CHECKBOX     = 0,
	BUTTON       = 1,
	RADIO_BUTTON = 2,
	NEW_LINE     = 3
}


--#region GridItem

---@ignore
---@class GridItem
---@field m_type eGridItemType
---@field m_label string
---@field m_gvar? string
---@field m_opts GridItemParams
---@field m_uid joaat_t
---@field m_g_table table
---@field m_fine_tuning_data? { callback: function, condition: boolean|fun(): boolean }
local GridItem <const> = {}
GridItem.__index       = GridItem

---@param item_type eGridItemType
---@param item_label? string
---@param global_variable? string
---@param opts? GridItemParams
---@return GridItem
function GridItem.new(item_type, item_label, global_variable, opts)
	opts = opts or {}
	local g_table = opts.global_table or _G
	if (opts.persistent) then
		g_table = GVars
	end

	return setmetatable({
		m_uid              = _J(_F("%d%s", item_type, opts)),
		m_type             = item_type,
		m_label            = item_label or "",
		m_gvar             = global_variable,
		m_opts             = opts,
		m_g_table          = g_table,
		m_fine_tuning_data = opts.fineTuning
	}, GridItem)
end

---@return vec2 itemSize
function GridItem:Draw()
	local outSize
	local opts    = self.m_opts
	local _type   = self.m_type
	local g_table = self.m_g_table
	local gvar    = self.m_gvar
	local label   = opts.isTranslatorLabel and _T(self.m_label) or self.m_label
	local tooltip = opts.tooltip
	if (tooltip ~= nil and opts.isTranslatorLabel) then
		tooltip = _T(tooltip)
	end

	local result        = false
	local disblaed_cond = opts.disabled
	if (disblaed_cond ~= nil) then
		ImGui.BeginDisabled(disblaed_cond)
	end

	local config_value
	if (_type == eGridItemType.CHECKBOX) then
		config_value         = gvar and table.get_nested_value(g_table, gvar) or false
		config_value, result = GUI:CustomToggle(label, config_value, { tooltip = tooltip })
		outSize              = vec2:new(ImGui.CalcTextSize(label) + 90, ImGui.GetTextLineHeightWithSpacing())
		if (result) then
			table.set_nested_value(g_table, self.m_gvar, config_value)
		end
	elseif (_type == eGridItemType.BUTTON) then
		result  = GUI:Button(label, { tooltip = tooltip, repeatable = opts.buttonRepeat })
		outSize = vec2:new(ImGui.GetItemRectSize())
	elseif (_type == eGridItemType.RADIO_BUTTON) then
		config_value         = gvar and table.get_nested_value(g_table, gvar) or 0
		config_value, result = ImGui.RadioButton(label, config_value, opts.finalValue)
		outSize              = vec2:new(ImGui.GetItemRectSize())
		if (tooltip) then
			GUI:Tooltip(tooltip)
		end
		if (result and gvar) then
			table.set_nested_value(g_table, gvar, config_value)
		end
	elseif (_type == eGridItemType.NEW_LINE) then
		ImGui.NewLine()
		outSize = vec2:zero()
	end

	if (disblaed_cond ~= nil) then
		ImGui.EndDisabled()
	end

	if (result and type(opts.onClick) == "function") then
		pcall(opts.onClick)
	end

	if (config_value and type(opts.onTrue) == "function") then
		pcall(opts.onTrue)
	end

	return outSize
end

--#endregion


--#region GridRenderer

--------------------------------------
-- Class: GridRenderer
--------------------------------------
-- Renders ImGui widgets (buttons, checkboxes, radio buttons) in a grid layout.
---@class GridRenderer
---@field private m_columns number
---@field private m_elements GridItem[]
---@field private m_padding vec2
---@field private m_total_width number
---@field private m_total_height number
---@field private m_max_width number
---@field private m_max_height number
---@field private m_hash_map set<joaat_t>
---@overload fun(columns: integer, padding_x?: float, padding_y?: float) : GridRenderer
local GridRenderer = Callable("GridRenderer")

---@param columns integer The number of columns in the grid. Defaults to 1.
---@param padding_x? float Horizontal padding *(default: 10)*.
---@param padding_y? float Vertical padding *(default: 10)*.
---@return GridRenderer
function GridRenderer.new(columns, padding_x, padding_y)
	return MakeInstance({
		m_columns      = columns or 1,
		m_padding      = vec2:new(padding_x or 10, padding_y or 10),
		m_elements     = {},
		m_hash_map     = {},
		m_total_width  = 0,
		m_total_height = 0,
		m_max_width    = 0,
		m_max_height   = 0,
	}, GridRenderer)
end

---@param item GridItem
function GridRenderer:DoesItemExist(item)
	return self.m_hash_map[item.m_uid] == true
end

---@param item_type eGridItemType
---@param item_label string
---@param global_variable? string The variable's name that will be controlled by your ImGui item.
---@param opts? GridItemParams
---@overload fun(self: GridRenderer, item_type: 0, item_label: string, global_variable: string, opts?: GridItemCheckboxParams): boolean
---@overload fun(self: GridRenderer, item_type: 1, item_label: string, global_variable: nil, opts?: GridItemButtonParams): boolean
---@overload fun(self: GridRenderer, item_type: 2, item_label: string, global_variable: nil, opts?: GridItemRadioParams): boolean
---@overload fun(self: GridRenderer, item_type: 3): true
---@return boolean
function GridRenderer:AddItem(item_type, item_label, global_variable, opts)
	local gridItem = GridItem.new(item_type, item_label, global_variable, opts)
	if (item_type ~= eGridItemType.NEW_LINE and self:DoesItemExist(gridItem)) then
		return false
	end

	table.insert(self.m_elements, gridItem)
	self.m_hash_map[gridItem.m_uid] = true
	return true
end

---@param label string
---@param global_variable string The variable that will be controlled by the checkbox.
---@param opts? GridItemCheckboxParams
function GridRenderer:AddCheckbox(label, global_variable, opts)
	self:AddItem(eGridItemType.CHECKBOX, label, global_variable, opts)
end

---@param label string
---@param opts? GridItemButtonParams
function GridRenderer:AddButton(label, opts)
	self:AddItem(eGridItemType.BUTTON, label, nil, opts)
end

---@param label string
---@param opts? GridItemRadioParams
function GridRenderer:AddRadioButton(label, opts)
	self:AddItem(eGridItemType.RADIO_BUTTON, label, nil, opts)
end

function GridRenderer:AddNewLine()
	self:AddItem(eGridItemType.NEW_LINE)
end

function GridRenderer:Draw()
	local current_x = ImGui.GetCursorPosX()
	local current_y = ImGui.GetCursorPosY()
	local start_x   = current_x

	for i, item in ipairs(self.m_elements) do
		ImGui.PushID(i)
		ImGui.SetCursorPos(current_x, current_y)
		local item_size = item:Draw() + self.m_padding

		local fine_tune_t = item.m_fine_tuning_data
		if (fine_tune_t) then
			local can_edit  = true
			local cond      = fine_tune_t.condition
			local cond_type = type(cond)
			if (cond_type == "function") then
				can_edit = cond()
			elseif (cond_type == "boolean") then
				can_edit = cond
			end

			if (can_edit) then
				ImGui.SetCursorPos(current_x + item_size.x - 45, current_y + 10)
				ImGui.SetWindowFontScale(0.75)
				if (ImGui.SmallButton(" . . . ")) then
					pcall(fine_tune_t.callback)
				end
				ImGui.SetWindowFontScale(1.0)
				GUI:Tooltip(_T("GENERIC_OPTIONS_LABEL"))
			end
		end

		if (item_size.x > self.m_max_width) then
			self.m_max_width = item_size.x
		end

		if (self.m_columns > 1) then
			if (i % self.m_columns == 0) then
				current_x = start_x
				current_y = current_y + item_size.y
			else
				current_x = current_x + self.m_max_width
			end
		else
			ImGui.SameLine()
			if (current_x + self.m_max_width > ImGui.GetContentRegionAvail()) then
				current_x = start_x
				current_y = current_y + item_size.y
			else
				current_x = current_x + self.m_max_width
			end
		end

		self.m_max_height = math.max(self.m_max_height, item_size.y)
		ImGui.PopID()
	end

	self.m_total_width  = current_x + self.m_max_width
	self.m_total_height = current_y + self.m_max_height
	ImGui.Spacing()
end

return GridRenderer

--#endregion
