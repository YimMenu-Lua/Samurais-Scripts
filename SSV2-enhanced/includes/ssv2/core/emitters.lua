local Emitters = {}; Emitters.__index = Emitters
local rave = {
    'SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_01_LEFT', 'SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_02_RIGHT',
    'SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_03_REVERB', 'SE_DLC_HEI4_ISLAND_BEACH_PARTY_MUSIC_NEW_04_REVERB' }
local default = 'RADIO_30_DLC_HEI4_MIX1_REVERB'
function Emitters.new() return setmetatable({ owned = {} }, Emitters) end

function Emitters:party(owner, enabled, station)
    if enabled and not network.is_session_started() then AUDIO.SET_AUDIO_FLAG('LoadMPData', true) end
    for _, name in ipairs(rave) do
        if enabled then
            self.owned[name] = owner
            AUDIO.SET_STATIC_EMITTER_ENABLED(name, true)
            AUDIO.SET_EMITTER_RADIO_STATION(name, station or default)
            AUDIO.LINK_STATIC_EMITTER_TO_ENTITY(name, owner)
        elseif self.owned[name] == owner then
            AUDIO.SET_EMITTER_RADIO_STATION(name, default)
            AUDIO.SET_STATIC_EMITTER_ENABLED(name, false)
            self.owned[name] = nil
        end
    end
end

function Emitters:clear()
    for name in pairs(self.owned) do
        AUDIO.SET_EMITTER_RADIO_STATION(name, default); AUDIO.SET_STATIC_EMITTER_ENABLED(name, false)
    end
    self.owned = {}
end

return Emitters
