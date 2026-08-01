-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local BusinessMgr   = require("includes.features.online.business_mgr.BusinessManager")
local drawWarehouse = require("includes.frontend.business_mgr.warehouse_ui")

return function()
	drawWarehouse(BusinessMgr:GetHangar(), _T("YRV3_HANGAR_NOT_OWNED"))
end
