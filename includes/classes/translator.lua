---@diagnostic disable: lowercase-global

local Labels = require("lib.Translations")

if not keybinds then
    keybinds = CFG:ReadItem("keybinds")
end

if not gpad_keybinds then
    gpad_keybinds = CFG:ReadItem("gpad_keybinds")
end


---@class Translator
Translator = {}
Translator.__index = Translator
Translator.lang = LANG
Translator.log_history = {}
Translator.cache = {}
Translator.button_map = {
    {
        name = "DRIFT_MODE_DESC_",
        kbm = keybinds.tdBtn.name
    },
    {
        name = "DRIFT_TIRES_DESC_",
        kbm = keybinds.tdBtn.name
    },
    {
        name = "NOS_DESC_",
        kbm = keybinds.nosBtn.name
    },
    {
        name = "VEHICLE_MINES_DESC_",
        kbm = keybinds.vehicle_mine.name
    },
    {
        name = "ANIM_STOP_DESC_",
        kbm = keybinds.stop_anim.name
    },
    {
        name = "SCN_STOP_DESC_",
        kbm = keybinds.stop_anim.name
    },
    {
        name = "NOS_PURGE_DESC_",
        kbm = keybinds.purgeBtn.name,
        gpad = gpad_keybinds.purgeBtn.name
    },
    {
        name = "ROD_DESC_",
        kbm = keybinds.rodBtn.name,
        gpad = gpad_keybinds.rodBtn.name
    },
    {
        name = "TRIGGERBOT_DESC_",
        kbm = keybinds.triggerbotBtn.name,
        gpad = gpad_keybinds.triggerbotBtn.name
    },
}

---@param msg string
function Translator:was_logged(msg)
    if #self.log_history == 0 then
        return
    end

    for _, v in ipairs(self.log_history) do
        if v == msg then
            return true
        end
    end
    return false
end

-- Translates text to the user's language.
--
-- If the label to translate is missing or the language
--
-- is invalid, it defaults to English (US).
---@param label string
---@return string
function Translator:Translate(label)
    if #self.cache > 0 and self.lang ~= LANG then
        self.cache = {}
        self.lang = LANG
    end

    if self.cache[label] and self.lang == LANG then
        return self.cache[label]
    end

    ---@type string, string
    local retStr, logmsg
    if Labels[label] then
        for _, v in pairs(Labels[label]) do
            if LANG == v.iso then
                retStr = v.text
                break
            end
        end

        -- Replace "---" and "___" placeholders with button names.
        if retStr ~= nil and #retStr > 0 then
            for _, tr in ipairs(self.button_map) do
                if tr.name == label then
                    if Lua_fn.str_contains(retStr, "___") then
                        retStr = Lua_fn.str_replace(retStr, "___", tr.kbm)
                    end
                    if Lua_fn.str_contains(retStr, "---") then
                        retStr = Lua_fn.str_replace(retStr, "---", tr.gpad)
                    end
                end
            end
        else
            logmsg = "Missing or unsupported language! Defaulting to English (US)."
            if not self:was_logged(logmsg) then
                YimToast:ShowWarning("Translator", logmsg, true)
                table.insert(self.log_history, logmsg)
            end
            retStr = Labels[label][1].text
            SS.debug(string.format("Missing translation for: %s in (%s)", label, self.lang))
        end
    else
        logmsg = "Missing label!"
        if not self:was_logged(logmsg) then
            YimToast:ShowWarning("Translator", logmsg, true)
            table.insert(self.log_history, logmsg)
        end
        retStr = string.format("[!MISSING LABEL]: %s", label)
        SS.debug(string.format("Missing label: %s", label))
    end

    if not self.cache[label] then
        self.cache[label] = retStr
    end

    return retStr
end
