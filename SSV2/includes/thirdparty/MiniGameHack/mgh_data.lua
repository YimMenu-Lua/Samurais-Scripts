---@class MiniGameHackLocals
---@field sgsl_entry string
---@field callback fun(scrLocal: ScriptLocal, s: script_util)

---@class MiniGameHackBsLocals
---@field sgsl_entry string
---@field offsets array<integer>
---@field bits array<integer>

---@class MiniGameHackBsGlobals : MiniGameHackBsLocals
---@field scrLocal? ScriptGlobal


---@type { main_locals: table<string, array<MiniGameHackLocals>>, bs_locals: table<string, array<MiniGameHackBsLocals>> }
return {
	main_locals = {
		["fm_mission_controller"] = {
			{
				sgsl_entry = "mgh_fmmc_local_1",
				callback = function(scrLocal, s) scrLocal:WriteInt(0) end
			},
			{
				sgsl_entry = "mgh_fmmc_local_2",
				callback = function(scrLocal, s) scrLocal:WriteInt(0) end
			},
			{
				sgsl_entry = "mgh_fmmc_local_3",
				callback = function(scrLocal, s) scrLocal:WriteInt(7) end
			},
			{
				sgsl_entry = "mgh_fmmc_local_4",
				callback = function(scrLocal, s) scrLocal:At(135):WriteInt(3) end
			},
			{
				sgsl_entry = "mgh_fmmc_local_5",
				callback = function(scrLocal, s) scrLocal:At(24):WriteInt(7) end
			},
			{
				sgsl_entry = "mgh_fmmc_local_6",
				callback = function(scrLocal, s) scrLocal:At(11):WriteFloat(1.0) end
			},
			{
				sgsl_entry = "mgh_fmmc_local_7",
				callback = function(scrLocal, s) scrLocal:At(2):WriteInt(8) end
			},
			{
				sgsl_entry = "mgh_fmmc_local_8",
				callback = function(scrLocal, s) scrLocal:WriteInt(5) end
			},
			{
				sgsl_entry = "mgh_fmmc_local_9",
				callback = function(scrLocal, s) scrLocal:WriteInt(2) end
			},
		},
		["fm_mission_controller_2020"] = {
			{
				sgsl_entry = "mgh_fmmc20_local_1",
				callback = function(scrLocal, s) scrLocal:At(24):WriteInt(7) end
			},
			{
				sgsl_entry = "mgh_fmmc20_local_2",
				callback = function(scrLocal, s) scrLocal:At(135):WriteInt(3) end
			},
			{
				sgsl_entry = "mgh_fmmc20_local_3",
				callback = function(scrLocal, s) scrLocal:WriteInt(6) end
			},
			{
				sgsl_entry = "mgh_fmmc20_local_4",
				callback = function(scrLocal, s) scrLocal:At(3):WriteFloat(100.0) end
			},
			{
				sgsl_entry = "mgh_fmmc20_local_5",
				callback = function(scrLocal, s) scrLocal:WriteInt(2) end
			},
			{
				sgsl_entry = "mgh_fmmc20_local_6",
				callback = function(scrLocal, s)
					scrLocal:WriteInt(scrLocal:At(1):ReadInt())
					scrLocal:At(2):WriteInt(3)
				end
			},
			{
				sgsl_entry = "mgh_fmmc20_local_7",
				callback = function(scrLocal, s)
					if (scrLocal:ReadInt() == 3) then
						local pwd = scrLocal:At(1)
						pwd:WriteInt(2)
						pwd:At(2):WriteInt(pwd:At(3):ReadInt())
						pwd:At(4):WriteInt(pwd:At(5):ReadInt())
						pwd:At(6):WriteInt(pwd:At(7):ReadInt())
						PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 237, 1.0)
					end
				end
			},
		},
		["fm_mission_controller_v3"] = {
			{
				sgsl_entry = "mgh_fmmc_v3_local_1",
				callback = function(scrLocal, s) scrLocal:At(24):WriteInt(7) end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_2",
				callback = function(scrLocal, s) scrLocal:At(135):WriteInt(3) end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_3",
				callback = function(scrLocal, s) scrLocal:WriteInt(6) end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_4",
				callback = function(scrLocal, s)
					scrLocal:At(4, 13):At(3):WriteFloat(100.0)
				end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_5",
				callback = function(scrLocal, s) scrLocal:WriteInt(2) end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_6",
				callback = function(scrLocal, s)
					scrLocal:WriteInt(scrLocal:At(1):ReadInt())
					scrLocal:At(2):WriteInt(3)
				end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_7",
				callback = function(scrLocal, s)
					if (scrLocal:ReadInt() == 3) then
						local pwd = scrLocal:At(1)
						pwd:WriteInt(2)
						pwd:At(2):WriteInt(pwd:At(3):ReadInt())
						pwd:At(4):WriteInt(pwd:At(5):ReadInt())
						pwd:At(6):WriteInt(pwd:At(7):ReadInt())
						PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 237, 1.0)
					end
				end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_8",
				callback = function(scrLocal, s)
					for i = 0, 7 do
						scrLocal:At(i, 4):WriteInt(1)
					end
				end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_9",
				callback = function(scrLocal, s) scrLocal:WriteInt(5) end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_10",
				callback = function(scrLocal, s) scrLocal:WriteInt(5) end
			},
			{
				sgsl_entry = "mgh_fmmc_v3_local_11",
				callback = function(scrLocal, s)
					for i = 0, 2 do
						scrLocal:At(1):At(i, 2):At(1):WriteInt(0)
						s:sleep(100)
						PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 237, 1.0)
					end
				end
			},
		},
		["fm_content_island_heist"] = {
			{
				sgsl_entry = "mgh_fm_c_ih_1",
				callback = function(scrLocal, s)
					scrLocal:WriteInt(scrLocal:At(1):ReadInt())
					scrLocal:At(2):WriteInt(3)
				end
			},
			{
				sgsl_entry = "mgh_fm_c_ih_2",
				callback = function(scrLocal, s) scrLocal:At(24):WriteInt(7) end
			}
		},
		["fm_content_vehrob_prep"] = {
			{
				sgsl_entry = "mgh_fm_c_vehrob_prep_1",
				callback = function(scrLocal, s)
					scrLocal:WriteInt(scrLocal:At(1):ReadInt())
					scrLocal:At(2):WriteInt(3)
				end
			},
			{
				sgsl_entry = "mgh_fm_c_vehrob_prep_2",
				callback = function(scrLocal, s) scrLocal:At(24):WriteInt(7) end
			}
		},
		["am_mp_arc_cab_manager"] = {
			{
				sgsl_entry = "mgh_am_mp_arc_cab_magr_1",
				callback = function(scrLocal, s)
					scrLocal:WriteInt(scrLocal:At(1):ReadInt())
					scrLocal:At(2):WriteInt(3)
				end
			},
		},
		["fm_content_business_battles"] = {
			{
				sgsl_entry = "mgh_fm_c_bb",
				callback = function(scrLocal, s) scrLocal:At(24):WriteInt(7) end
			},
		},
		["am_mp_hotwire"] = {
			{
				sgsl_entry = "mgh_hotwire",
				callback = function(scrLocal, s) scrLocal:WriteInt(2) end
			},
		},
		["word_hack"] = {
			{
				sgsl_entry = "mgh_wordhack",
				callback = function(scrLocal, s) scrLocal:At(53):WriteInt(5) end
			},
		},
		["circuitblockhack"] = {
			{
				sgsl_entry = "mgh_circ_block_hack",
				callback = function(scrLocal, s) scrLocal:At(9):WriteInt(2) end
			},
		},
		["fm_content_hacker_house_finale"] = {
			{
				sgsl_entry = "mgh_fm_c_hh_finale",
				callback = function(scrLocal, s) scrLocal:At(1):WriteInt(5) end
			},
		},
		["fm_content_stash_house"] = {
			{
				sgsl_entry = "mgh_stash_house",
				callback = function(scrLocal, s)
					for i = 0, 2 do
						local offsetLocal = scrLocal:At(22):At(i, 2)
						offsetLocal:WriteInt(offsetLocal:At(1):ReadInt())
						s:sleep(250)
						PAD.SET_CONTROL_VALUE_NEXT_FRAME(2, 235, 1.0)
					end
				end
			},
		},
	},
	bs_locals = {
		["fm_mission_controller"] = {
			{
				sgsl_entry = "mgh_h3_hack_1",
				offsets = {},
				bits = { 0 }
			},
			{
				sgsl_entry = "mgh_h3_hack_2",
				offsets = {},
				bits = { 0 }
			},
			{
				sgsl_entry = "mgh_fmmc_bs",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["fm_mission_controller_2020"] = {
			{
				sgsl_entry = "mgh_h4_hack",
				offsets = {},
				bits = { 0 }
			},
			{
				sgsl_entry = "mgh_fmmc20_bs",
				offsets = { 9, 18, 26, 28 },
				bits = { 0 }
			},
		},
		["fm_mission_controller_v3"] = {
			{
				sgsl_entry = "mgh_fmmc_v3_bs",
				offsets = { 9, 18, 26, 28 },
				bits = { 0 }
			},
		},
		["am_mp_arc_cab_manager"] = {
			{
				sgsl_entry = "mgh_h3_hack_1_p",
				offsets = {},
				bits = { 0 }
			},
			{
				sgsl_entry = "mgh_h3_hack_2_p",
				offsets = {},
				bits = { 0 }
			},
		},
		["fm_content_hacker_whistle_prep"] = {
			{
				sgsl_entry = "mgh_fm_c_hwp",
				offsets = {},
				bits = { 26 }
			},
		},
		["agency_heist3b"] = {
			{
				sgsl_entry = "mgh_ah3b",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["business_battles_sell"] = {
			{
				sgsl_entry = "mgh_bb_sell",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["fm_content_business_battles"] = {
			{
				sgsl_entry = "mgh_fm_c_bb_bs",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["fm_content_island_heist"] = {
			{
				sgsl_entry = "mgh_fm_c_ih_bs",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["fm_content_vehrob_casino_prize"] = {
			{
				sgsl_entry = "mgh_fm_c_vrcp_bs",
				offsets = { 2 },
				bits = { 9, 18, 26, 28 }
			},
		},
		["fm_content_vehrob_police"] = {
			{
				sgsl_entry = "mgh_fm_c_vrp_bs",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["fm_content_vehrob_prep"] = {
			{
				sgsl_entry = "mgh_fm_c_vehrob_prep_bs",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["fm_content_vip_contract_1"] = {
			{
				sgsl_entry = "mgh_fm_c_vip_c_bs",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["gb_cashing_out"] = {
			{
				sgsl_entry = "mgh_gb_cashingout_bs",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["gb_gunrunning_defend"] = {
			{
				sgsl_entry = "mgh_gb_gr_defend_bs",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
		["gb_sightseer"] = {
			{
				sgsl_entry = "mgh_gb_sightseer_bs",
				offsets = {},
				bits = { 9, 18, 26, 28 }
			},
		},
	},
}
