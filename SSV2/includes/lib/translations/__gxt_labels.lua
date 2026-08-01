-- Copyright (C) 2026 SAMURAI (xesdoog) & Contributors.
-- This file is part of Samurai's Scripts.
--
-- Permission is hereby granted to copy, modify, and redistribute
-- this code as long as you respect these conditions:
--	* Credit the owner and contributors.
--	* Provide a copy of or a link to the original license (GPL-3.0 or later); see LICENSE.md or <https://www.gnu.org/licenses/>.


-- All labels placed in this table will be translated and cached when the Translator loads so they can be used
--
-- either in the Translator:Translate, or _T macro, or indexed directly without ever calling any natives.
--
-- To extend the table with new GXTs, simply follow the same stucture: `t[GXT] = ""`. Keys remain the same
--
--  but values will be mutated to the GXT's value from the game when the script finishes loading.
return {
	PIM_REGBOSS     = "", -- Register As a Boss
	PIM_MAGM0B      = "", -- Retire
	PIM_MAGB        = "", -- SecuroServ VIP
	PIM_MAGBC       = "", -- SecuroServ CEO
	PI_BIK_MCP      = "", -- Motorcycle Club President
	GB_BOSSC        = "", -- CEO
	GB_REST_ACCM    = "", -- Morotcycle Club
	CELL_CLUB       = "", -- Nightclub
	CELL_HANGAR     = "", -- Hangar
	CELL_BUNKER     = "", -- Bunker
	CELL_ACID_LAB   = "", -- Acid Lab
	CELL_SLVG_YRD   = "", -- Salvage Yard
	MP_CARWASH      = "", -- Car Wash
	CELL_16         = "", -- Settings
	HTITLE_TUT      = "", -- The Fleeca Job
	HTITLE_PRISON   = "", -- The Prison Break
	HTITLE_HUMANE   = "", -- The Humane Labs Raid
	HTITLE_NARC     = "", -- Series A Funding
	HTITLE_ORNATE   = "", -- The Pacific Standard Job
	DLCC_DOOMS      = "", -- The Doomsday Heist
	ACH_ACHGO2_NAME = "", -- The Data Breaches (Doomsday act 1)
	ACH_ACHGO3_NAME = "", -- The Bogdan Problem (Doomsday act 2)
	ACH_ACHGO4_NAME = "", -- The Doomsday Scenario (Doomsday act 3)
	CH_END_NAME     = "", -- The Diamond Casino Heist
	DLCC_CONTR      = "", -- The Contract (Dr. Dre)
	DLCC_ISLAN      = "", -- The Cayo Perico Heist
	AWT_1026        = "", -- The Cluckin' Bell Farm Raid
	DLCC_FHAN       = "", -- Oscar Guzman Flies Again
	DLCC_AVIM       = "", -- KnoWay Out
	DLCC_KORTZ      = "", -- The Kortz Center Heist
	CELL_SUBMARINE  = "", -- Kosatka
	DLCC_HEIST_H    = "", -- Go to dynasty8realestate.com to purchase a high-end Apartment. This property gives you access to a planning room where you can set up and play a series of Heists.
	GOPS_BASE_HELP  = "", -- Go to foreclosures.maze-bank.com to purchase a Facility. This property gives you access to The Doomsday Heist planning room as a Boss.
	CH_HLP_2        = "", -- Visit foreclosures.maze-bank.com to view and purchase an Arcade. This gives you access to The Diamond Casino Heist planning area as a Boss.
	HIF_SUB_HELP    = "", -- Visit warstock-cache-and-carry.com to purchase a Kosatka submarine. This gives you access to The Cayo Perico Heist as a Boss.
}
