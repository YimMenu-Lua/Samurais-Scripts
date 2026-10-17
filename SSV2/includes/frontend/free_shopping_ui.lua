-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


local FreeShopping = require("includes.features.online.FreeShopping")


GUI:RegisterNewTab(Enums.eTabID.TAB_ONLINE, "SUBTAB_FREE_SHOPPING", function()
	if (Backend:GetGameBranch() == Enums.eGameBranch.ENHANCED) then
		ImGui.TextWrapped(_T("FS_ENHANCED_BUILTIN"))
		return
	end

	if (not FreeShopping:IsSupported()) then
		ImGui.TextWrapped(_T("FS_LEGACY_ONLY"))
		return
	end

	if (not Game.IsOnline()) then
		ImGui.Text(_T("GENERIC_UNAVAILABLE_SP"))
		return
	end

	if (not Backend:IsUpToDate()) then
		ImGui.Text(_T("GENERIC_OUTDATED"))
		return
	end

	GUI:HeaderText(_T("SUBTAB_FREE_SHOPPING"), { separator = true, spacing = true })
	ImGui.TextWrapped(_T("FS_DESCRIPTION"))

	local enabled, changed = GUI:CustomToggle(_T("FS_ENABLE"), FreeShopping:IsEnabled(), {
		tooltip = _T("FS_ENABLE_TT"),
	})
	if (changed) then
		FreeShopping:SetEnabled(enabled)
	end

	if (FreeShopping:IsEnabled()) then
		ImGui.Text(_T("FS_ACTIVE"))
	else
		ImGui.Text(_T("FS_DISABLED"))
	end

	local err = FreeShopping:GetError()
	if (err) then
		ImGui.Separator()
		ImGui.TextWrapped(_F("%s: %s", _T("FS_UNAVAILABLE"), err))
	end
end, nil, true)
