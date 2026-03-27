-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- Only add locales if you have matching files for them under /lib/translations/ otherwise you'll get an error when trying
--
-- to select a new language because `require` falls back to `package.searcher` which is disabled in V1's sandbox (don't know about V2 yet).
--
-- The error is actually just a warning from the API but just to keep things clean and running smoothly, don't add non-existing locales.
return {
	{ name = "English", iso = "en-US" },
	{ name = "Français", iso = "fr-FR" },
	{ name = "Deütsch", iso = "de-DE" },
	{ name = "Español", iso = "es-ES" },
	{ name = "Italiano", iso = "it-IT" },
	{ name = "Português", iso = "pt-BR" },
	{ name = "Русский", iso = "ru-RU" },
	{ name = "中國人", iso = "zh-TW" },
	{ name = "中国人", iso = "zh-CN" },
	{ name = "日本語", iso = "ja-JP" },
	{ name = "Polski", iso = "pl-PL" },
	{ name = "한국인", iso = "ko-KR" },
}
