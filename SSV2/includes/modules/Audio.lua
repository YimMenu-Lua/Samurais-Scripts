---@class ActiveEmitter
---@field name string
---@field default_station string
---@field current_station string
---@field source handle
---@field coords vec3

---@class Audio
---@field StaticEmitters table<string, { name: string, default_station: string }>
---@field private m_frontend_sound_id integer
---@field private m_active_emitters table<string, ActiveEmitter> A list of enabled emitters and the entities they are linked to.
Audio = { m_active_emitters = {} }
Audio.__index = Audio

---@param emitter table
---@param toggle boolean
---@param entity? integer
---@param station? string
function Audio:ToggleEmitter(emitter, toggle, entity, station)
	script.run_in_fiber(function(s)
		if (emitter and self.m_active_emitters[emitter.name]) then
			AUDIO.SET_EMITTER_RADIO_STATION(emitter.name, self.m_active_emitters[emitter.name].default_station)
			AUDIO.SET_STATIC_EMITTER_ENABLED(emitter.name, false)
			self.m_active_emitters[emitter.name] = nil
			s:sleep(250)
		end

		if (not toggle) then
			return
		end

		if (not Game.IsOnline()) then
			AUDIO.SET_AUDIO_FLAG("LoadMPData", true)
		end

		if (type(emitter) == "string") then
			emitter = self.StaticEmitters[emitter] or { name = emitter, default_station = station }
		end

		entity  = entity or Self:GetHandle()
		emitter = emitter or self.StaticEmitters.rave_1
		station = station or emitter.default_station

		AUDIO.SET_STATIC_EMITTER_ENABLED(emitter.name, true)
		AUDIO.SET_EMITTER_RADIO_STATION(emitter.name, station)
		AUDIO.LINK_STATIC_EMITTER_TO_ENTITY(emitter.name, entity)

		self.m_active_emitters[emitter.name] = {
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
		self.StaticEmitters.radio_high,
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
			self.StaticEmitters["rave_" .. i],
			toggle,
			entity,
			"RADIO_30_DLC_HEI4_MIX1_REVERB"
		)
	end
end

---@return boolean
function Audio:AreAnyEmittersEnabled()
	return next(self.m_active_emitters) ~= nil
end

function Audio:StopAllEmitters()
	if self:AreAnyEmittersEnabled() then
		for _, emitter in pairs(self.m_active_emitters) do
			AUDIO.SET_EMITTER_RADIO_STATION(emitter.name, emitter.default_station)
			AUDIO.SET_STATIC_EMITTER_ENABLED(emitter.name, false)
		end

		self.m_active_emitters = {}
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

---@param speech_name string
---@param voice_name string
---@param position vec3
---@param speech_params? string
function Audio:PlaySpeechFromPosition(speech_name, voice_name, position, speech_params)
	AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(
		speech_name,
		voice_name,
		position.x,
		position.y,
		position.z,
		speech_params or "SPEECH_PARAMS_FORCE"
	)
end

Audio.StaticEmitters = {
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

Audio.RadioStations = {
	{ station = "RADIO_11_TALK_02",               name = "Blaine County Radio" },
	{ station = "RADIO_21_DLC_XM17",              name = "Blonded Los Santos 97.8 FM" },
	{ station = "RADIO_04_PUNK",                  name = "Channel X" },
	{ station = "RADIO_08_MEXICAN",               name = "East Los FM" },
	{ station = "RADIO_14_DANCE_02",              name = "FlyLo FM" },
	{ station = "RADIO_23_DLC_XM19_RADIO",        name = "iFruit Radio" },
	{ station = "RADIO_34_DLC_HEI4_KULT",         name = "Kult FM" },
	{ station = "RADIO_01_CLASS_ROCK",            name = "Los Santos Rock Radio" },
	{ station = "RADIO_22_DLC_BATTLE_MIX1_RADIO", name = "Los Santos Underground Radio" },
	{ station = "RADIO_36_AUDIOPLAYER",           name = "Media Player" },
	{ station = "RADIO_02_POP",                   name = "Non-Stop-Pop FM" },
	{ station = "RADIO_03_HIPHOP_NEW",            name = "Radio Los Santos" },
	{ station = "RADIO_16_SILVERLAKE",            name = "Radio Mirror Park" },
	{ station = "RADIO_30_DLC_HEI4_MIX1_REVERB",  name = "Rave DJ Set" },
	{ station = "RADIO_06_COUNTRY",               name = "Rebel Radio" },
	{ station = "RADIO_19_USER",                  name = "Self Radio" },
	{ station = "RADIO_07_DANCE_01",              name = "Soulwax FM" },
	{ station = "RADIO_17_FUNK",                  name = "Space 103.2" },
	{ station = "RADIO_27_DLC_PRHEI4",            name = "Still Slipping Los Santos" },
	{ station = "RADIO_12_REGGAE",                name = "The Blue Ark" },
	{ station = "RADIO_20_THELAB",                name = "The Lab" },
	{ station = "RADIO_15_MOTOWN",                name = "The Lowdown 9.11" },
	{ station = "RADIO_35_DLC_HEI4_MLR",          name = "The Music Locker" },
	{ station = "HIDDEN_RADIO_STRIP_CLUB",        name = "Vanilla Unicorn" },
	{ station = "RADIO_18_90S_ROCK",              name = "Vinewood Boulevard Radio" },
	{ station = "RADIO_09_HIPHOP_OLD",            name = "West Coast Classics" },
	{ station = "RADIO_05_TALK_01",               name = "West Coast Talk Radio" },
	{ station = "RADIO_13_JAZZ",                  name = "Worldwide FM" },
}
