local FeatureBase = require("includes.modules.FeatureBase")

---@class WorldMisc : FeatureBase
---@field private m_entity World
---@field private m_active boolean
---@field public m_bounds_extended boolean	-- bad idea. should've used a shared state instead of juggling bools
---@field public m_ocean_waves_disabled boolean
---@field public m_flight_music_disabled boolean
---@field public m_wanted_music_disabled boolean -- well now I'm too deep. fml
local WorldMisc = setmetatable({}, FeatureBase)
WorldMisc.__index = WorldMisc

---@param ent any
---@return WorldMisc
function WorldMisc.new(ent)
	local self = FeatureBase.new(ent)
	---@diagnostic disable-next-line
	return setmetatable(self, WorldMisc)
end

function WorldMisc:Init()
	self.m_active                = false
	self.m_bounds_extended       = false
	self.m_ocean_waves_disabled  = false
	self.m_flight_music_disabled = false
	self.m_wanted_music_disabled = false
end

function WorldMisc:ShouldRun()
	return (not Backend:IsPlayerSwitchInProgress()
		and not script.is_active("maintransition")
	)
end

function WorldMisc:Cleanup()
	self.m_entity:ResetBounds()
	self.m_entity:ResetOceanWaves()
	self.m_bounds_extended       = false
	self.m_ocean_waves_disabled  = false
	self.m_flight_music_disabled = false
	self.m_wanted_music_disabled = false
end

function WorldMisc:Update()
	if (GVars.features.world.extend_bounds and not self.m_bounds_extended) then
		self.m_entity:ExtendBounds()
	end

	if (GVars.features.world.disable_ocean_waves and not self.m_ocean_waves_disabled) then
		self.m_entity:DisableOceanWaves()
	end

	if (GVars.features.world.disable_flight_music and not self.m_flight_music_disabled) then
		AUDIO.SET_AUDIO_FLAG("DisableFlightMusic", true)
	end

	if (GVars.features.world.disable_wanted_music and not self.m_wanted_music_disabled) then
		AUDIO.SET_AUDIO_FLAG("WantedMusicDisabled", true)
	end
end

return WorldMisc
