---@diagnostic disable

---------------- debug stuff ------------------
local sound_id, sound_index = -1, 1
local hasSoundFinished = false
local function readSoundsFile()
  if SS_debug then
    if io.exists("soundNames.json") then
      local jsonFile, _ = io.open("soundNames.json", "r")
      if jsonFile ~= nil then
        local content = jsonFile:read("*all")
        jsonFile:close()
        return CFG:decode(content, nil, false)
      end
    else
      error("[FATAL] Json file not found!")
    end
  end
  return nil
end
local all_fe_sounds = readSoundsFile()
local function filterFrontendSounds()
  filteredSounds = {}
  if all_fe_sounds ~= nil then
    ---@diagnostic disable-next-line
    for _, v in ipairs(all_fe_sounds) do
      if string.find(v.AudioName:lower(), sound_search) then
        table.insert(filteredSounds, v)
      end
    end
  end
end
local function displayFrontendSounds()
  filterFrontendSounds()
  local allSoundNames = {}
  for _, v in ipairs(filteredSounds) do
    table.insert(allSoundNames, v.AudioName)
  end
  sound_index, siused = ImGui.ListBox("##sounds", sound_index, allSoundNames, #filteredSounds)
end
---------------------------------------------

function soundPlayerUI()
  ImGui.Spacing(); ImGui.SeparatorText("Human Sounds"); ImGui.Spacing()
  ImGui.Dummy(20, 1); ImGui.SameLine(); sound_switch, isChanged = ImGui.RadioButton(MALE_SOUNDS_, sound_switch, 0); ImGui
      .SameLine()
  if isChanged then
    UI.widgetSound("Nav")
  end
  ImGui.Dummy(20, 1); ImGui.SameLine(); sound_switch, isChanged = ImGui.RadioButton(FEMALE_SOUNDS_, sound_switch, 1)
  if isChanged then
    UI.widgetSound("Nav")
  end
  ImGui.Spacing()
  if sound_switch == 0 then
    ImGui.PushItemWidth(280)
    displayMaleSounds()
    ImGui.PopItemWidth()
    selected_sound = male_sounds_T[sound_index1 + 1]
  else
    ImGui.PushItemWidth(280)
    displayFemaleSounds()
    ImGui.PopItemWidth()
    selected_sound = female_sounds_T[sound_index2 + 1]
  end
  ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
  if sound_btn_off then
    ImGui.BeginDisabled()
    ImGui.Button(string.format(" %s ", loading_label), 60, 30)
    ImGui.EndDisabled()
  else
    if ImGui.Button(string.format("%s##sounds", GENERIC_PLAY_BTN_)) then
      script.run_in_fiber(function(playsnd)
        local myCoords = Game.getCoords(self.get_ped(), true)
        AUDIO.PLAY_AMBIENT_SPEECH_FROM_POSITION_NATIVE(selected_sound.soundName, selected_sound.soundRef, myCoords.x,
          myCoords.y, myCoords.z, "SPEECH_PARAMS_FORCE")
        sound_btn_off = true
        start_loading_anim = true
        playsnd:sleep(5000)
        sound_btn_off = false
        start_loading_anim = false
      end)
    end
  end

  ImGui.Dummy(1, 10); ImGui.SeparatorText("Radio Stations")
  UI.toolTip(false, RADIO_STATIONS_DESC_)
  ImGui.Spacing()
  ImGui.PushItemWidth(280)
  displayRadioStations()
  ImGui.PopItemWidth()
  selected_radio = radio_stations[radio_index + 1]
  if not radio_btn_off then
    ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
    if not is_playing_radio then
      if ImGui.Button(string.format("%s##radio", GENERIC_PLAY_BTN_)) then
        script.run_in_fiber(function(rad)
          if not is_playing_anim then
            play_music(true, selected_radio.station)
            is_playing_radio   = true
            radio_btn_off      = true
            start_loading_anim = true
            rad:sleep(3000)
            radio_btn_off      = false
            start_loading_anim = false
          else
            gui.show_error("Samurais Scripts", "This option is disabled while playing animations to prevent bugs.")
          end
        end)
      end
    else
      if ImGui.Button(string.format("%s##sounds", GENERIC_STOP_BTN_)) then
        script.run_in_fiber(function(rad)
          play_music(false)
          is_playing_radio   = false
          radio_btn_off      = true
          start_loading_anim = true
          rad:sleep(1500)
          radio_btn_off      = false
          start_loading_anim = false
        end)
      end
    end
  else
    ImGui.SameLine(); ImGui.Spacing(); ImGui.SameLine()
    ImGui.BeginDisabled()
    ImGui.Button(string.format(" %s ", loading_label), 60, 30)
    ImGui.EndDisabled()
  end

  if SS_debug then
    ImGui.Dummy(1, 10); ImGui.SeparatorText("Frontend Sounds")
    ImGui.PushItemWidth(420)
    sound_search, sschanged = ImGui.InputTextWithHint("##search", "Search Sounds", sound_search, 64)
    is_typing = ImGui.IsItemActive()
    displayFrontendSounds()
    ImGui.PopItemWidth()
    if filteredSounds ~= nil then
      selected_sound = filteredSounds[sound_index + 1]
    end
    ImGui.Spacing(); ImGui.PushButtonRepeat(true)
    if ImGui.Button(" + ") then
      if sound_index == #filteredSounds - 1 then
        sound_index = 0
      end
      sound_index = sound_index + 1
    end
    ImGui.SameLine()
    if ImGui.Button(" - ") then
      if sound_index == 0 then
        sound_index = #filteredSounds
      end
      sound_index = sound_index - 1
    end
    ImGui.PopButtonRepeat()
    ImGui.PopItemWidth()
    ImGui.Spacing()
    ImGui.BeginDisabled(selected_sound == nil or not hasSoundFinished)
    if ImGui.Button("  Play  ") then
      script.run_in_fiber(function()
        sound_id = AUDIO.GET_SOUND_ID()
        AUDIO.PLAY_SOUND_FRONTEND(sound_id, selected_sound.AudioName, selected_sound.AudioRef, true)
      end)
    end
    ImGui.EndDisabled()
    ImGui.SameLine(); ImGui.BeginDisabled(selected_sound == nil or hasSoundFinished)
    if ImGui.Button("  Stop  ") then
      script.run_in_fiber(function()
        AUDIO.STOP_SOUND(sound_id)
        AUDIO.RELEASE_SOUND_ID(sound_id)
      end)
    end
    ImGui.EndDisabled()
    ImGui.SameLine(); ImGui.BeginDisabled(selected_sound == nil)
    if ImGui.Button("  Print  ") then
      log.debug(string.format("\n\"%s\", \"%s\"", string.upper(selected_sound.AudioName),
        string.upper(selected_sound.AudioRef)))
    end
    ImGui.EndDisabled()
  end
end

if SS_debug then
  script.register_looped("Sound Checker", function()
    hasSoundFinished = AUDIO.HAS_SOUND_FINISHED(sound_id)
  end)
end
