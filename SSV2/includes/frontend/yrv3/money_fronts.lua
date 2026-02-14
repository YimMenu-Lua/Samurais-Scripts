-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local drawBasicBusiness   = require("includes.frontend.yrv3.basic_business")
local measureBulletWidths = require("includes.frontend.helpers.measure_text_width")

---@type table<string, integer>
local bulletWidths        = {}

return function()
	local carWash = YRV3:GetCarWash()
	if (not carWash) then
		ImGui.Text(_T("YRV3_CWASH_NOT_OWNED"))
		return
	end

	local clearHeatLabel = _F("%s %s", _T("GENERIC_CLEAR"), _T("YRV3_CWASH_HEAT"))
	local iso            = GVars.backend.language_code
	local bulletWidth    = bulletWidths[iso]
	if (not bulletWidth) then
		bulletWidth = measureBulletWidths({
			_T("YRV3_CWASH_WORK_EARNINGS"),
			_T("YRV3_CASH_SAFE"),
			_T("YRV3_CWASH_HEAT"),
			clearHeatLabel
		}, 60.0)

		bulletWidths[iso] = bulletWidth
	end

	drawBasicBusiness(carWash, true, bulletWidth, clearHeatLabel)

	local subs = carWash:GetSubBusinesses()
	if (not subs or #subs == 0) then
		return
	end

	for _, sub in ipairs(subs) do
		drawBasicBusiness(sub, false, bulletWidth, clearHeatLabel)
	end
end
