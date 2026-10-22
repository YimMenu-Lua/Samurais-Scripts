local Translator = {}
Translator.__index = Translator
local locales = require('includes.ssv2.data.locale_codes')

function Translator.new(settings)
    local english = require('includes.ssv2.data.locales.en-US')
    local pending = {}; for key in pairs(require('includes.ssv2.data.gxt_labels')) do pending[key] = true end
    return setmetatable({
        settings = settings,
        english = english,
        cache = { ['en-US'] = english },
        locales = locales,
        gxt = {},
        pending = pending,
        next_language_check = 0
    }, Translator)
end

function Translator:update()
    if self.debug_disabled then return end
    if self.settings:get('backend.use_game_language') and util.time() >= self.next_language_check then
        local map = {
            [0] = 'en-US',
            [1] = 'fr-FR',
            [2] = 'de-DE',
            [3] = 'it-IT',
            [4] = 'es-ES',
            [5] = 'pt-BR',
            [6] = 'pl-PL',
            [7] = 'ru-RU',
            [8] = 'ko-KR',
            [9] = 'zh-TW',
            [10] = 'ja-JP',
            [11] = 'es-ES',
            [12] = 'zh-CN'
        }
        local requested, index = map[LOCALIZATION.GET_CURRENT_LANGUAGE()] or 'en-US', 1
        for i, code in ipairs(locales) do if code == 'en-US' then index = i end end
        for i, code in ipairs(locales) do if code == requested then
                index = i; break
            end end
        self.settings:set('backend.language_index', index)
        self.next_language_check = util.time() + 1000
    end
    local count = 0
    for key in pairs(self.pending) do
        local label = HUD.GET_FILENAME_FOR_AUDIO_CONVERSATION(key)
        if label and label ~= '' and label ~= 'NULL' then self.gxt[key] = label end
        self.pending[key] = nil; count = count + 1; if count >= 32 then break end
    end
end

function Translator:reload(debug_break)
    if util.time() < (self.reload_after or 0) then return end
    self.reload_after = util.time() + 3000
    self.debug_disabled = debug_break or false
    if self.debug_disabled then return end
    self.cache = { ['en-US'] = self.english }; self.gxt = {}; self.pending = {}
    for key in pairs(require('includes.ssv2.data.gxt_labels')) do self.pending[key] = true end
end

function Translator:text(key, fallback)
    local index = self.settings:get('backend.language_index') or 1
    local locale = locales[index] or 'en-US'
    if not self.cache[locale] then self.cache[locale] = require('includes.ssv2.data.locales.' .. locale) end
    local value = self.cache[locale][key] or self.english[key] or self.gxt[key]
    if not value then self.pending[key] = true end
    return value or fallback or key
end

function Translator:format(key, ...)
    local value = self:text(key)
    local ok, result = pcall(string.format, value, ...)
    return ok and result or value
end

return Translator
