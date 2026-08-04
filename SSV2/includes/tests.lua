--[[
	Mock environment playground.

	Write your code in this file then open the project's folder in a terminal and type: lua samurais_scripts.lua
	
	Must have Lua 5.4 installed.
]]


--[[

local Set = require("includes.classes.Set")

AssertArgs({
	{ Set(),       Set, },    -- pass
	{ vec3:zero(), vec3, },   -- pass
	{ "abc",       "string", }, -- pass
	{ 420,         "integer", }, -- pass
	{ 0.69,        "float", }, -- pass
	{ 123,         "float", }, -- fail
	{ -1e-6,       "number", }, -- pass
	{ LocalPlayer, Player, }, -- pass
	{ LocalPlayer, Vehicle, }, -- fail
	{ LocalPlayer, Ped, },    -- pass
	{ LocalPlayer, Entity, }, -- pass
	{ nullptr,     "pointer", }, -- fail (nullptr is just a dummy table)
}, { test_run = true })

--]]

-- ThreadManager:UpdateMockRoutines()
