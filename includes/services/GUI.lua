---@diagnostic disable: param-type-mismatch

--#region Tab

--------------------------------------
-- Tab Class
--------------------------------------
---@ignore
---@class Tab : ClassMeta<Tab>
---@field private m_name string
---@field private m_gui? function
---@field private m_subtabs? table<string, Tab>
---@field private m_api tab
---@field private m_grid_layout? GridRenderer
---@overload fun(name: string, api_obj?: tab, drawable?: function, subtabs?: Tab) : Tab
local Tab = Class("Tab")

---@param name string
---@param api_obj tab
---@param drawable? function
---@param subtabs? Tab[]
---@return Tab
function Tab.new(name, api_obj, drawable, subtabs)
    return setmetatable(
        {
            m_name    = name,
            m_gui     = drawable,
            m_subtabs = subtabs or {},
            m_api     = api_obj
        },
        Tab
    )
end

---@param name string
---@param drawable? function
---@param subtabs? Tab[]
---@return Tab
function Tab:RegisterSubtab(name, drawable, subtabs)
    assert(
        (type(name) == "string" and #name > 0),
        "Attempt to register a new tab with no name."
    )

    local subtab = Tab(name, nil, drawable, subtabs)
    self.m_subtabs[name] = subtab
    return subtab
end

function Tab:GetSubtab(name)
    return self.m_subtabs[name]
end

function Tab:RegisterGUI(drawable)
    if (type(drawable) ~= "function") then
        return
    end

    if self:HasGUI() then
        -- just warn and proceed
        log.fwarning("%s already had a GUI function. Did you mean to overwrite it?", self:GetName())
    end

    self.m_gui = drawable
end

---@return string
function Tab:GetName()
    return self.m_name
end

---@return boolean
function Tab:HasGUI()
    return (type(self.m_gui) == "function")
end

---@return function
function Tab:GetGUI()
    return self.m_gui
end

---@return tab
function Tab:GetAPI()
    return self.m_api
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
        self.m_grid_layout = GridRenderer.new(
            columns or 5,
            padding_x or 25,
            padding_y or 25
        )
    end

    return self.m_grid_layout
end

---@return boolean
function Tab:HasGridLayout()
    return self.m_grid_layout ~= nil
end

function Tab:RemoveGrid()
    self.m_grid_layout = nil
end

function Tab:RemoveGUI()
    self.m_gui = nil
end

function Tab:ListSubtabs()
    return self.m_subtabs
end

---@param label string
---@param gvar_key string -- A key to insert into GVars (global variables)
---@param on_enable? function
---@param on_disable? function
---@param meta? CommandMeta
function Tab:AddBoolCommand(label, gvar_key, on_enable, on_disable, meta)
    if (type(label) ~= "string" or type(gvar_key) ~= "string") then
        error("AddBoolCommand requires a label and global variable key string.")
    end

    meta = meta or {}
    self:GetOrCreateGrid():AddCheckbox(
        label,
        gvar_key,
        {
            persistent = true,
            tooltip = meta.description,
            onClick = function()
                if (GVars[gvar_key] and type(on_enable) == "function") then
                    on_enable()
                end
                if (not GVars[gvar_key] and type(on_disable) == "function") then
                    on_disable()
                end
            end,
        }
    )

    if (not CommandExecutor) then
        return
    end

    local command_name = label:lower():gsub("%s+", "_")
    CommandExecutor:RegisterCommand(command_name, function()
        GVars[gvar_key] = not GVars[gvar_key]

        if (GVars[gvar_key] and type(on_enable) == "function") then
            on_enable()
        end

        if (not GVars[gvar_key] and type(on_disable) == "function") then
            on_disable()
        end

        CommandExecutor:notify(
            "%s %s",
            label,
            GVars[gvar_key] and "Enabled" or "Disabled"
        )
    end, meta)
end

---@param label string
---@param gvar_key string -- A key to insert into GVars (global variables)
---@param callback function
---@param on_disable? function
---@param meta? CommandMeta
function Tab:AddLoopedCommand(label, gvar_key, callback, on_disable, meta)
    if (type(label) ~= "string" or type(gvar_key) ~= "string") then
        error("AddBoolCommand requires a label and global variable key string.")
    end

    meta = meta or {}
    local command_name = label:lower():gsub("%s+", ""):trim()
    local suspended_thread = not GVars[gvar_key]
    local thread = ThreadManager:CreateNewThread(command_name:upper(), callback, suspended_thread)

    local function toggle()
        if GVars[gvar_key] then
            if thread then thread:Resume() end
        else
            if thread then thread:Suspend() end
            if on_disable then on_disable() end
        end

        CommandExecutor:notify(
            "%s %s.",
            label,
            GVars[gvar_key] and "Enabled" or "Disabled"
        )
    end

    self:GetOrCreateGrid():AddCheckbox(
        label,
        gvar_key,
        {
            persistent = true,
            tooltip = meta.description,
            onClick = toggle,
        }
    )

    if (not CommandExecutor) then
        return
    end

    local command_callback = function()
        GVars[gvar_key] = not GVars[gvar_key]
        toggle()
    end

    CommandExecutor:RegisterCommand(command_name, command_callback, meta)
end

function Tab:Notify(fmt, ...)
    local msg = (... ~= nil) and _F(fmt, ...) or fmt
    Toast:ShowMessage(self:GetName(), msg, false, 5)
end

--#endregion


--#region GUI

--------------------------------------
-- GUI Class
--------------------------------------
---@class GUI : ClassMeta<GUI>
---@field private m_tabs table<string, { this: Tab, api_obj: tab }> 
---@field private m_guis function[] -- Independent GUIs
---@field private m_screen_resolution vec2
local GUI = Class("GUI")

-- Constructor
---@return GUI
function GUI:init()
    local instance = setmetatable({ m_tabs = {}, m_guis = {} }, self)
    instance.m_screen_resolution = Game.GetScreenResolution()
    return instance
end

---@param name string
---@return boolean
function GUI:DoesTabExist(name)
    return self.m_tabs[name] ~= nil
end

---@param name string
---@param drawable? function
---@param subtabs? Tab[]
---@return Tab
function GUI:RegisterNewTab(name, drawable, subtabs)
    assert((not string.isnullorwhitespace(name)), "Attempt to register a new tab with no name.")

    if self:DoesTabExist(name) then
        error(("Tab '%s' already exists."):format(name))
    end

    local api_tab = gui.add_tab(name)
    local newtab  = Tab(name, api_tab, drawable, subtabs)
    self.m_tabs[name] = { this = newtab, api_obj = gui.add_tab(name) }

    return newtab
end

---@param name string
---@return { this: Tab, api_obj: tab }|nil
function GUI:GetTab(name)
    if not self:DoesTabExist(name) then
        return
    end

    return self.m_tabs[name]
end

---@param name string
---@param parent_name string
---@return Tab|nil
function GUI:GetSubtab(name, parent_name)
    if (not self:DoesTabExist(parent_name)) then
        self:notify("A parent tab with the name '%s' does not exist.", parent_name)
        return
    end

    local child = self.m_tabs[name].this:GetSubtab(name)
    if (not child) then
        self:notify("A sub-tab with the name '%s' does not exist.", name)
        return
    end

    return child
end

---@param newtab Tab
---@param api_tab tab
function GUI:RecursiveAddTab(newtab, api_tab)
    local previous_gui = newtab:GetGUI()
    local drawfunc = function()
        if (type(previous_gui) == "function") then
            local ok, err = pcall(previous_gui)
            if (not ok) then
                log.warning(err)
                newtab:RemoveGUI()
                return
            end
        end

        if newtab:HasGridLayout() then
            local ok, err = pcall(function()
                newtab:GetGridRenderer():Draw()
            end)

            if (not ok) then
                log.warning(err)
                newtab:RemoveGrid()
                return
            end
        end
    end

    api_tab:add_imgui(drawfunc)

    local subtabs = newtab:ListSubtabs()
    local keys = {}

    for name in pairs(subtabs) do
        table.insert(keys, name)
    end
    table.sort(keys)

    for _, name in ipairs(keys) do
        local subtab = subtabs[name]
        if subtab then
            local sub_api = api_tab:add_tab(subtab:GetName())
            self:RecursiveAddTab(subtab, sub_api)
        end
    end
end

---@param drawfunc function
function GUI:RegisterIndependentGUI(drawfunc)
    if (type(drawfunc) ~= "function") then
        return
    end

    table.insert(self.m_guis, drawfunc)
end

function GUI:Draw()
    if self.m_screen_resolution:is_zero() then
        self.m_screen_resolution = Game.GetScreenResolution()
    end

    for _, entry in pairs(self.m_tabs) do
        self:RecursiveAddTab(entry.this, entry.api_obj)
    end

    for _, drawfunc in ipairs(self.m_guis) do
        gui.add_always_draw_imgui(drawfunc)
    end
end

-- Calculates a new window size and center position vectors in relation to the screen resolution.
---@param x_mod float x modifier (ex: 0.5)
---@param y_mod float y modifier (ex: 0.3)
---@return vec2, vec2 -- size, center position
function GUI:GetNewWindowSizeAndCenterPos(x_mod, y_mod)
    if self.m_screen_resolution:is_zero() then
        self.m_screen_resolution = Game.GetScreenResolution()
    end

    local size = vec2:new(
        self.m_screen_resolution.x * x_mod,
        self.m_screen_resolution.y * y_mod
    )
    local center = vec2:new(
        (self.m_screen_resolution.x - size.x) / 2,
        (self.m_screen_resolution.y - size.y) / 2
    )

    return size, center
end

-- Wrapper for `ImGui::TextColored`.
---@param text string
---@param color Color
---@param opts? { alpha: number, wrap_pos: number }
function GUI:TextColored(text, color, opts)
    opts = opts or {}
    local r, g, b, a -- fwd decl
    local has_wrap_pos = type(opts.wrap_pos) == "number"

    if (not IsInstance(color, Color)) then
        r, g, b, a = 1, 0.1, 0, 1
    end

    r, g, b, a = color:AsFloat()
    ImGui.PushStyleColor(ImGuiCol.Text, r, g, b, opts.alpha or a or 1)

    if (has_wrap_pos) then
        ImGui.PushTextWrapPos(opts.wrap_pos)
    end

    ImGui.TextWrapped(text)
    ImGui.PopStyleColor(1)

    if (has_wrap_pos) then
        ImGui.PopTextWrapPos()
    end
end

-- Creates a help marker `(?)` symbol in front of the widget this function is called after.
--
-- When the symbol is hovered, it displays a tooltip.
---@param text string
---@param opts? { color: Color, alpha: number, wrap_pos: number }
function GUI:HelpMarker(text, opts)
    if (GVars.ui.disable_tooltips) then
        return
    end

    opts = opts or { wrap_pos = ImGui.GetFontSize() * 25 }

    ImGui.SameLine()
    ImGui.TextDisabled("(?)")
    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
        ImGui.SetNextWindowBgAlpha(0.75)
        ImGui.BeginTooltip()
        if IsInstance(opts.color, Color) then
            self:TextColored(text, opts.color, opts)
        else
            ImGui.PushTextWrapPos(opts.wrap_pos)
            ImGui.TextWrapped(text)
            ImGui.PopTextWrapPos()
        end
        ImGui.EndTooltip()
    end
end

-- Displays a tooltip whenever the widget this function is called after is hovered.
---@param text string
---@param opts? { color: Color, alpha: number, wrap_pos: number }
function GUI:Tooltip(text, opts)
    if (GVars.ui.disable_tooltips) then
        return
    end

    opts = opts or {}
    wrap_pos = opts.wrap_pos or ImGui.GetFontSize() * 25

    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
        ImGui.SetNextWindowBgAlpha(0.75)
        ImGui.BeginTooltip()
        if IsInstance(opts.color, Color) then
            self:TextColored(text, opts.color, wrap_pos)
        else
            ImGui.PushTextWrapPos(wrap_pos)
            ImGui.TextWrapped(text)
            ImGui.PopTextWrapPos()
        end
        ImGui.EndTooltip()
    end
end

-- Displays a multiline tooltip when the ImGui widget this function is called after is hovered.
---@param lines string[]
---@param wrap_pos? number
function GUI:TooltipMultiline(lines, wrap_pos)
    if (GVars.ui.disable_tooltips) then
        return
    end

    wrap_pos = wrap_pos or (ImGui.GetFontSize() * 25)

    if ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) then
        ImGui.SetNextWindowBgAlpha(0.75)
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(wrap_pos)
        for _, line in pairs(lines) do
            if not string.isnullorwhitespace(line) then
                ImGui.TextWrapped(line)
                ImGui.Spacing()
            end
        end
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end

-- Draws a small confirmation popup window with Yes/No buttons.
--
-- Can execute a callback function on confirmation.
---@param name string
---@param callback function
---@param ... any
function GUI:ConfirmPopup(name, callback, ...)
    if ImGui.BeginPopupModal(
        name,
        ImGuiWindowFlags.NoTitleBar |
        ImGuiWindowFlags.AlwaysAutoResize
    ) then
        if not YELLOW then
            YELLOW = Color("yellow")
        end
        ImGui.PushTextWrapPos(ImGui.GetWindowWidth() - 10)
        self:TextColored("Are you sure?", Color("yellow"), { alpha = 0.9 })
        ImGui.Spacing()

        if ImGui.Button("Yes", 80, 30) then
            self:PlaySound(self.Sounds.Button)
            callback(...)
            ImGui.CloseCurrentPopup()
        end

        ImGui.SameLine()
        ImGui.Dummy(20, 1)
        ImGui.SameLine()

        if ImGui.Button("No", 80, 30) then
            self:PlaySound(self.Sounds.Cancel)
            ImGui.CloseCurrentPopup()
        end

        ImGui.PopTextWrapPos()
        ImGui.EndPopup()
        return true
    end
end

-- Checks if an ImGui widget was clicked.
---@param button GUI.MouseButtons
---@return boolean
function GUI:IsItemClicked(button)
    if (button == self.MouseButtons.LEFT) then
        return (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(0))
    elseif (button == self.MouseButtons.RIGHT) then
        return (ImGui.IsItemHovered(ImGuiHoveredFlags.AllowWhenDisabled) and ImGui.IsItemClicked(1))
    end

    return false
end

-- Sets the clipboard text.
---@param text string
---@param eval? function
function GUI:SetClipBoardText(text, eval)
    if (type(eval) == "function" and not eval()) then
        return
    end

    self:PlaySound(self.Sounds.Click)
    ImGui.SetClipboardText(text)
    self:Notify("Link copied to clipboard.")
end

-- Plays a sound when an ImGui widget is clicked.
---@param sound string|table
function GUI:PlaySound(sound)
    if GVars.ui.disable_sound_feedback then
        return
    end

    local _sound = (type(sound) == "string") and self.Sounds[sound] or sound
    if (not _sound) then
        return
    end

    ThreadManager:RunInFiber(function()
        AUDIO.PLAY_SOUND_FRONTEND(-1, _sound.soundName, _sound.soundRef, false)
    end)
end

---@param fmt string
---@param ... any
function GUI:Notify(fmt, ...)
    local msg = (... ~= nil) and _F(fmt, ...) or fmt
    local name = Backend.script_name:replace("_", " "):titlecase()
    Toast:ShowMessage(name, msg)
end

---@return Tab
function GUI:GetMainTab()
    local existing = self:GetTab(Backend.script_name)
    return existing and existing.this or self:RegisterNewTab(Backend.script_name or "Samurai's Scripts")
end

---@param label string
---@param bool boolean
---@param opts? { tooltip?: string, color?: Color }
---@return boolean, boolean
function GUI:Checkbox(label, bool, opts)
    local clicked = false
    bool, clicked = ImGui.Checkbox(label, bool)

    if (clicked) then
        self:PlaySound(self.Sounds.Checkbox)
    end

    if (opts and opts.tooltip) then
        self:Tooltip(opts.tooltip, opts)
    end

    return bool, clicked
end

---@param label string
---@param opts? { size?: vec2, repeatable?: boolean }
function GUI:Button(label, opts)
    opts = opts or { size = vec2:zero(), repeatable = false }

    ImGui.PushButtonRepeat(opts.repeatable)
    local pressed = ImGui.Button(label, opts.size.x, opts.size.y)
    ImGui.PopButtonRepeat()

    if (pressed) then
        self:PlaySound(self.Sounds.Button)
    end

    return pressed
end

---@param label string
---@param color Color
---@param hover_color Color
---@param active_color Color
---@param opts? { size?: vec2, repeatable?: boolean }
function GUI:ButtonColored(label, color, hover_color, active_color, opts)
    ImGui.PushStyleColor(ImGuiCol.Button, color:AsRGBA())
    ImGui.PushStyleColor(ImGuiCol.ButtonHovered, hover_color:AsRGBA())
    ImGui.PushStyleColor(ImGuiCol.ButtonActive, active_color:AsRGBA())
    local pressed = self:Button(label, opts)
    ImGui.PopStyleColor(3)

    if (pressed) then
        self:PlaySound(self.Sounds.Button)
    end

    return pressed
end

--- Draws an ImGui item and handles enabling/disabling it on `condition`.
---@generic T1, T2, T3, T4, T5
---@param ImGuiItem fun(...: any): T1, T2, T3, T4, T5
---@param condition boolean Disables the item when true.
---@param ... any
---@return T1, T2, T3, T4, T5, ...
function GUI:ConditionalItem(ImGuiItem, condition, ...)
    ImGui.BeginDisabled(condition)
    local ret = table.pack(ImGuiItem(...))
    ImGui.EndDisabled()

    return table.unpack(ret)
end

GUI.Sounds = {
    Radar = {
        soundName = "RADAR_ACTIVATE",
        soundRef = "DLC_BTL_SECURITY_VANS_RADAR_PING_SOUNDS"
    },
    Button = {
        soundName = "SELECT",
        soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET"
    },
    Pickup = {
        soundName = "PICK_UP",
        soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET"
    },
    Pickup_alt = {
        soundName = "PICK_UP_WEAPON",
        soundRef = "HUD_FRONTEND_CUSTOM_SOUNDSET"
    },
    Fail = {
        soundName = "CLICK_FAIL",
        soundRef = "WEB_NAVIGATION_SOUNDS_PHONE"
    },
    Click = {
        soundName = "CLICK_LINK",
        soundRef = "DLC_H3_ARCADE_LAPTOP_SOUNDS"
    },
    Notify = {
        soundName = "LOSE_1ST",
        soundRef = "GTAO_FM_EVENTS_SOUNDSET"
    },
    Delete = {
        soundName = "DELETE",
        soundRef = "HUD_DEATHMATCH_SOUNDSET"
    },
    Cancel = {
        soundName = "CANCEL",
        soundRef = "HUD_FREEMODE_SOUNDSET"
    },
    Error = {
        soundName = "ERROR",
        soundRef = "HUD_FREEMODE_SOUNDSET"
    },
    Nav = {
        soundName = "NAV_LEFT_RIGHT",
        soundRef = "HUD_FREEMODE_SOUNDSET"
    },
    Checkbox = {
        soundName = "NAV_UP_DOWN",
        soundRef = "HUD_FREEMODE_SOUNDSET"
    },
    Select_alt = {
        soundName = "CHANGE_STATION_LOUD",
        soundRef = "RADIO_SOUNDSET"
    },
    Focus_in = {
        soundName = "FOCUSIN",
        soundRef = "HINTCAMSOUNDS"
    },
    Focus_out = {
        soundName = "FOCUSOUT",
        soundRef = "HINTCAMSOUNDS"
    },
}

---@enum GUI.MouseButtons
GUI.MouseButtons = {
    LEFT = 0x0,
    RIGHT = 0x1
}

--#endregion

return GUI
