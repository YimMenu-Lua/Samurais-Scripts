---@class Audio
---@field Emitters table<string, { name: string, default_station: string }> Static Emitters.
---@field ActiveEmitters table<string, { name: string, default_station: string, current_station: string, source: handle, coords: vec3 }> A list of enabled emitters and the entities they are linked to.
Audio = { ActiveEmitters = {} }
Audio.__index = Audio

---@param emitter table
---@param toggle boolean
---@param entity? integer
---@param station? string
function Audio:ToggleEmitter(emitter, toggle, entity, station)
	script.run_in_fiber(function(s)
		if (emitter and self.ActiveEmitters[emitter.name]) then
			AUDIO.SET_EMITTER_RADIO_STATION(emitter.name, self.ActiveEmitters[emitter.name].default_station)
			AUDIO.SET_STATIC_EMITTER_ENABLED(emitter.name, false)
			self.ActiveEmitters[emitter.name] = nil
			s:sleep(250)
		end

		if (not toggle) then
			return
		end

		if (not Game.IsOnline()) then
			AUDIO.SET_AUDIO_FLAG("LoadMPData", true)
		end

		if (type(emitter) == "string") then
			emitter = self.Emitters[emitter] or { name = emitter, default_station = station }
		end

		entity  = entity or Self:GetHandle()
		emitter = emitter or self.Emitters.rave_1
		station = station or emitter.default_station

		AUDIO.SET_STATIC_EMITTER_ENABLED(emitter.name, true)
		AUDIO.SET_EMITTER_RADIO_STATION(emitter.name, station)
		AUDIO.LINK_STATIC_EMITTER_TO_ENTITY(emitter.name, entity)

		self.ActiveEmitters[emitter.name] = {
			name = emitter.name,
			default_station = emitter.default_station,
			current_station = station,
			source = entity,
			coords = Game.GetEntityCoords(entity, false)
		}
	end)
end

---@param toggle boolean
---@param station? string
function Audio:BlastRadio(toggle, station)
	Audio:ToggleEmitter(
		self.Emitters.radio_high,
		toggle,
		Self:GetHandle(),
		station
	)
end

---@param toggle boolean
---@param entity? integer
function Audio:PartyMode(toggle, entity)
	for i = 1, 4 do
		Audio:ToggleEmitter(
			self.Emitters["rave_" .. i],
			toggle,
			entity,
			"RADIO_30_DLC_HEI4_MIX1_REVERB"
		)
	end
end

---@return boolean
function Audio:AreAnyEmittersEnabled()
	return next(self.ActiveEmitters) ~= nil
end

function Audio:StopAllEmitters()
	if self:AreAnyEmittersEnabled() then
		for _, emitter in pairs(self.ActiveEmitters) do
			AUDIO.SET_EMITTER_RADIO_STATION(emitter.name, emitter.default_station)
			AUDIO.SET_STATIC_EMITTER_ENABLED(emitter.name, false)
		end

		self.ActiveEmitters = {}
	end
end

---@param vehicle integer
---@param isLoud? boolean
function Audio.PlayExhaustPop(vehicle, isLoud)
	if (not vehicle or not ENTITY.DOES_ENTITY_EXIST(vehicle)) then
		return
	end

	local soundName = isLoud and "SNIPER_FIRE" or "BOOT_POP"
	local soundRef = isLoud and "DLC_BIKER_RESUPPLY_MEET_CONTACT_SOUNDS" or "DLC_VW_BODY_DISPOSAL_SOUNDS"

	AUDIO.PLAY_SOUND_FROM_ENTITY(
		-1,
		soundName,
		vehicle,
		soundRef,
		true,
		0
	)
end

Audio.Emitters = {
	rave_1 = {
		name = "SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_01_LEFT",
		default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
	},
	rave_2 = {
		name = "SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_02_RIGHT",
		default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
	},
	rave_3 = {
		name = "SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_03_REVERB",
		default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
	},
	rave_4 = {
		name = "SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_04_REVERB",
		default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
	},
	muffled = {
		name = "SE_BA_DLC_CLUB_EXTERIOR",
		default_station = "RADIO_22_DLC_BATTLE_MIX1_CLUB"
	},
	muffled_2 = {
		name = "DLC_TUNER_MEET_BUILDING_MUSIC",
		default_station = "RADIO_07_DANCE_01"
	},
	muffled_3 = {
		name = "SE_DLC_BIKER_TEQUILALA_EXTERIOR_EMITTER",
		default_station = "HIDDEN_RADIO_04_PUNK"
	},
	radio_low = {
		name = "DLC_MPSUM2_AUTO_STORE_MUSIC",
		default_station = "RADIO_22_DLC_BATTLE_MIX1_RADIO"
	},
	radio_medium = {
		name = "SE_DLC_FIXER_INVESTIGATION_WAY_IN_MUSIC_01",
		default_station = "HIDDEN_RADIO_09_HIPHOP_OLD"
	},
	radio_high = {
		name = "SE_DLC_FIXER_DATA_LEAK_MANSION_SPEAKER_09",
		default_station = "RADIO_07_DANCE_01"
	},
	special = {
		name = "DLC_TUNER_MEET_BUILDING_ENGINES",
		default_station = ""
	},
	test = {
		name = "SE_DLC_BTL_YACHT_EXTERIOR_01",
		default_station = "HIDDEN_RADIO_07_DANCE_01"
	},
	test_2 = {
		name = "se_dlc_hei4_island_beach_party_music_new_03_reverb",
		default_station = "RADIO_30_DLC_HEI4_MIX1_REVERB"
	},
}
