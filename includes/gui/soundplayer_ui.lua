---@diagnostic disable

local s_SoundSearchQuery   = ""
local i_SoundIndex1        = 0
local i_SoundIndex2        = 0
local i_SoundSwitch        = 0
local i_RadioIndex         = 0
local b_DisableRadioButton = false
local b_IsPlayingRadio     = false
local b_SoundBtnOff        = false
local t_SelectedSound      = {}
local s_SelectedRadio      = {}
local t_PedSpeeches <const> = {
    male = {
        { name = "Angry Chinese",     soundName = "GENERIC_INSULT_HIGH",      soundRef = "MP_M_SHOPKEEP_01_CHINESE_MINI_01" },
        { name = "Begging Chinese",   soundName = "GUN_BEG",                  soundRef = "MP_M_SHOPKEEP_01_CHINESE_MINI_01" },
        { name = "Call The Cops!",    soundName = "PHONE_CALL_COPS",          soundRef = "MP_M_SHOPKEEP_01_CHINESE_MINI_01" },
        { name = "CHARGE!!",          soundName = "GENERIC_WAR_CRY",          soundRef = "S_M_Y_BLACKOPS_01_BLACK_MINI_01" },
        { name = "Creep",             soundName = "SHOUT_PERV_AT_WOMAN_PERV", soundRef = "A_M_Y_MEXTHUG_01_LATINO_FULL_01" },
        { name = "Clown Dying",       soundName = "CLOWN_DEATH",              soundRef = "CLOWNS" },
        { name = "Clown Laughing",    soundName = "CLOWN_LAUGH",              soundRef = "CLOWNS" },
        { name = "Franklin Laughing", soundName = "LAUGH",                    soundRef = "WAVELOAD_PAIN_FRANKLIN" },
        { name = "How are you?",      soundName = "GENERIC_HOWS_IT_GOING",    soundRef = "S_M_M_PILOT_01_WHITE_FULL_01" },
        { name = "Insult",            soundName = "GENERIC_INSULT_HIGH",      soundRef = "S_M_Y_SHERIFF_01_WHITE_FULL_01" },
        { name = "Insult 02",         soundName = "GENERIC_FUCK_YOU",         soundRef = "FRANKLIN_DRUNK" },
        { name = "Pain",              soundName = "ELECTROCUTION",            soundRef = "MISTERK" },
        { name = "Pain 02",           soundName = "TOOTHPULL_PAIN",           soundRef = "MISTERK" },
        { name = "Threaten",          soundName = "CHALLENGE_THREATEN",       soundRef = "S_M_Y_BLACKOPS_01_BLACK_MINI_01" },
        { name = "You Look Stupid!",  soundName = "FRIEND_LOOKS_STUPID",      soundRef = "FRANKLIN_DRUNK" },
    },
    female = {
        { name = "Blowjob",        soundName = "SEX_ORAL",                   soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
        { name = "Call The Cops!", soundName = "PHONE_CALL_COPS",            soundRef = "A_F_M_SALTON_01_WHITE_FULL_01" },
        { name = "Hooker Offer",   soundName = "HOOKER_OFFER_SERVICE",       soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
        { name = "How are you?",   soundName = "GENERIC_HOWS_IT_GOING",      soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
        { name = "Insult",         soundName = "GENERIC_INSULT_HIGH",        soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
        { name = "Let's Go!",      soundName = "CHALLENGE_ACCEPTED_GENERIC", soundRef = "A_F_M_SALTON_01_WHITE_FULL_01" },
        { name = "Moan",           soundName = "SEX_GENERIC_FEM",            soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
        { name = "Roast",          soundName = "GAME_HECKLE",                soundRef = "A_F_M_SALTON_01_WHITE_FULL_01" },
        { name = "Threaten",       soundName = "CHALLENGE_THREATEN",         soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
    }
}

local function DisplayMaleSounds()
    t_FilteredMaleSounds = {}
    for _, v in ipairs(t_PedSpeeches.male) do
        table.insert(t_FilteredMaleSounds, v.name)
    end
    i_SoundIndex1, used = ImGui.Combo("##maleSounds", i_SoundIndex1, t_FilteredMaleSounds, #t_PedSpeeches.male)
end

local function DisplayFemaleSounds()
    t_FilteredFemaleSounds = {}
    for _, v in ipairs(t_PedSpeeches.female) do
        table.insert(t_FilteredFemaleSounds, v.name)
    end
    i_SoundIndex2, used = ImGui.Combo("##femaleSounds", i_SoundIndex2, t_FilteredFemaleSounds, #t_PedSpeeches.female)
end

local function DisplayRadioStations()
    t_FilteredRadios = {}
    for _, v in ipairs(t_RadioStations) do
        table.insert(t_FilteredRadios, v.name)
    end
    i_RadioIndex, used = ImGui.Combo("##radioStations", i_RadioIndex, t_FilteredRadios, #t_RadioStations)
end

---------------- debug stuff ------------------
local i_SoundID, i_SoundIndex = -1, 1
local b_HasSoundFinished = false

local function ReadSoundsFile()
    if not io.exists("soundNames.json") then
        YimToast:ShowError(
            "Samurai's Scripts",
            "[FATAL] Json file not found!"
        )
        return
    end

    local jsonFile, _ = io.open("soundNames.json", "r")
    if jsonFile ~= nil then
        local content = jsonFile:read("*all")
        jsonFile:close()
        return CFG:Decode(content, nil, false)
    end
end

local t_AllFrontendSounds = SS_debug and ReadSoundsFile() or nil
local function FilterFrontendSounds()
    t_FilteredFrontendSounds = {}
    if t_AllFrontendSounds ~= nil then
        for _, v in ipairs(t_AllFrontendSounds) do
            if string.find(v.AudioName:lower(), s_SoundSearchQuery) then
                table.insert(t_FilteredFrontendSounds, v)
            end
        end
    end
end

local function DisplayFrontendSounds()
    FilterFrontendSounds()
    local t_AllFrontendSoundNames = {}
    for _, v in ipairs(t_FilteredFrontendSounds) do
        table.insert(t_AllFrontendSoundNames, v.AudioName)
    end
    i_SoundIndex, siused = ImGui.ListBox("##sounds", i_SoundIndex, t_AllFrontendSoundNames, #t_FilteredFrontendSounds)
end
---------------------------------------------

function SoundPlayerUI()
    ImGui.Spacing(); ImGui.SeparatorText("Human Sounds"); ImGui.Spacing()
    ImGui.Dummy(20, 1); ImGui.SameLine(); i_SoundSwitch, isChanged = ImGui.RadioButton(_T("MALE_SOUNDS_"),
        i_SoundSwitch, 0); ImGui
        .SameLine()
    if isChanged then
        UI.WidgetSound("Nav")
    end
    ImGui.Dummy(20, 1); ImGui.SameLine(); i_SoundSwitch, isChanged = ImGui.RadioButton(_T("FEMALE_SOUNDS_"),
        i_SoundSwitch, 1)
    if isChanged then
        UI.WidgetSound("Nav")
    end
    ImGui.Spacing()
    if i_SoundSwitch == 0 then
        ImGui.PushItemWidth(280)
        DisplayMaleSounds()
        ImGui.PopItemWidth()
        t_SelectedSound = t_PedSpeeches.male[i_SoundIndex1 + 1]
    else
        ImGui.PushItemWidth(280)
        DisplayFemaleSounds()
        ImGui.PopItemWidth()
        t_SelectedSound = t_PedSpeeches.female[i_SoundIndex2 + 1]
    end
    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()

    if b_SoundBtnOff then
        ImGui.BeginDisabled()
        ImGui.Button(string.format(" %s ", s_LoadingLabel), 60, 30)
        ImGui.EndDisabled()
    else
        if ImGui.Button(string.format("%s##sounds", _T("GENERIC_PLAY_BTN_"))) then
            script.run_in_fiber(function(playsnd)
                local myCoords = Game.GetEntityCoords(Self.GetPedID(), true)
                AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(t_SelectedSound.soundName, t_SelectedSound.soundRef,
                    myCoords.x,
                    myCoords.y, myCoords.z, "SPEECH_PARAMS_FORCE")
                b_SoundBtnOff = true
                b_ShouldAnimateLoadingLabel = true
                playsnd:sleep(5000)
                b_SoundBtnOff = false
                b_ShouldAnimateLoadingLabel = false
            end)
        end
    end

    ImGui.Dummy(1, 10); ImGui.SeparatorText("Radio Stations")
    UI.Tooltip(_T("RADIO_STATIONS_DESC_"))
    ImGui.Spacing()
    ImGui.SetNextItemWidth(280)
    DisplayRadioStations()

    s_SelectedRadio = t_RadioStations[i_RadioIndex + 1]

    ImGui.SameLine()
    ImGui.Spacing()
    ImGui.SameLine()

    if not b_DisableRadioButton then
        if not b_IsPlayingRadio then
            if ImGui.Button(string.format("%s##radio", _T("GENERIC_PLAY_BTN_"))) then
                script.run_in_fiber(function(rad)
                    if YimActions:IsPedPlaying(self.get_ped()) then
                        YimToast:ShowError(
                            "Samurais Scripts",
                            "This option is disabled while using YimActions."
                        )
                        return
                    end

                    Game.Audio:BlastRadio(true, s_SelectedRadio.station)
                    b_IsPlayingRadio = true
                    b_DisableRadioButton = true
                    b_ShouldAnimateLoadingLabel = true
                    rad:sleep(1500)
                    b_DisableRadioButton = false
                    b_ShouldAnimateLoadingLabel = false
                end)
            end
        else
            if ImGui.Button(string.format("%s##sounds", _T("GENERIC_STOP_BTN_"))) then
                script.run_in_fiber(function(rad)
                    Game.Audio:BlastRadio(false)
                    b_IsPlayingRadio = false
                    b_DisableRadioButton = true
                    b_ShouldAnimateLoadingLabel = true
                    rad:sleep(1500)
                    b_DisableRadioButton = false
                    b_ShouldAnimateLoadingLabel = false
                end)
            end
        end
    else
        ImGui.BeginDisabled()
        ImGui.Button(string.format(" %s ", s_LoadingLabel), 60, 30)
        ImGui.EndDisabled()
    end

    if SS_debug then
        ImGui.Dummy(1, 10)
        ImGui.SeparatorText("Frontend Sounds")
        ImGui.PushItemWidth(420)
        s_SoundSearchQuery, _ = ImGui.InputTextWithHint("##search", "Search Sounds", s_SoundSearchQuery, 64)
        b_IsTyping = ImGui.IsItemActive()
        DisplayFrontendSounds()
        ImGui.PopItemWidth()

        if t_FilteredFrontendSounds then
            t_SelectedSound = t_FilteredFrontendSounds[i_SoundIndex + 1]
        end

        ImGui.Spacing()
        ImGui.PushButtonRepeat(true)
        if ImGui.Button(" + ") then
            if i_SoundIndex == #t_FilteredFrontendSounds - 1 then
                i_SoundIndex = 0
            end
            i_SoundIndex = i_SoundIndex + 1
        end

        ImGui.SameLine()
        if ImGui.Button(" - ") then
            if i_SoundIndex == 0 then
                i_SoundIndex = #t_FilteredFrontendSounds
            end
            i_SoundIndex = i_SoundIndex - 1
        end

        ImGui.PopButtonRepeat()
        ImGui.PopItemWidth()
        ImGui.Spacing()
        ImGui.BeginDisabled(not t_SelectedSound)
            ImGui.BeginDisabled(b_HasSoundFinished)
            if ImGui.Button("  Play  ") then
                script.run_in_fiber(function()
                    i_SoundID = AUDIO.GET_SOUND_ID()
                    AUDIO.PLAY_SOUND_FRONTEND(i_SoundID, t_SelectedSound.AudioName, t_SelectedSound.AudioRef, true)
                end)
            end
            ImGui.EndDisabled()

            ImGui.SameLine()
            ImGui.BeginDisabled(b_HasSoundFinished)
            if ImGui.Button("  Stop  ") then
                script.run_in_fiber(function()
                    AUDIO.STOP_SOUND(i_SoundID)
                    AUDIO.RELEASE_SOUND_ID(i_SoundID)
                end)
            end
            ImGui.EndDisabled()

            if ImGui.Button("  Print  ") then
                log.debug(
                string.format(
                    "\n\"%s\", \"%s\"",
                        string.upper(t_SelectedSound.AudioName),
                        string.upper(t_SelectedSound.AudioRef)))
            end
        ImGui.EndDisabled()
    end
end

if SS_debug then
    script.register_looped("Sound Checker", function()
        b_HasSoundFinished = AUDIO.HAS_SOUND_FINISHED(i_SoundID)
    end)
end
