---@class RawEscortMemberData
---@field name string
---@field modelHash hash
---@field weapon hash

---@class RawEscortGroupData
---@field name string
---@field vehicleModel hash
---@field members { [1]: RawEscortMemberData, [2]: RawEscortMemberData, [3]: RawEscortMemberData }
---@field JSON boolean?

local customPaints <const> = require("includes.data.custom_paints")

return {
	---@private
	---@type dict<RawEscortGroupData>
	DefaultEscortGroups = {
		["Armenian Mobsters"] = {
			members = {
				{
					modelHash = 3882958867,
					name = "Levon Termendzhyan",
					weapon = 453432689
				},
				{
					modelHash = 4255728232,
					name = "Armen Petrosyan",
					weapon = 453432689
				},
				{
					modelHash = 4058522530,
					name = "Yanni",
					weapon = 453432689
				}
			},
			name = "Armenian Mobsters",
			vehicleModel = 83136452
		},
		["Bad Bitches"] = {
			members = {
				{
					modelHash = 42647445,
					name = "Beretta Von PewPew",
					weapon = 3220176749
				},
				{
					modelHash = 2168724337,
					name = "Big Booty Iggy",
					weapon = 3220176749
				},
				{
					modelHash = 2934601397,
					name = "Sasha Slasha",
					weapon = 3220176749
				}
			},
			name = "Bad Bitches",
			vehicleModel = 461465043
		},
		["Private Mercenaries"] = {
			members = {
				{
					modelHash = 1631478380,
					name = "Jack Reacher",
					weapon = 2210333304
				},
				{
					modelHash = 1349953339,
					name = "Ethan Hunt",
					weapon = 2210333304
				},
				{
					modelHash = 3019107892,
					name = "Sam Fisher",
					weapon = 2210333304
				}
			},
			name = "Private Mercenaries",
			vehicleModel = 2370534026
		},
		["Sicarios"] = {
			members = {
				{
					modelHash = 2572894111,
					name = "Ovidio Guzman",
					weapon = 3220176749
				},
				{
					modelHash = 2127932792,
					name = "Popeye",
					weapon = 3220176749
				},
				{
					modelHash = 3870061732,
					name = "El Sueno",
					weapon = 3220176749
				}
			},
			name = "Sicarios",
			vehicleModel = 1254014755
		},
		["VIP Security"] = {
			members = {
				{
					modelHash = 4049719826,
					name = "Arthur Bishop",
					weapon = 2210333304
				},
				{
					modelHash = 691061163,
					name = "Luke Wright",
					weapon = 2210333304
				},
				{
					modelHash = 1442749254,
					name = "Frank Martin",
					weapon = 2210333304
				}
			},
			name = "VIP Security",
			vehicleModel = 666166960
		}
	},

	NewGroupVehicles = {
		0x825A9F4C,
		0x6210CBB0,
		0x7B7E56F0,
		0xB6410173,
		0x9FC300D,
		0x8D4B7A8A,
		0xAF966F3C,
		0x9114EADA,
		0x84F42E51,
		0xD80F4A44,
		0x4ABEBF23,
		0xB9210FD0,
		0x27816B7E,
		0x36848602,
		0xD0EB2BE5,
		0x4DF2780F,
		0xBC32A33B,
		0xCC8A305C,
		0x1B8165D3,
		0x25CBE2E2,
		0x6FF0F727,
		0x9628879C,
		0x8852855,
		0xCE0B9F22,
		0x258C9364,
		0x27B4E6B0,
		0x4FB1A214,
		0x48CECED3,
		0x1573422D,
		0x34B7390F,
		0x4BA4E8DC,
		0x92F5024E,
		0xFDAEBF27,
		0x94114926,
		0xCFCA3668,
		0x9D96B45B,
		0x28B67ACA,
		0xCFCFEB3B,
		0x7F5C91F1,
		0x32B29A4B,
		0xE6401328,
		0x1D06D681,
		0x4F48FC4,
		0x1C09CF5E,
		0xBA5334AC,
		0x779F23AA,
		0xE882E5F6,
		0xF06C29C7,
		0x47BBCF2E,
		0xC29F8F4E,
		0xA3FC0F4D,
		0xD2389392,
		0x75397001,
		0x462FE277
	},

	DefaultLimousines = {
		["Patriot Stretch"] = {
			model       = 0xE6E967F8,
			color       = {
				primary   = customPaints[18],
				secondary = customPaints[18]
			},
			mods        = {
				[2]  = 0,
				[3]  = 0,
				[5]  = 1,
				[8]  = 7,
				[12] = 3,
				[13] = 2,
				[16] = 2,
				[17] = 4,
				[24] = 22
			},
			wheelType   = 9,
			window_tint = 1,
			description = "The perfect choice for spoiled brats."
		},
		["Cognoscenti LWB"] = {
			model       = 0x86FE0B60,
			color       = {
				primary = customPaints[11],
				secondary = customPaints[22]
			},
			mods        = {
				[12] = 3,
				[13] = 2,
				[16] = 3,
				[17] = 4,
				[24] = 8,
			},
			wheelType   = 3,
			wheelColor  = 0,
			window_tint = 1,
			description = "Understated class."
		},
		["Stretch Limo"] = {
			model = 0x8B13F083,
			color = {
				primary = customPaints[11],
				secondary = customPaints[11]
			},
			window_tint = 1,
			description = "The classic limousine."
		},
		["Turreted Limo"] = {
			model = 0xF92AEC4D,
			color = {
				primary = customPaints[11],
				secondary = customPaints[11]
			},
			window_tint = 1,
			description = "The perfect choice for billionaires under siege."
		},
		["Roosevelt Valor"] = {
			model = 0xDC19D101,
			color = {
				primary   = customPaints[18],
				secondary = customPaints[11]
			},
			window_tint = 0,
			description = "A vintage icon from the prohibition era: When business was booming and rivals were bleeding."
		},
		["Windsor Drop"] = {
			model       = 0x8CF5CAE1,
			mods        = {
				[12] = 3,
				[13] = 2,
				[14] = 2,
				[16] = 3,
				[17] = 4,
				[24] = 27,
			},
			color       = {
				primary = customPaints[18],
				secondary = customPaints[22],
				interior = 106
			},
			wheelType   = 3,
			window_tint = 1,
			description = "Arab money, habibi!"
		},
	},

	DefaultHeliModels = {
		Pair.new("Annihilator", 837858166),
		Pair.new("Annihilator Stealth", 295054921),
		Pair.new("Maverick", 2634305738),
		Pair.new("Police Maverick", 353883353),
		Pair.new("Savage", 4212341271),
		Pair.new("SuperVolito", 710198397),
		Pair.new("SuperVolito Carbon", 2623428164),
		Pair.new("Swift Flying Bravo", 3955379698),
		Pair.new("Swift Deluxe", 1075432268),
		Pair.new("Valkyrie", 2694714877),
		Pair.new("Volatus", 2449479409),
	},

	HeliPresetDestinations = {
		Pair.new("Sandy Shores Helipad", vec3:new(1770.17, 3239.85, 42.1217)),
		Pair.new("Paleto Bay Sheriff's Office", vec3:new(-475.02, 5988.46, 31.3367)),
		Pair.new("Fort Zancudo Helipad", vec3:new(-1859.4, 2795.65, 32.8066)),
		Pair.new("The Diamond Casino Helipad", vec3:new(967.052, 42.1343, 123.127)),
		Pair.new("Vinewood Police Station", vec3:new(579.992, 12.3636, 103.234)),
		Pair.new("Hawick Agency Helipad", vec3:new(393.284, -66.3109, 124.376)),
		Pair.new("Richard's Majestic Helipad", vec3:new(-913.493, -378.444, 137.906)),
		Pair.new("Rockford Hills Agency Helipad", vec3:new(-1007.68, -415.99, 80.1686)),
		Pair.new("Vespucci Canals Agency Helipad", vec3:new(-1010.76, -756.875, 81.7484)),
		Pair.new("Little Seoul Agency Helipad", vec3:new(-597.602, -716.92, 131.04)),
		Pair.new("Lombank Office Helipad", vec3:new(-1581.9, -569.51, 116.328)),
		Pair.new("Mazebank West Office Helipad", vec3:new(-1391.7, -477.587, 91.2508)),
		Pair.new("Mazebank Tower Helipad", vec3:new(-75.2834, -819.323, 326.175)),
		Pair.new("Arcadius Office Helipad", vec3:new(-144.582, -593.811, 211.775)),
	},
	DefaultJetModels = {
		{
			name        = "Luxor Deluxe",
			model       = 0xB79F589E,
			description =
			"Now that the private jet market is open to every middle-class American willing to harvest their children's organs for cash, you need a new way to stand out. Forget standard light-weight, high-malleability, flame retardant aeronautical construction materials, yours are solid gold! It's time to tell the world exactly who you are. Besides, all your passengers will be too wasted on the complimentary champagne and cigars to care if you melt and fall out the sky during the next solar storm."
		},
		{
			name        = "Nimbus",
			model       = 0xB2CF7250,
			description =
			"The cutting edge has always had its naysayers. 'Why is the toilet made of rhino horn?' Fortunately the enemies of progress are completely inaudible when you and the other board members are daisy chaining at 40,000 feet."
		},
	},
	Airports = {
		{
			name            = "Los Santos International Airport",
			runwayStart     = vec3:new(-1305.79, -2148.72, 13.9446),
			runwayEnd       = vec3:new(-1663.04, -2775.99, 13.9447),
			taxiPos         = vec3:new(-1046.74, -2971.01, 13.9487),
			cutPos          = vec3:new(-2204.82, -2554.53, 678.723),
			hangar          = {
				pos     = vec3:new(-979.294, -2993.9, 13.9451),
				heading = 50
			},
			landingApproach = {
				pos     = vec3:new(-860.534, -1476.28, 286.833),
				heading = 143.321
			},
			limoTeleport    = {
				pos     = vec3:new(-991.083, -3005.92, 13.9451),
				heading = 15.427
			},
		},
		{
			name            = "Fort Zancudo",
			runwayStart     = vec3:new(-1972.55, 2842.36, 32.8104),
			runwayEnd       = vec3:new(-2598.1, 3199.13, 32.8118),
			taxiPos         = vec3:new(-2166.8, 3203.57, 32.8049),
			cutPos          = vec3:new(-3341.66, 3578.68, 595.203),
			hangar          = {
				pos     = vec3:new(-2140.81, 3255.64, 32.8103),
				heading = 132
			},
			landingApproach = {
				pos     = vec3:new(-1487.91, 2553.82, 266.253),
				heading = 55.7258
			},
			limoTeleport    = {
				pos     = vec3:new(-2134.02, 3241.4, 32.8103),
				heading = 97.989
			},
		},
		{
			name            = "Sandy Shores Airfield",
			runwayStart     = vec3:new(1052.2, 3068.35, 41.6282),
			runwayEnd       = vec3:new(1718.24, 3254.43, 41.1363),
			taxiPos         = vec3:new(1705.72, 3254.61, 41.0139),
			cutPos          = vec3:new(-164.118, 1830.04, 996.586),
			hangar          = {
				pos     = vec3:new(1744.21, 3276.24, 41.1191),
				heading = 150
			},
			landingApproach = {
				pos     = vec3:new(633.196, 2975.52, 263.214),
				heading = 277.875
			},
			limoTeleport    = {
				pos     = vec3:new(1755.6, 3261.15, 41.3516),
				heading = 83.893
			},
		},
	}
}
