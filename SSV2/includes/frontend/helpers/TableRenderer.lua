-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local RED <const>                = Color.RED
local PURPLE <const>             = Color("purple")
local ORANGE <const>             = Color("orange")
local REF_COUNT                  = 0

local TokenTypes <const>         = {
	["boolean"] = "boolean",
	["nil"]     = "nil",
	["number"]  = "number",
	["string"]  = "string",
	["table"]   = "table",
	default     = "unk"
}

local TokenColors <const>        = {
	["boolean"] = Color.BLUE,
	["nil"]     = PURPLE,
	["number"]  = Color("yellow"):Brighten(0.4),
	["string"]  = ORANGE,
	default     = PURPLE
}

---@class TableRendererToken
---@field m_type "number"|"string"|"boolean"|"table"|"unk"
---@field m_color Color
local TableRendererToken <const> = {}
TableRendererToken.__index       = TableRendererToken

function TableRendererToken.new(value)
	local _type = type(value)
	return setmetatable({
		m_type  = Match(_type, TokenTypes),
		m_color = Match(_type, TokenColors)
	}, TableRendererToken)
end

---@class TableRenderer
---@field private m_uid joaat_t
local TableRenderer <const> = {}
TableRenderer.__index = TableRenderer

---@return TableRenderer
function TableRenderer.new()
	REF_COUNT = REF_COUNT + 1
	local uid = _J("TABLE_RENDERER_" .. REF_COUNT)
	return setmetatable({ m_uid = uid }, TableRenderer)
end

---@private
---@param value anyval
---@param isKey boolean
function TableRenderer:DrawObject(value, isKey)
	local token = TableRendererToken.new(value)
	local color = token.m_color
	local v     = type(value) == "string" and _F('"%s"', value) or tostring(value)
	if (not isKey) then
		ImGui.TextColored(color.r, color.g, color.b, color.a, v)
		return
	end

	ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 0, 0)
	ImGui.TextColored(PURPLE.r, PURPLE.g, PURPLE.b, PURPLE.a, "[")
	ImGui.SameLine()
	ImGui.TextColored(color.r, color.g, color.b, color.a, v)
	ImGui.SameLine()
	ImGui.TextColored(PURPLE.r, PURPLE.g, PURPLE.b, PURPLE.a, "]")
	ImGui.PopStyleVar()
end

---@param value any
---@param depth integer
---@param seen? set<table>
function TableRenderer:DrawValue(value, depth, seen)
	seen = seen or {}
	local valueType = type(value)

	if (valueType ~= "table") then
		self:DrawObject(value, false)
		return
	end

	if (seen[value]) then
		ImGui.TextColored(RED.r, RED.g, RED.b, RED.a, "<circular_reference>")
		return
	end

	seen[value] = true

	ImGui.Text("{")
	ImGui.Indent()

	for k, v in pairs(value) do
		self:DrawObject(k, true)
		ImGui.SameLine()
		ImGui.Text("=")
		ImGui.SameLine()
		self:DrawValue(v, depth + 1, seen)
	end

	ImGui.Unindent()
	ImGui.Text("}")
end

---@param data table
---@param size vec2
function TableRenderer:Draw(data, size)
	ImGui.PushStyleColor(ImGuiCol.ChildBg, 0.01, 0.0, 0.0, 1.0)
	ImGui.PushStyleVar(ImGuiStyleVar.ScrollbarSize, 11.3)
	ImGui.PushID(self.m_uid)
	ImGui.BeginChildEx("##tableRenderer", size, ImGuiChildFlags.Borders)
	self:DrawValue(data, 0, {})
	ImGui.EndChild()
	ImGui.PopStyleColor()
	ImGui.PopStyleVar()
	ImGui.PopID()
end

return TableRenderer
