---@diagnostic disable

lang_T          = {
    { name = 'English', iso = 'en-US' },
    { name = 'Français', iso = 'fr-FR' },
    { name = 'Deütsch', iso = 'de-DE' },
    { name = 'Español', iso = 'es-ES' },
    { name = 'Italiano', iso = 'it-IT' },
    { name = 'Português (Brasil)', iso = 'pt-BR' },
    { name = 'Русский (Russian)', iso = 'ru-RU' },
    { name = 'Chinese (Traditional)', iso = 'zh-TW' },
    { name = 'Chinese (Simplified)', iso = 'zh-CN' },
    { name = 'Japanese', iso = 'ja-JP' },
    { name = 'Polish', iso = 'pl-PL' },
    { name = 'Korean', iso = 'ko-KR' },
}

ui_sounds_T     = {
    ["Radar"] = {
        soundName = "RADAR_ACTIVATE",
        soundRef = "DLC_BTL_SECURITY_VANS_RADAR_PING_SOUNDS"
    },
    ["Select"] = {
        soundName = "SELECT",
        soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET"
    },
    ["Pickup"] = {
        soundName = "PICK_UP",
        soundRef = "HUD_FRONTEND_DEFAULT_SOUNDSET"
    },
    ["W_Pickup"] = {
        soundName = "PICK_UP_WEAPON",
        soundRef = "HUD_FRONTEND_CUSTOM_SOUNDSET"
    },
    ["Fail"] = {
        soundName = "CLICK_FAIL",
        soundRef = "WEB_NAVIGATION_SOUNDS_PHONE"
    },
    ["Click"] = {
        soundName = "CLICK_LINK",
        soundRef = "DLC_H3_ARCADE_LAPTOP_SOUNDS"
    },
    ["Notif"] = {
        soundName = "LOSE_1ST",
        soundRef = "GTAO_FM_EVENTS_SOUNDSET"
    },
    ["Delete"] = {
        soundName = "DELETE",
        soundRef = "HUD_DEATHMATCH_SOUNDSET"
    },
    ["Cancel"] = {
        soundName = "CANCEL",
        soundRef = "HUD_FREEMODE_SOUNDSET"
    },
    ["Error"] = {
        soundName = "ERROR",
        soundRef = "HUD_FREEMODE_SOUNDSET"
    },
    ["Nav"] = {
        soundName = "NAV_LEFT_RIGHT",
        soundRef = "HUD_FREEMODE_SOUNDSET"
    },
    ["Nav2"] = {
        soundName = "NAV_UP_DOWN",
        soundRef = "HUD_FREEMODE_SOUNDSET"
    },
    ["Select2"] = {
        soundName = "CHANGE_STATION_LOUD",
        soundRef = "RADIO_SOUNDSET"
    },
    ["Focus_In"] = {
        soundName = "FOCUSIN",
        soundRef = "HINTCAMSOUNDS"
    },
    ["Focus_Out"] = {
        soundName = "FOCUSOUT",
        soundRef = "HINTCAMSOUNDS"
    },
}

eGameState      = {
    "Invalid",
    "Playing",
    "Died",
    "Arrested",
    "FailedMission",
    "LeftGame",
    "Respawn",
    "InMPCutscene",
}

eModelTypes     = {
    [0]     = 'Invalid',
    [1]     = 'Object',
    [2]     = 'MLO',
    [3]     = 'Time',
    [4]     = 'Weapon',
    [5]     = 'Vehicle',
    [6]     = 'Ped',
    [7]     = 'Destructible',
    [33]    = 'Destructible',
    [157]   = 'Building/Map Texture',
    [43649] = 'Fixed Map Object',
    [16385] = 'Fixed Map Object',
}

rgb_loop_colors = {
    { 0,   255, 255, 1 },
    { 0,   127, 255, 1 },
    { 0,   0,   255, 1 },
    { 127, 0,   255, 1 },
    { 255, 0,   255, 1 },
    { 255, 0,   127, 1 },
    { 255, 0,   0,   1 },
    { 255, 127, 0,   1 },
    { 255, 255, 0,   1 },
    { 127, 255, 0,   1 },
    { 0,   255, 0,   1 },
    { 0,   255, 127, 1 }

}

gta_vehicles_T  = {
    "AMBULANCE", "BARRACKS", "BARRACKS2", "BARRACKS3", "BLIMP", "BLIMP2", "BMX", "BUS", "Baller", "Benson", "BfInjection",
    "Biff", "Bison2", "Bison3", "BjXL", "Bodhi2", "Burrito", "Burrito4", "Buzzard2", "CAMPER", "CRUSADER", "Caddy2",
    "Cargobob", "Cargobob3", "Cargobob4", "Dinghy", "Dominator", "Dynasty", "Emperor2", "Euros", "FBI", "FBI2", "FLATBED",
    "FORKLIFT", "Frogger", "GRANGER", "Gauntlet", "Hauler", "Hauler2", "Lazer", "MESA", "MESA3", "Miljet", "Mixer",
    "Mixer2", "Mower", "Mule", "Mule2", "Mule3", "Novak", "Packer", "Phantom", "Phantom4", "Phoenix", "Pounder",
    "Predator",
    "RHINO", "RIOT", "RancherXL", "RapidGT", "RapidGT2", "Rebel", "Rentalbus", "Ripley", "Rubble", "SEVEN70", "SHERIFF",
    "SPECTER", "SPECTER2", "SURFER", "Sadler", "Sanchez", "Seminole", "Shamal", "Stryder", "Stunt", "Sugoi", "Suntrap",
    "Surano", "Surfer2", "TOURBUS", "TOWTRUCK", "TRACTOR", "Taco", "TipTruck", "TipTruck2", "Towtruck2", "Trash",
    "Utillitruck3", "Vader", "Ztype", "adder", "airbus", "airtug", "akula", "akuma", "aleutian", "alkonost", "alpha",
    "alphaz1", "annihilator", "annihilator2", "apc", "ardent", "armytanker", "armytrailer", "armytrailer2", "asbo",
    "asea",
    "asea2", "asterope", "asterope2", "astron", "autarch", "avarus", "avenger", "avenger2", "avenger3", "avenger4",
    "avisa",
    "bagger", "baletrailer", "baller2", "baller3", "baller4", "baller5", "baller6", "baller7", "baller8", "banshee",
    "banshee2", "banshee3", "barrage", "bati", "bati2", "benson2", "besra", "bestiagts", "bf400", "bifta", "bison",
    "blade",
    "blazer", "blazer2", "blazer3", "blazer4", "blazer5", "blimp3", "blista", "blista2", "blista3", "boattrailer",
    "boattrailer2", "boattrailer3", "bobcatXL", "bombushka", "boor", "boxville", "boxville2", "boxville3", "boxville4",
    "boxville5", "boxville6", "brawler", "brickade", "brickade2", "brigham", "brioso", "brioso2", "brioso3", "broadway",
    "bruiser", "bruiser2", "bruiser3", "brutus", "brutus2", "brutus3", "btype", "btype2", "btype3", "buccaneer",
    "buccaneer2", "buffalo", "buffalo2", "buffalo3", "buffalo4", "buffalo5", "bulldozer", "bullet", "burrito2",
    "burrito3",
    "burrito5", "buzzard", "cablecar", "caddy", "caddy3", "calico", "caracara", "caracara2", "carbonizzare", "carbonrs",
    "cargobob2", "cargobob5", "cargoplane", "cargoplane2", "casco", "castigator", "cavalcade", "cavalcade2", "cavalcade3",
    "cerberus", "cerberus2", "cerberus3", "champion", "chavosv6", "cheburek", "cheetah", "cheetah2", "chernobog",
    "chimera",
    "chino", "chino2", "cinquemila", "cliffhanger", "clique", "clique2", "club", "coach", "cog55", "cog552", "cogcabrio",
    "cognoscenti", "cognoscenti2", "comet2", "comet3", "comet4", "comet5", "comet6", "comet7", "conada", "conada2",
    "contender", "coquette", "coquette2", "coquette3", "coquette4", "coquette5", "coquette6", "corsita", "coureur",
    "cruiser", "cuban800", "cutter", "cyclone", "cypher", "daemon", "daemon2", "deathbike", "deathbike2", "deathbike3",
    "defiler", "deity", "deluxo", "deveste", "deviant", "diablous", "diablous2", "dilettante", "dilettante2", "dinghy2",
    "dinghy3", "dinghy4", "dinghy5", "dloader", "docktrailer", "docktug", "dodo", "dominator10", "dominator2",
    "dominator3",
    "dominator4", "dominator5", "dominator6", "dominator7", "dominator8", "dominator9", "dorado", "double", "drafter",
    "draugur", "driftcheburek", "driftcypher", "drifteuros", "driftfr36", "driftfuto", "driftfuto2", "driftjester",
    "driftjester3", "driftnebula", "driftremus", "driftsentinel", "drifttampa", "driftvorschlag", "driftyosemite",
    "driftzr350", "dubsta", "dubsta2", "dubsta3", "dukes", "dukes2", "dukes3", "dump", "dune", "dune2", "dune3", "dune4",
    "dune5", "duster", "duster2", "elegy", "elegy2", "ellie", "emerus", "emperor", "emperor3", "enduro", "entity2",
    "entity3", "entityxf", "envisage", "esskey", "eudora", "eurosx32", "everon", "everon2", "exemplar", "f620", "faction",
    "faction2", "faction3", "fagaloa", "faggio", "faggio2", "faggio3", "fcr", "fcr2", "felon", "felon2", "feltzer2",
    "feltzer3", "firebolt", "firetruk", "fixter", "flashgt", "fmj", "formula", "formula2", "fq2", "fr36", "freecrawler",
    "freight", "freight2", "freightcar", "freightcar2", "freightcar3", "freightcont1", "freightcont2", "freightgrain",
    "frogger2", "fugitive", "furia", "furoregt", "fusilade", "futo", "futo2", "gargoyle", "gauntlet2", "gauntlet3",
    "gauntlet4", "gauntlet5", "gauntlet6", "gb200", "gburrito", "gburrito2", "glendale", "glendale2", "gp1",
    "graintrailer",
    "granger2", "greenwood", "gresley", "growler", "gt500", "guardian", "habanero", "hakuchou", "hakuchou2", "halftrack",
    "handler", "havok", "hellion", "hermes", "hexer", "hotknife", "hotring", "howard", "hunter", "huntley", "hustler",
    "hydra", "imorgon", "impaler", "impaler2", "impaler3", "impaler4", "impaler5", "impaler6", "imperator", "imperator2",
    "imperator3", "inductor", "inductor2", "infernus", "infernus2", "ingot", "innovation", "insurgent", "insurgent2",
    "insurgent3", "intruder", "issi2", "issi3", "issi4", "issi5", "issi6", "issi7", "issi8", "italigtb", "italigtb2",
    "italigto", "italirsx", "iwagen", "jackal", "jb700", "jb7002", "jester", "jester2", "jester3", "jester4", "jester5",
    "jet", "jetmax", "journey", "journey2", "jubilee", "jugular", "kalahari", "kamacho", "kanjo", "kanjosj", "khamelion",
    "khanjali", "komoda", "kosatka", "krieger", "kuruma", "kuruma2", "l35", "landstalker", "landstalker2", "le7b",
    "lectro",
    "lguard", "limo2", "lm87", "locust", "longfin", "lurcher", "luxor", "luxor2", "lynx", "mamba", "mammatus", "manana",
    "manana2", "manchez", "manchez2", "manchez3", "marquis", "marshall", "massacro", "massacro2", "maverick", "menacer",
    "mesa2", "metrotrain", "michelli", "microlight", "minitank", "minivan", "minivan2", "mogul", "molotok", "monroe",
    "monster", "monster3", "monster4", "monster5", "monstrociti", "moonbeam", "moonbeam2", "mule4", "mule5", "nebula",
    "nemesis", "neo", "neon", "nero", "nero2", "nightblade", "nightshade", "nightshark", "nimbus", "ninef", "ninef2",
    "niobe", "nokota", "omnis", "omnisegt", "openwheel1", "openwheel2", "oppressor", "oppressor2", "oracle", "oracle2",
    "osiris", "outlaw", "pRanger", "panthere", "panto", "paradise", "paragon", "paragon2", "paragon3", "pariah",
    "patriot",
    "patriot2", "patriot3", "patrolboat", "pbus", "pbus2", "pcj", "penetrator", "penumbra", "penumbra2", "peyote",
    "peyote2", "peyote3", "pfister811", "phantom2", "phantom3", "picador", "pigalle", "pipistrello", "pizzaboy",
    "polcaracara", "polcoquette4", "poldominator10", "poldorado", "polfaction2", "polgauntlet", "polgreenwood", "police",
    "police2", "police3", "police4", "police5", "policeb", "policeold1", "policeold2", "policet", "policet3",
    "polimpaler5",
    "polimpaler6", "polmav", "polterminus", "pony", "pony2", "postlude", "pounder2", "powersurge", "prairie", "premier",
    "previon", "primo", "primo2", "proptrailer", "prototipo", "pyro", "r300", "radi", "raiden", "raiju", "raketrailer",
    "rallytruck", "rancherxl2", "rapidgt3", "raptor", "ratbike", "ratel", "ratloader", "ratloader2", "rcbandito",
    "reaper",
    "rebel2", "rebla", "reever", "regina", "remus", "retinue", "retinue2", "revolter", "rhapsody", "rhinehart", "riata",
    "riot2", "rocoto", "rogue", "romero", "rrocket", "rt3000", "ruffian", "ruiner", "ruiner2", "ruiner3", "ruiner4",
    "rumpo", "rumpo2", "rumpo3", "ruston", "s80", "sabregt", "sabregt2", "sadler2", "sanchez2", "sanctus", "sandking",
    "sandking2", "savage", "savestra", "sc1", "scarab", "scarab2", "scarab3", "schafter2", "schafter3", "schafter4",
    "schafter5", "schafter6", "schlagen", "schwarzer", "scorcher", "scramjet", "scrap", "seabreeze", "seashark",
    "seashark2", "seashark3", "seasparrow", "seasparrow2", "seasparrow3", "seminole2", "sentinel", "sentinel2",
    "sentinel3",
    "sentinel4", "serrano", "sheava", "sheriff2", "shinobi", "shotaro", "skylift", "slamtruck", "slamvan", "slamvan2",
    "slamvan3", "slamvan4", "slamvan5", "slamvan6", "sm722", "sovereign", "speeder", "speeder2", "speedo", "speedo2",
    "speedo4", "speedo5", "squaddie", "squalo", "stafford", "stalion", "stalion2", "stanier", "starling", "stinger",
    "stingergt", "stingertt", "stockade", "stockade3", "stratum", "streamer216", "streiter", "stretch", "strikeforce",
    "stromberg", "submersible", "submersible2", "sultan", "sultan2", "sultan3", "sultanrs", "superd", "supervolito",
    "supervolito2", "surfer3", "surge", "swift", "swift2", "swinger", "t20", "tahoma", "tailgater", "tailgater2",
    "taipan",
    "tampa", "tampa2", "tampa3", "tanker", "tanker2", "tankercar", "taxi", "technical", "technical2", "technical3",
    "tempesta", "tenf", "tenf2", "terbyte", "terminus", "tezeract", "thrax", "thrust", "thruster", "tigon", "titan",
    "titan2", "toreador", "torero", "torero2", "tornado", "tornado2", "tornado3", "tornado4", "tornado5", "tornado6",
    "toro", "toro2", "toros", "towtruck3", "towtruck4", "tr2", "tr3", "tr4", "tractor2", "tractor3", "trailerlarge",
    "trailerlogs", "trailers", "trailers2", "trailers3", "trailers4", "trailers5", "trailersmall", "trailersmall2",
    "trash2", "trflat", "tribike", "tribike2", "tribike3", "trophytruck", "trophytruck2", "tropic", "tropic2", "tropos",
    "tug", "tula", "tulip", "tulip2", "turismo2", "turismo3", "turismor", "tvtrailer", "tvtrailer2", "tyrant", "tyrus",
    "uranus", "utillitruck", "utillitruck2", "vacca", "vagner", "vagrant", "valkyrie", "valkyrie2", "vamos", "vectre",
    "velum", "velum2", "verlierer2", "verus", "vestra", "vetir", "veto", "veto2", "vigero", "vigero2", "vigero3",
    "vigilante", "vindicator", "virgo", "virgo2", "virgo3", "virtue", "viseris", "visione", "vivanite", "volatol",
    "volatus", "voltic", "voltic2", "voodoo", "voodoo2", "vorschlaghammer", "vortex", "vstr", "warrener", "warrener2",
    "washington", "wastelander", "weevil", "weevil2", "windsor", "windsor2", "winky", "wolfsbane", "xa21", "xls", "xls2",
    "yosemite", "yosemite1500", "yosemite2", "yosemite3", "youga", "youga2", "youga3", "youga4", "youga5", "z190", "zeno",
    "zentorno", "zhaba", "zion", "zion2", "zion3", "zombiea", "zombieb", "zorrusso", "zr350", "zr380", "zr3802", "zr3803",
}

PED_TYPE        = {
    _PLAYER_0              = 0,
    _PLAYER_1              = 1,
    _NETWORK_PLAYER        = 2,
    _PLAYER_2              = 3,
    _CIVMALE               = 4,
    _CIVFEMALE             = 5,
    _COP                   = 6,
    _GANG_ALBANIAN         = 7,
    _GANG_BIKER_1          = 8,
    _GANG_BIKER_2          = 9,
    _GANG_ITALIAN          = 10,
    _GANG_RUSSIAN          = 11,
    _GANG_RUSSIAN_2        = 12,
    _GANG_IRISH            = 13,
    _GANG_JAMAICAN         = 14,
    _GANG_AFRICAN_AMERICAN = 15,
    _GANG_KOREAN           = 16,
    _GANG_CHINESE_JAPANESE = 17,
    _GANG_PUERTO_RICAN     = 18,
    _DEALER                = 19,
    _MEDIC                 = 20,
    _FIREMAN               = 21,
    _CRIMINAL              = 22,
    _BUM                   = 23,
    _PROSTITUTE            = 24,
    _SPECIAL               = 25,
    _MISSION               = 26,
    _SWAT                  = 27,
    _ANIMAL                = 28,
    _ARMY                  = 29,
}

pedBones        = {
    { name = "Root",       ID = 0 },
    { name = "Head",       ID = 12844 },
    { name = "Spine 00",   ID = 23553 },
    { name = "Spine 01",   ID = 24816 },
    { name = "Spine 02",   ID = 24817 },
    { name = "Spine 03",   ID = 24818 },
    { name = "Right Hand", ID = 6286 },
    { name = "Left Hand",  ID = 18905 },
    { name = "Right Foot", ID = 35502 },
    { name = "Left Foot",  ID = 14201 },
}

vehBones        = {
    "chassis", "chassis_lowlod", "chassis_dummy", "seat_dside_f", "seat_dside_r",
    "seat_dside_r1", "seat_dside_r2", "seat_dside_r3", "seat_dside_r4", "seat_dside_r5", "seat_dside_r6", "seat_dside_r7",
    "seat_pside_f", "seat_pside_r", "seat_pside_r1", "seat_pside_r2", "seat_pside_r3", "seat_pside_r4", "seat_pside_r5",
    "seat_pside_r6", "seat_pside_r7", "window_lf1", "window_lf2", "window_lf3", "window_rf1", "window_rf2", "window_rf3",
    "window_lr1", "window_lr2", "window_lr3", "window_rr1", "window_rr2", "window_rr3", "door_dside_f", "door_dside_r",
    "door_pside_f", "door_pside_r", "handle_dside_f", "handle_dside_r", "handle_pside_f", "handle_pside_r", "wheel_lf",
    "wheel_rf", "wheel_lm1", "wheel_rm1", "wheel_lm2", "wheel_rm2", "wheel_lm3", "wheel_rm3", "wheel_lr", "wheel_rr",
    "suspension_lf", "suspension_rf", "suspension_lm", "suspension_rm", "suspension_lr", "suspension_rr", "spring_rf",
    "spring_lf", "spring_rr", "spring_lr", "transmission_f", "transmission_m", "transmission_r", "hub_lf", "hub_rf",
    "hub_lm1", "hub_rm1", "hub_lm2", "hub_rm2", "hub_lm3", "hub_rm3", "hub_lr", "hub_rr", "windscreen", "windscreen_r",
    "window_lf", "window_rf", "window_lr", "window_rr", "window_lm", "window_rm", "bodyshell", "bumper_f", "bumper_r",
    "wing_rf", "wing_lf", "bonnet", "boot", "exhaust", "exhaust_2", "exhaust_3", "exhaust_4", "exhaust_5", "exhaust_6",
    "exhaust_7", "exhaust_8", "exhaust_9", "exhaust_10", "exhaust_11", "exhaust_12", "exhaust_13", "exhaust_14",
    "exhaust_15", "exhaust_16", "engine", "overheat", "overheat_2", "petrolcap", "petroltank", "petroltank_l",
    "petroltank_r", "steering", "hbgrip_l", "hbgrip_r", "headlight_l", "headlight_r", "taillight_l", "taillight_r",
    "indicator_lf", "indicator_rf", "indicator_lr", "indicator_rr", "brakelight_l", "brakelight_r", "brakelight_m",
    "reversinglight_l", "reversinglight_r", "extralight_1", "extralight_2", "extralight_3", "extralight_4", "numberplate",
    "interiorlight", "siren1", "siren2", "siren3", "siren4", "siren5", "siren6", "siren7", "siren8", "siren9", "siren10",
    "siren11", "siren12", "siren13", "siren14", "siren15", "siren16", "siren17", "siren18", "siren19", "siren20",
    "siren_glass1", "siren_glass2", "siren_glass3", "siren_glass4", "siren_glass5", "siren_glass6", "siren_glass7",
    "siren_glass8", "siren_glass9", "siren_glass10", "siren_glass11", "siren_glass12", "siren_glass13", "siren_glass14",
    "siren_glass15", "siren_glass16", "siren_glass17", "siren_glass18", "siren_glass19", "siren_glass20", "spoiler",
    "struts", "misc_a", "misc_b", "misc_c", "misc_d", "misc_e", "misc_f", "misc_g", "misc_h", "misc_i", "misc_j",
    "misc_k",
    "misc_l", "misc_m", "misc_n", "misc_o", "misc_p", "misc_q", "misc_r", "misc_s", "misc_t", "misc_u", "misc_v",
    "misc_w",
    "misc_x", "misc_y", "misc_z", "misc_1", "misc_2", "weapon_1a", "weapon_1b", "weapon_1c", "weapon_1d", "weapon_1a_rot",
    "weapon_1b_rot", "weapon_1c_rot", "weapon_1d_rot", "weapon_2a", "weapon_2b", "weapon_2c", "weapon_2d",
    "weapon_2a_rot",
    "weapon_2b_rot", "weapon_2c_rot", "weapon_2d_rot", "weapon_3a", "weapon_3b", "weapon_3c", "weapon_3d",
    "weapon_3a_rot",
    "weapon_3b_rot", "weapon_3c_rot", "weapon_3d_rot", "weapon_4a", "weapon_4b", "weapon_4c", "weapon_4d",
    "weapon_4a_rot",
    "weapon_4b_rot", "weapon_4c_rot", "weapon_4d_rot", "turret_1base", "turret_1barrel", "turret_2base", "turret_2barrel",
    "turret_3base", "turret_3barrel", "ammobelt", "searchlight_base", "searchlight_light", "attach_female", "roof",
    "roof2",
    "soft_1", "soft_2", "soft_3", "soft_4", "soft_5", "soft_6", "soft_7", "soft_8", "soft_9", "soft_10", "soft_11",
    "soft_12", "soft_13", "forks", "mast", "carriage", "fork_l", "fork_r", "forks_attach", "frame_1", "frame_2",
    "frame_3",
    "frame_pickup_1", "frame_pickup_2", "frame_pickup_3", "frame_pickup_4", "freight_cont", "freight_bogey",
    "freightgrain_slidedoor", "door_hatch_r", "door_hatch_l", "tow_arm", "tow_mount_a", "tow_mount_b", "tipper",
    "combine_reel", "combine_auger", "slipstream_l", "slipstream_r", "arm_1", "arm_2", "arm_3", "arm_4", "scoop", "boom",
    "stick", "bucket", "shovel_2", "shovel_3", "Lookat_UpprPiston_head", "Lookat_LowrPiston_boom", "Boom_Driver",
    "cutter_driver", "vehicle_blocker", "extra_1", "extra_2", "extra_3", "extra_4", "extra_5", "extra_6", "extra_7",
    "extra_8", "extra_9", "extra_ten", "extra_11", "extra_12", "break_extra_1", "break_extra_2", "break_extra_3",
    "break_extra_4", "break_extra_5", "break_extra_6", "break_extra_7", "break_extra_8", "break_extra_9",
    "break_extra_10",
    "mod_col_1", "mod_col_2", "mod_col_3", "mod_col_4", "mod_col_5", "handlebars", "forks_u", "forks_l", "wheel_f",
    "swingarm", "wheel_r", "crank", "pedal_r", "pedal_l", "static_prop", "moving_prop", "static_prop2", "moving_prop2",
    "rudder", "rudder2", "wheel_rf1_dummy", "wheel_rf2_dummy", "wheel_rf3_dummy", "wheel_rb1_dummy", "wheel_rb2_dummy",
    "wheel_rb3_dummy", "wheel_lf1_dummy", "wheel_lf2_dummy", "wheel_lf3_dummy", "wheel_lb1_dummy", "wheel_lb2_dummy",
    "wheel_lb3_dummy", "bogie_front", "bogie_rear", "rotor_main", "rotor_rear", "rotor_main_2", "rotor_rear_2",
    "elevators",
    "tail", "outriggers_l", "outriggers_r", "rope_attach_a", "rope_attach_b", "prop_1", "prop_2", "elevator_l",
    "elevator_r", "rudder_l", "rudder_r", "prop_3", "prop_4", "prop_5", "prop_6", "prop_7", "prop_8", "rudder_2",
    "aileron_l", "aileron_r", "airbrake_l", "airbrake_r", "wing_l", "wing_r", "wing_lr", "wing_rr", "engine_l",
    "engine_r",
    "nozzles_f", "nozzles_r", "afterburner", "wingtip_1", "wingtip_2", "gear_door_fl", "gear_door_fr", "gear_door_rl1",
    "gear_door_rr1", "gear_door_rl2", "gear_door_rr2", "gear_door_rml", "gear_door_rmr", "gear_f", "gear_rl", "gear_lm1",
    "gear_rr", "gear_rm1", "gear_rm", "prop_left", "prop_right", "legs", "attach_male", "draft_animal_attach_lr",
    "draft_animal_attach_rr", "draft_animal_attach_lm", "draft_animal_attach_rm", "draft_animal_attach_lf",
    "draft_animal_attach_rf", "wheelcover_l", "wheelcover_r", "barracks", "pontoon_l", "pontoon_r", "no_ped_col_step_l",
    "no_ped_col_strut_1_l", "no_ped_col_strut_2_l", "no_ped_col_step_r", "no_ped_col_strut_1_r", "no_ped_col_strut_2_r",
    "light_cover", "emissives", "neon_l", "neon_r", "neon_f", "neon_b", "dashglow", "doorlight_lf", "doorlight_rf",
    "doorlight_lr", "doorlight_rr", "unknown_id", "dials", "engineblock", "bobble_head", "bobble_base", "bobble_hand",
    "chassis_Control",
}

reserved_keys_T = {
    kb   = {
        0x01,
        0x07,
        0x0A,
        0x0B,
        0x1B,
        0x24,
        0x2C,
        0x2D,
        0x46,
        0x5B,
        0x5C,
        0x5E,
    },
    gpad = {
        23,
        24,
        25,
        71,
        75,
    }
}


weapbones_T              = {
    "WAPLasr",
    "WAPLasr_2",
    "WAPFlshLasr",
    "WAPFlshLasr_2",
    "WAPFlsh",
    "WAPFlsh_2",
    "gun_barrels",
    "gun_muzzle"
}

plane_bones_T            = {
    "afterburner",
    "aileron_l",
    "aileron_r",
    "airbrake_l",
    "airbrake_r",
    "chassis_dummy",
    "elevators",
    "elevator_l",
    "elevator_r",
    "emissives",
    "rudder",
    "rudder_2",
    "rudder_l",
    "rudder_r",
    "door_hatch_l",
    "door_hatch_r",
    "door_dside_f",
    "door_dside_r",
    "door_pside_f",
    "door_pside_r",
    "exhaust",
    "exhaust_1",
    "exhaust_2",
    "exhaust_3",
    "exhaust_4",
    "exhaust_5",
    "exhaust_6",
    "exhaust_7",
    "exhaust_8",
    "exhaust_9",
    "exhaust_10",
    "exhaust_11",
    "exhaust_12",
    "exhaust_13",
    "exhaust_14",
    "exhaust_15",
    "exhaust_16",
    "handle_dside_f",
    "handle_dside_r",
    "handle_pside_f",
    "handle_pside_r",
    "legs",
    "nozzles_f",
    "nozzles_r",
    "outriggers_l",
    "outriggers_r",
    "prop_1",
    "prop_2",
    "prop_3",
    "prop_4",
    "prop_5",
    "prop_6",
    "prop_7",
    "prop_8",
    "prop_left",
    "prop_right",
    "rotor_main",
    "rotor_rear",
    "rotor_main_2",
    "rotor_rear_2",
    "tail",
    "wing_l",
    "wing_r",
    "wing_lr",
    "wing_rr",
    "wingtip_1",
    "wingtip_2",
}

driftSmokeColors         = {
    "White",
    "Black",
    "Red",
    "Green",
    "Blue",
    "Yellow",
    "Orange",
    "Pink",
    "Purple"
}

objectives_T             = {
    1,
    9,
    143,
    144,
    145,
    146,
    306,
    535,
    536,
    537,
    538,
    539,
    540,
    541,
    542,
}

vehOffsets_T             = {
    fc   = 0x001C,
    ft   = 0x0014,
    rc   = 0x0020,
    rt   = 0x0018,
    cg   = 0x0882,
    ng   = 0x0880,
    tg   = 0x0886,
    vm   = 0x000C,
    bf   = 0x006C,
    dfm  = 0x0014,
    accm = 0x004C,
    cofm = 0x0020,
}

handguns_T               = {
    0x1B06D571,
    0xBFE256D4,
    0x5EF9FEC4,
    0x22D8FE39,
    0x3656C8C1,
    0x99AEEB3B,
    0xBFD21232,
    0x88374054,
    0xD205520E,
    0x83839C4,
    0x47757124,
    0xDC4DB296,
    0xC1B3C3D1,
    0xCB96392F,
    0x97EA20B8,
    0xAF3696A1,
    0x2B5EF5EC,
    0x917F6C8C
}

cell_inputs_T            = {
    { control = 172, input = 1 },
    { control = 173, input = 2 },
    { control = 174, input = 3 },
    { control = 175, input = 4 },
    { control = 176, input = 5 },
    { control = 177, input = 5 },
    { control = 178, input = 5 },
    { control = 179, input = 5 },
    { control = 180, input = 1 },
    { control = 181, input = 2 },
}

radio_stations           = {
    { station = "RADIO_11_TALK_02",               name = "Blaine County Radio" },
    { station = "RADIO_21_DLC_XM17",              name = "Blonded Los Santos 97.8 FM" },
    { station = "RADIO_04_PUNK",                  name = "Channel X" },
    { station = "RADIO_08_MEXICAN",               name = "East Los FM" },
    { station = "RADIO_14_DANCE_02",              name = "FlyLo FM" },
    { station = "RADIO_23_DLC_XM19_RADIO",        name = "iFruit Radio" },
    { station = "RADIO_34_DLC_HEI4_KULT",         name = "Kult FM" },
    { station = "RADIO_01_CLASS_ROCK",            name = "Los Santos Rock Radio" },
    { station = "RADIO_22_DLC_BATTLE_MIX1_RADIO", name = "Los Santos Underground Radio" },
    { station = "RADIO_36_AUDIOPLAYER",           name = "Media Player" },
    { station = "RADIO_02_POP",                   name = "Non-Stop-Pop FM" },
    { station = "RADIO_03_HIPHOP_NEW",            name = "Radio Los Santos" },
    { station = "RADIO_16_SILVERLAKE",            name = "Radio Mirror Park" },
    { station = "RADIO_06_COUNTRY",               name = "Rebel Radio" },
    { station = "RADIO_19_USER",                  name = "Self Radio" },
    { station = "RADIO_07_DANCE_01",              name = "Soulwax FM" },
    { station = "RADIO_17_FUNK",                  name = "Space 103.2" },
    { station = "RADIO_27_DLC_PRHEI4",            name = "Still Slipping Los Santos" },
    { station = "RADIO_12_REGGAE",                name = "The Blue Ark" },
    { station = "RADIO_20_THELAB",                name = "The Lab" },
    { station = "RADIO_15_MOTOWN",                name = "The Lowdown 9.11" },
    { station = "RADIO_35_DLC_HEI4_MLR",          name = "The Music Locker" },
    { station = "RADIO_18_90S_ROCK",              name = "Vinewood Boulevard Radio" },
    { station = "RADIO_09_HIPHOP_OLD",            name = "West Coast Classics" },
    { station = "RADIO_05_TALK_01",               name = "West Coast Talk Radio" },
    { station = "RADIO_13_JAZZ",                  name = "Worldwide FM" },
}

male_sounds_T            = {
    { name = "Angry Chinese",     soundName = "GENERIC_INSULT_HIGH",      soundRef = "MP_M_SHOPKEEP_01_CHINESE_MINI_01" },
    { name = "Begging Chinese",   soundName = "GUN_BEG",                  soundRef = "MP_M_SHOPKEEP_01_CHINESE_MINI_01" },
    { name = "Call The Cops!",    soundName = "PHONE_CALL_COPS",          soundRef = "MP_M_SHOPKEEP_01_CHINESE_MINI_01" },
    { name = "CHARGE!!",          soundName = "GENERIC_WAR_CRY",          soundRef = "S_M_Y_BLACKOPS_01_BLACK_MINI_01" },
    { name = "Creep",             soundName = "SHOUT_PERV_AT_WOMAN_PERV", soundRef = "A_M_Y_MEXTHUG_01_LATINO_FULL_01" },
    { name = "Clown Dying",       soundName = "CLOWN_DEATH",              soundRef = "CLOWNS" },
    { name = "Clown Laughing",    soundName = "CLOWN_LAUGH",              soundRef = "CLOWNS" },
    { name = "Franklin Laughing", soundName = "LAUGH",                    soundRef = "WAVELOAD_PAIN_FRANKLIN" },
    { name = "How are you?",      soundName = "GENERIC_HOWS_IT_GOING",    soundRef = "S_M_M_PILOT_01_WHITE_FULL_01" },
    { name = "Insult",            soundName = "GENERIC_INSULT_HIGH",      soundRef = "S_M_Y_SHERIFF_01_WHITE_FULL_01" },
    { name = "Insult 02",         soundName = "GENERIC_FUCK_YOU",         soundRef = "FRANKLIN_DRUNK" },
    { name = "Pain",              soundName = "ELECTROCUTION",            soundRef = "MISTERK" },
    { name = "Pain 02",           soundName = "TOOTHPULL_PAIN",           soundRef = "MISTERK" },
    { name = "Threaten",          soundName = "CHALLENGE_THREATEN",       soundRef = "S_M_Y_BLACKOPS_01_BLACK_MINI_01" },
    { name = "You Look Stupid!",  soundName = "FRIEND_LOOKS_STUPID",      soundRef = "FRANKLIN_DRUNK" },
}

female_sounds_T          = {
    { name = "Blowjob",        soundName = "SEX_ORAL",                   soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
    { name = "Call The Cops!", soundName = "PHONE_CALL_COPS",            soundRef = "A_F_M_SALTON_01_WHITE_FULL_01" },
    { name = "Hooker Offer",   soundName = "HOOKER_OFFER_SERVICE",       soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
    { name = "How are you?",   soundName = "GENERIC_HOWS_IT_GOING",      soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
    { name = "Insult",         soundName = "GENERIC_INSULT_HIGH",        soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
    { name = "Let's Go!",      soundName = "CHALLENGE_ACCEPTED_GENERIC", soundRef = "A_F_M_SALTON_01_WHITE_FULL_01" },
    { name = "Moan",           soundName = "SEX_GENERIC_FEM",            soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
    { name = "Roast",          soundName = "GAME_HECKLE",                soundRef = "A_F_M_SALTON_01_WHITE_FULL_01" },
    { name = "Threaten",       soundName = "CHALLENGE_THREATEN",         soundRef = "S_F_Y_HOOKER_03_BLACK_FULL_01" },
}

projectile_types_T       = {
    0xB1CA77B1,
    0xA284510B,
    0x4DD2DC56,
    0x6D544C99,
    0x63AB0442,
    0xDB26713A,
    0xFEA23564,
    0x166218FF,
    0x13579279,
    0xBEFDC581,
    0x2024F4E8,
    0x2C082D7D,
    0x73F7C04B,
    0xF8A3939F,
    0xCF0896E0,
    0xE2822A29,
    0xEFFD014B,
    0x46B89C8E,
    0x9F1A91DE,
    2138347493,
    1672152130,
    1966766321,
    162065050,
    519052682,
    1820910717,
    2092838988,
    1151689097,
    1987049393,
    2011877270,
    153396725,
    1198717003,
    341154295,
    1347266149,
    1686798800,
    1995916491,
    375527679,
    324506233,
    84788907,
    125959754,
    615608432,
    741814745,
    785467445,
    968648323,
    -- 220773539, -- cluster bombs
    1508567460,
    1776356704,
    1414837446,
    1834241177,
    -1813897027,
    -1568386805,
    -1001503935,
    -1420407917,
    -1169823560,
    -1258723020,
    -651022627,
    -- -647126932, -- spike mine
    -1950890434,
    -699583383,
    -1838445340,
    -1125578533,
    -729187314,
    -1572351938,
    -901318531,
    -410795078,
    -1638383454,
    -123497569,
    -821520672,
    -1090665087,
    -2012408590,
    -146175596,
    -1538514291,
}

pe_combat_attributes_T   = {
    { id = 5,  bool = true },
    { id = 13, bool = true },
    { id = 21, bool = true },
    { id = 28, bool = true },
    { id = 31, bool = true },
    { id = 38, bool = true },
    { id = 42, bool = true },
    { id = 46, bool = true },
    { id = 58, bool = true },
    { id = 71, bool = true },
    { id = 17, bool = false },
    { id = 63, bool = false },
}

pe_config_flags_T        = {
    { id = 128, bool = true },
    { id = 140, bool = true },
    { id = 141, bool = true },
    { id = 208, bool = true },
    { id = 229, bool = true },
    { id = 294, bool = true },
    { id = 435, bool = true },
}

random_quotes_T          = {
    "FACT: AWD drifting isn't drifting.",
    "People who put M badges on a non-M BMW should go to prison.",
    "Speed has never killed anyone. Suddenly becoming stationary, that's what gets you.",
    "Being a lorry driver is hard: change gear change gear change gear change gear, check your mirrors, murder a prostitute, change gear change gear, murder... That's a lot of effort in a day.",
    "Jaguar is pronounced just the way it's spelled.",
    "Some say, the person who wrote this script has a full size tattoo of his face... on his face.",
    "Fun Fact: Harmless is not really harmless. He's a Kung-Fu master.",
    "The drift feature in this script is an ingenious solution to a problem that should never have existed.",
    "A car guy's diet: Gasoline and burnt rubber.",
    "There is never enough horsepower, just not enough traction.",
    "Fun Fact: Bananas are berries, but strawberries aren't.",
    "The best way to make a small fortune racing is to start with a large fortune and work your way down.",
    "Fun Fact: DeadlineEm is actually my grandfather.",
    "You can sleep in your car, but you can't race your house.",
    "It don't matter if you win by an inch or a mile. Winning's winning.",
    "There's no 'wax on wax off' with drifting. You learn by doing it. The first drifters invented drifting out in the touge by feeling it. So feel it.",
    "Dude, I almost had you!\10\10    ¤ RIP, Paul Walker ¤",
    "Fun Fact: USBMenus has a tattoo of a USB stick on his forehead. He really loves USBs.",
    "Why did the car go to therapy? Because it had too many breakdowns! Haha... I uh.. I think I need therapy.",
    "Fun Fact: The inventor of the Pringles can is now buried in one.",
    "Life is too short to drive boring cars.",
    "Ok I understand that at some point in time someone saw a bug on a bed and just thought: 'I'm gonna name them bed bugs'. Yeah that makes sense but... Who the fuck named them cockroaches?",
    "What's the difference between your job and your wife? Your job still sucks after 5 years.",
}

flight_controls_T        = {
    72,
    75,
    87,
    88,
    89,
    90,
    106,
    107,
    108,
    109,
    110,
    111,
    112,
}

-- CVehicle::HandlingFlags
HF                       = {
    _SMOOTHED_COMPRESSION                      = 0,
    _REDUCED_MOD_MASS                          = 1,
    _HAS_KERS                                  = 2,
    _HAS_RALLY_TYRES                           = 3,
    _NO_HANDBRAKE                              = 4,
    _STEER_REARWHEELS                          = 5,
    _HANDBRAKE_REARWHEELSTEER                  = 6,
    _STEER_ALL_WHEELS                          = 7,
    _FREEWHEEL_NO_GAS                          = 8,
    _NO_REVERSE                                = 9,
    _REDUCED_RIGHTING_FORCE                    = 10,
    _STEER_NO_WHEELS                           = 11,
    _CVT                                       = 12,
    _ALT_EXT_WHEEL_BOUNDS_BEH                  = 13,
    _DONT_RAISE_BOUNDS_AT_SPEED                = 14,
    _EXT_WHEEL_BOUNDS_COL                      = 15,
    _LESS_SNOW_SINK                            = 16,
    _TYRES_CAN_CLIP                            = 17,
    _REDUCED_DRIVE_OVER_DAMAGE                 = 18,
    _ALT_EXT_WHEEL_BOUNDS_SHRINK               = 19,
    _OFFROAD_ABILITIES                         = 20,
    _OFFROAD_ABILITIES_X2                      = 21,
    _TYRES_RAISE_SIDE_IMPACT_THRESHOLD         = 22,
    _OFFROAD_INCREASED_GRAVITY_NO_FOLIAGE_DRAG = 23,
    _ENABLE_LEAN                               = 24,
    _FORCE_NO_TC_OR_SC                         = 25,
    _HEAVYARMOUR                               = 26,
    _ARMOURED                                  = 27,
    _SELF_RIGHTING_IN_WATER                    = 28,
    IMPROVED_RIGHTING_FORCE                    = 29,
    _LOW_SPEED_WHEELIES                        = 30,
}

-- CVehicle::ModelFlags
MF                       = {
    _IS_VAN                    = 0,
    _IS_BUS                    = 1,
    _IS_LOW                    = 2,
    _IS_BIG                    = 3,
    _ABS_STD                   = 4, -- abs standard
    _ABS_OPTION                = 5, -- abs when upgraded
    _ABS_ALT_STD               = 6, -- alternate abs standard
    _ABS_ALT_OPTION            = 7, -- alternate abs when upgraded
    _NO_DOORS                  = 8,
    _TANDEM_SEATING            = 9,
    _SIT_IN_BOAT               = 10,
    _HAS_TRACKS                = 11,
    _NO_EXHAUST                = 12,
    _DOUBLE_EXHAUST            = 13,
    _NO_1STPERSON_LOOKBEHIND   = 14,
    _CAN_ENTER_IF_NO_DOOR      = 15,
    _AXLE_F_TORSION            = 16,
    _AXLE_F_SOLID              = 17,
    _AXLE_F_MCPHERSON          = 18,
    _ATTACH_PED_TO_BODYSHELL   = 19,
    _AXLE_R_TORSION            = 20,
    _AXLE_R_SOLID              = 21,
    _AXLE_R_MCPHERSON          = 22,
    _DONT_FORCE_GRND_CLEARANCE = 23,
    _DONT_RENDER_STEER         = 24,
    _NO_WHEEL_BURST            = 25,
    _INDESTRUCTIBLE            = 26,
    _DOUBLE_FRONT_WHEELS       = 27,
    _IS_RC                     = 28,
    _DOUBLE_REAR_WHEELS        = 29,
    _NO_WHEEL_BREAK            = 30,
    _EXTRA_CAMBER              = 31,
}

-- CVehicle::ModelInfoFlags
VMF                      = {
    _HAS_LIVERY                                  = 7,
    _SPORTS                                      = 9,
    _DONT_ROTATE_TAIL_ROTOR                      = 26,
    _PARKING_SENSORS                             = 27,
    _PEDS_CAN_STAND_ON_TOP                       = 28,
    _LAW_ENFORCEMENT                             = 31,
    _EMERGENCY_SERVICE                           = 32,
    _RICH_CAR                                    = 36,
    _AVERAGE_CAR                                 = 37,
    _POOR_CAR                                    = 38,
    _ALLOWS_RAPPEL                               = 39,
    _IS_ELECTRIC                                 = 43,
    _CANNOT_BE_MODDED                            = 54,
    _HAS_NO_ROOF                                 = 64,
    _HAS_BULLETPROOF_GLASS                       = 76,
    _CANNOT_BE_PICKUP_BY_CARGOBOB                = 95,
    _DISABLE_BUSTING                             = 112,
    _ALLOW_HATS_NO_ROOF                          = 117,
    _HAS_LOWRIDER_HYDRAULICS                     = 119,
    _HAS_BULLET_RESISTANT_GLASS                  = 120,
    _HAS_INCREASED_RAMMING_FORCE                 = 121,
    _HAS_LOWRIDER_DONK_HYDRAULICS                = 123,
    _JUMPING_CAR                                 = 125,
    _HAS_ROCKET_BOOST                            = 126,
    _RAMMING_SCOOP                               = 127,
    _HAS_PARACHUTE                               = 128,
    _HAS_RAMP                                    = 129,
    _FRONT_BOOT                                  = 131,
    _DONT_HOLD_LOW_GEARS_WHEN_ENGINE_UNDER_LOAD  = 136,
    _HAS_GLIDER                                  = 137,
    _INCREASE_LOW_SPEED_TORQUE                   = 138,
    _EQUIP_UNARMED_ON_ENTER                      = 152,
    _HAS_VERTICAL_FLIGHT_MODE                    = 154,
    _DROP_SUSPENSION_WHEN_STOPPED                = 157,
    _HAS_VERTICAL_ROCKET_BOOST                   = 161,
    _NO_HEAVY_BRAKE_ANIMATION                    = 168,
    _HAS_INCREASED_RAMMING_FORCE_VS_ALL_VEHICLES = 172,
    _HAS_NITROUS_MOD                             = 174,
    _HAS_JUMP_MOD                                = 175,
    _HAS_RAMMING_SCOOP_MOD                       = 176,
    _HAS_SUPER_BRAKES_MOD                        = 177,
    _CRUSHES_OTHER_VEHICLES                      = 178,
    _RAMP_MOD                                    = 182,
    _HAS_SIDE_SHUNT                              = 184,
    _HAS_SUPERCHARGER                            = 188,
    _SPOILER_MOD_DOESNT_INCREASE_GRIP            = 194,
    _NO_REVERSING_ANIMATION                      = 195,
    _IS_FORMULA_VEHICLE                          = 197,
}

-- AnimFlags
AF                       = {

    -- TODO:
    -- Rework Anim Flags in the Actions section
    -- to bitwise operations instead of simple
    -- arithmetic additions.

    _LOOPING                          = 1 << 0,
    _HOLD_LAST_FRAME                  = 1 << 1,
    _REPOSITION_WHEN_FINISHED         = 1 << 2,
    _NOT_INTERRUPTABLE                = 1 << 3,
    _UPPERBODY                        = 1 << 4,
    _SECONDARY                        = 1 << 5,
    _REORIENT_WHEN_FINISHED           = 1 << 6,
    _ABORT_ON_PED_MOVEMENT            = 1 << 7,
    _ADDITIVE                         = 1 << 8,
    _TURN_OFF_COLLISION               = 1 << 9,
    _OVERRIDE_PHYSICS                 = 1 << 10,
    _IGNORE_GRAVITY                   = 1 << 11,
    _EXTRACT_INITIAL_OFFSET           = 1 << 12,
    _EXIT_AFTER_INTERRUPTED           = 1 << 13,
    _TAG_SYNC_IN                      = 1 << 14,
    _TAG_SYNC_OUT                     = 1 << 15,
    _TAG_SYNC_CONTINUOUS              = 1 << 16,
    _FORCE_START                      = 1 << 17,
    _USE_KINEMATIC_PHYSICS            = 1 << 18,
    _USE_MOVER_EXTRACTION             = 1 << 19,
    _HIDE_WEAPON                      = 1 << 20,
    _ENDS_IN_DEAD_POSE                = 1 << 21,
    _ACTIVATE_RAGDOLL_ON_COLLISION    = 1 << 22,
    _DONT_EXIT_ON_DEATH               = 1 << 23,
    _ABORT_ON_WEAPON_DAMAGE           = 1 << 24,
    _DISABLE_FORCED_PHYSICS_UPDATE    = 1 << 25,
    _PROCESS_ATTACHMENTS_ON_START     = 1 << 26,
    _EXPAND_PED_CAPSULE_FROM_SKELETON = 1 << 27,
    _USE_ALTERNATIVE_FP_ANIM          = 1 << 28,
    _BLENDOUT_WRT_LAST_FRAME          = 1 << 29,
    _USE_FULL_BLENDING                = 1 << 30,
}

Global_262145            = {
    f_4413  = 262145 + 4413,  -- int Snow Weather
    f_13059 = 262145 + 13059, -- int VIP Work CD
    f_13060 = 262145 + 13060, -- int VIP Challenge CD
    f_15397 = 262145 + 15397, -- int Hangar CD_1 *(600000ms)*
    f_15499 = 262145 + 15499, -- int CEO Buy CD *(300000ms)*
    f_15500 = 262145 + 15500, -- int CEO Sell CD *(1800000ms)*
    f_15501 = 262145 + 15501, -- int CEO Buy Failure CD *(off)*
    f_15502 = 262145 + 15502, -- int CEO Sell Failure CD *(off)*
    f_15624 = 262145 + 15624, -- bool CEO Disable Air Attacked Sell Mission *(false)*
    f_15636 = 262145 + 15636, -- bool CEO Disable Air Drop Sell Mission *(false)*
    f_15642 = 262145 + 15642, -- bool CEO Disable Fly Low Sell Mission *(false)*
    f_15643 = 262145 + 15643, -- bool CEO Disable Restricted Airspace Sell Mission *(false)*
    f_15649 = 262145 + 15649, -- bool CEO Disable Attacked Sell Mission *(false)*
    f_15651 = 262145 + 15651, -- bool CEO Disable Defend Sell Mission *(false)*
    f_15679 = 262145 + 15679, -- bool CEO Disable No-Damage Sell Mission *(false)*
    f_15680 = 262145 + 15680, -- bool CEO Disable Sea Attacked Sell Mission *(false)*
    f_15686 = 262145 + 15686, -- bool CEO Disable Sea Defend Sell Mission *(false)*
    f_15692 = 262145 + 15692, -- bool CEO Disable Sting Operation Sell Mission *(false)*
    f_15698 = 262145 + 15698, -- bool CEO Disable Trackify Sell Mission *(false)*
    f_17290 = 262145 + 17290, -- int Weed Production Time *(360000ms)*
    f_17291 = 262145 + 17291, -- int Meth Production Time *(180000ms)*
    f_17292 = 262145 + 17292, -- int Coke Production Time *(3000000ms)*
    f_17293 = 262145 + 17293, -- int Fake Documents Production Time *(300000ms)*
    f_17294 = 262145 + 17294, -- int Fake Cash Production Time *(720000ms)*
    f_17319 = 262145 + 17319, -- int Fake Documents Unit Value
    f_17320 = 262145 + 17320, -- int Cash Factory Unit Value
    f_17321 = 262145 + 17321, -- int Cocaine Unit Value
    f_17322 = 262145 + 17322, -- int Meth Unit Value
    f_17323 = 262145 + 17323, -- int Weed Unit Value
    f_17324 = 262145 + 17324, -- int Acid Unit Value
    f_17325 = 262145 + 17325, -- int Fake Documents Equipment Upgrade Boost Amount
    f_17326 = 262145 + 17326, -- int Cash Factory Equipment Upgrade Boost Amount
    f_17327 = 262145 + 17327, -- int Cocaine Equipment Upgrade Boost Amount
    f_17328 = 262145 + 17328, -- int Meth Equipment Upgrade Boost Amount
    f_17329 = 262145 + 17329, -- int Weed Equipment Upgrade Boost Amount
    f_17330 = 262145 + 17330, -- int Acid Lab Upgrade Boost Amount
    f_17331 = 262145 + 17331, -- int Fake Documents Staff Upgrade Boost Amount
    f_17332 = 262145 + 17332, -- int Cash Factory Staff Upgrade Boost Amount
    f_17333 = 262145 + 17333, -- int Cocaine Staff Upgrade Boost Amount
    f_17334 = 262145 + 17334, -- int Meth Staff Upgrade Boost Amount
    f_17335 = 262145 + 17335, -- int Weed Staff Upgrade Boost Amount
    f_18356 = 262145 + 18356, -- bool MC Disable Convoy Sell Mission *(false)*
    f_18358 = 262145 + 18358, -- bool MC Disable Trashmaster Sell Mission *(false)*
    f_18361 = 262145 + 18361, -- bool MC Disable Proven Sell Mission *(false)*
    f_18363 = 262145 + 18363, -- bool MC Disable Friends In Need Sell Mission *(false)*
    f_18366 = 262145 + 18366, -- bool MC Disable Border Patrol Sell Mission *(false)*
    f_18388 = 262145 + 18388, -- bool MC Disable Heli Drop Sell Mission *(false)*
    f_18391 = 262145 + 18391, -- bool MC Disable Post OP Sell Mission *(false)*
    f_18393 = 262145 + 18393, -- bool MC Disable Air Drop Sell Mission *(false)*
    f_18398 = 262145 + 18398, -- bool MC Disable Sting Operation Sell Mission *(false)*
    f_18400 = 262145 + 18400, -- bool MC Disable Benson Sell Mission *(false)*
    f_18408 = 262145 + 18408, -- bool MC Disable Race Sell Mission *(false)*
    f_18571 = 262145 + 18571, -- int MC Work CD *(180000ms)*
    f_19077 = 262145 + 19077, -- int I/E Vehicle Source CD *(180000ms)*
    f_19153 = 262145 + 19153, -- int I/E Vehicle Sell CD *(180000ms)*
    f_19432 = 262145 + 19432, -- int I/E Vehicle Sell CD_1 *(1200000ms)*
    f_19433 = 262145 + 19433, -- int I/E Vehicle Sell CD_2 *(1680000ms)*
    f_19434 = 262145 + 19434, -- int I/E Vehicle Sell CD_3 *(2340000ms)*
    f_19435 = 262145 + 19435, -- int I/E Vehicle Sell CD_4 *(2880000ms)*
    f_21254 = 262145 + 21254, -- int Bunker Crate Value
    f_21255 = 262145 + 21255, -- int Bunker Equipment Upgrade Boost Amount
    f_21256 = 262145 + 21256, -- int Bunker Staff Upgrade Boost Amount
    f_21286 = 262145 + 21286, -- int MOC Request CD *(120000)*
    f_21573 = 262145 + 21573, -- int Acid Lab Request CD *(300000)*
    f_22433 = 262145 + 22433, -- int Hangar Steal CD_1 *(120000ms)*
    f_22434 = 262145 + 22434, -- int Hangar Steal CD_2 *(180000ms)*
    f_22435 = 262145 + 22435, -- int Hangar Steal CD_3 *(240000ms)*
    f_22472 = 262145 + 22472, -- int Hangar Heavy Lifting Sell Mission *(1.0)*
    f_22474 = 262145 + 22474, -- int Hangar Sell CD *(180000ms)*
    f_22509 = 262145 + 22509, -- int Hangar Contested Sell Mission *(1.0)*
    f_22511 = 262145 + 22511, -- int Hangar Agile Delivery Sell Mission *(1.0)*
    f_22513 = 262145 + 22513, -- int Hangar Precision Delivery Sell Mission *(1.0)*
    f_22515 = 262145 + 22515, -- int Hangar Flying Fortress Sell Mission *(1.0)*
    f_22517 = 262145 + 22517, -- int Hangar Fly Low Sell Mission *(1.0)*
    f_22519 = 262145 + 22519, -- int Hangar Air Delivery Sell Mission *(1.0)*
    f_22521 = 262145 + 22521, -- int Hangar Air Police Sell Mission *(1.0)*
    f_22523 = 262145 + 22523, -- int Hangar Under The Radar Sell Mission *(1.0)*
    f_22732 = 262145 + 22732, -- int Orbital Cannon CD *(2880000ms)*
    f_24026 = 262145 + 24026, -- int Nightclub Management CD *(300000ms)*
    f_24047 = 262145 + 24047, -- int Nightclub Sell Mission Single Drop *(1.0)*
    f_24048 = 262145 + 24048, -- int Nightclub Sell Mission Multi Drop *(1.0)*
    f_24049 = 262145 + 24049, -- int Nightclub Sell Mission Hack Drop *(1.0)*
    f_24050 = 262145 + 24050, -- int Nightclub Sell Mission Roadblock *(1.0)*
    f_24051 = 262145 + 24051, -- int Nightclub Sell Mission Protect Buyer *(1.0)*
    f_24052 = 262145 + 24052, -- int Nightclub Sell Mission Undercover Cops *(1.0)*
    f_24053 = 262145 + 24053, -- int Nightclub Sell Mission Offshore Transfer *(1.0)*
    f_24054 = 262145 + 24054, -- int Nightclub Sell Mission Not a Scratch *(1.0)*
    f_24055 = 262145 + 24055, -- int Nightclub Sell Mission Follow Heli *(1.0)*
    f_24056 = 262145 + 24056, -- int Nightclub Sell Mission Find Buyer *(1.0)*
    f_24208 = 262145 + 24208, -- int Terrorbyte Jobs Global CD *(300000ms)*
    f_24209 = 262145 + 24209, -- int Terrorbyte Bank Job CD *(1800000ms)*
    f_24210 = 262145 + 24210, -- int Terrorbyte Data Hack CD *(1800000ms)*
    f_24211 = 262145 + 24211, -- int Terrorbyte Infiltration CD *(1800000ms)*
    f_24212 = 262145 + 24212, -- int Terrorbyte Jewel Store CD *(1800000ms)*
    f_24234 = 262145 + 24234, -- int Terrorbyte Drone CD *(60000ms)*
    f_24235 = 262145 + 24235, -- int Terrorbyte Drone Shock CD *(12000ms)*
    f_24236 = 262145 + 24236, -- int Terrorbyte Drone Shock Damage To Players *(1)*
    f_24237 = 262145 + 24237, -- int Terrorbyte Drone Shock Damage To NPCs *(250)*
    f_24238 = 262145 + 24238, -- int Terrorbyte Drone Detonate Time *(7000ms)*
    f_24239 = 262145 + 24239, -- int Terrorbyte Drone Boost Duration *(4000ms)*
    f_24240 = 262145 + 24240, -- int Terrorbyte Drone Boost Recharge Time *(15000ms)*
    f_24241 = 262145 + 24241, -- int Terrorbyte Drone Health *(100)*
    f_24242 = 262145 + 24242, -- int Terrorbyte Drone Height Limit *(200)*
    f_24243 = 262145 + 24243, -- int Terrorbyte Drone Distance Limit *(500.0)*
    f_24244 = 262145 + 24244, -- int Terrorbyte Drone Speed *(35.0)*
    f_24266 = 262145 + 24266, -- int Terrorbyte Request CD *(120000ms)*
    f_24282 = 262145 + 24282, -- int Submarine Request CD *(120000ms)*
    f_26794 = 262145 + 26794, -- int Casino Work Request CD *(180000ms)*
    f_30357 = 262145 + 30357, -- int Autoshop Robbery CD *(3600s)*
    f_31038 = 262145 + 31038, -- int Security Missions CD *(600000ms)*
    f_31118 = 262145 + 31118, -- int Payphone Hits CD *(600000ms)*
    f_31119 = 262145 + 31118, -- int Agency SUV Request CD *(120000ms)*
    f_31882 = 262145 + 31882, -- int NC VIP Mission Spawn Chance% *(50)*
    f_31914 = 262145 + 31914, -- int NC Source Truck CD *(960000ms)*
    f_32158 = 262145 + 32158, -- int Halloween Weather
}

-- boolean
ceo_sell_mission_types_T = {
    f_15624 = 262145 + 15624, -- bool CEO Disable Air Attacked Sell Mission *(false)*
    f_15636 = 262145 + 15636, -- bool CEO Disable Air Drop Sell Mission *(false)*
    f_15642 = 262145 + 15642, -- bool CEO Disable Fly Low Sell Mission *(false)*
    f_15643 = 262145 + 15643, -- bool CEO Disable Restricted Airspace Sell Mission *(false)*
    f_15649 = 262145 + 15649, -- bool CEO Disable Attacked Sell Mission *(false)*
    f_15651 = 262145 + 15651, -- bool CEO Disable Defend Sell Mission *(false)*
    f_15679 = 262145 + 15679, -- bool CEO Disable No-Damage Sell Mission *(false)*
    f_15680 = 262145 + 15680, -- bool CEO Disable Sea Attacked Sell Mission *(false)*
    f_15686 = 262145 + 15686, -- bool CEO Disable Sea Defend Sell Mission *(false)*
    f_15692 = 262145 + 15692, -- bool CEO Disable Sting Operation Sell Mission *(false)*
    f_15698 = 262145 + 15698, -- bool CEO Disable Trackify Sell Mission *(false)*
}

-- boolean
mc_sell_mission_types_T  = {
    f_18356 = 262145 + 18356, -- bool MC Disable Convoy Sell Mission *(false)*
    -- f_18358 = 262145 + 18358, -- bool MC Disable Trashmaster Sell Mission *(false)*
    f_18361 = 262145 + 18361, -- bool MC Disable Proven Sell Mission *(false)*
    f_18363 = 262145 + 18363, -- bool MC Disable Friends In Need Sell Mission *(false)*
    f_18366 = 262145 + 18366, -- bool MC Disable Border Patrol Sell Mission *(false)*
    f_18388 = 262145 + 18388, -- bool MC Disable Heli Drop Sell Mission *(false)*
    f_18391 = 262145 + 18391, -- bool MC Disable Post OP Sell Mission *(false)*
    f_18393 = 262145 + 18393, -- bool MC Disable Air Drop Sell Mission *(false)*
    f_18398 = 262145 + 18398, -- bool MC Disable Sting Operation Sell Mission *(false)*
    -- f_18400 = 262145 + 18400, -- bool MC Disable Benson Sell Mission *(false)*
    f_18408 = 262145 + 18408, -- bool MC Disable Race Sell Mission *(false)*
}

-- float
nc_sell_mission_types_T  = {
    f_24048 = 262145 + 24048, -- float Nightclub Sell Mission Multi Drop *(1.0)*
    f_24049 = 262145 + 24049, -- float Nightclub Sell Mission Hack Drop *(1.0)*
    f_24050 = 262145 + 24050, -- float Nightclub Sell Mission Roadblock *(1.0)*
    f_24051 = 262145 + 24051, -- float Nightclub Sell Mission Protect Buyer *(1.0)*
    f_24052 = 262145 + 24052, -- float Nightclub Sell Mission Undercover Cops *(1.0)*
    f_24053 = 262145 + 24053, -- float Nightclub Sell Mission Offshore Transfer *(1.0)*
    f_24054 = 262145 + 24054, -- float Nightclub Sell Mission Not a Scratch *(1.0)*
    f_24055 = 262145 + 24055, -- float Nightclub Sell Mission Follow Heli *(1.0)*
    f_24056 = 262145 + 24056, -- float Nightclub Sell Mission Find Buyer *(1.0)*
}

-- float
hg_sell_mission_types_T  = {
    f_22472 = 262145 + 22472, -- float Hangar Heavy Lifting Sell Mission *(1.0)*
    f_22509 = 262145 + 22509, -- float Hangar Contested Sell Mission *(1.0)*
    -- f_22511 = 262145 + 22511, -- float Hangar Agile Delivery Sell Mission *(1.0)*
    -- f_22513 = 262145 + 22513, -- float Hangar Precision Delivery Sell Mission *(1.0)*
    f_22515 = 262145 + 22515, -- float Hangar Flying Fortress Sell Mission *(1.0)*
    -- f_22517 = 262145 + 22517, -- float Hangar Fly Low Sell Mission *(1.0)*
    f_22519 = 262145 + 22519, -- float Hangar Air Delivery Sell Mission *(1.0)*
    f_22521 = 262145 + 22521, -- float Hangar Air Police Sell Mission *(1.0)*
    f_22523 = 262145 + 22523, -- float Hangar Under The Radar Sell Mission *(1.0)*
}

world_seats_T            = {
    "prop_bench_01a",
    "prop_table_01_chr_b",
    "prop_bench_05",
    "prop_rub_couch02",
    "prop_hobo_seat_01",
    "prop_skid_chair_02",
    "prop_bench_02",
    "prop_bench_09",
    "prop_waiting_seat_01",
    "prop_table_06_chr",
    "prop_bench_10",
    "prop_chair_04b",
    "prop_rub_couch03",
    "prop_table_03_chr",
    "prop_bench_03",
    "prop_table_01_chr_a",
    "prop_table_02_chr",
    "prop_chair_01b",
    "prop_bench_11",
    "prop_rub_couch01",
    "prop_chair_01a",
    "prop_chair_06",
    "prop_table_03b_chr",
    "prop_old_deck_chair",
    "prop_rub_couch04",
    "prop_skid_chair_01",
    "prop_table_05_chr",
    "prop_chair_03",
    "prop_bench_08",
    "v_club_officechair",
    "v_corp_cd_chair",
    "prop_off_chair_03",
    "prop_skid_chair_03",
    "prop_chair_02",
    "prop_chair_05",
    "prop_chateau_chair_01",
    "prop_bench_06",
    "prop_bench_07",
    "prop_wait_bench_01",
    "prop_off_chair_04",
    "v_serv_ct_chair02",
    "prop_table_04_chr",
    "v_corp_offchair",
    "prop_off_chair_05",
    "prop_roller_car_01",
    "prop_roller_car_02",
    "prop_yacht_seat_01",
    "prop_yacht_seat_02",
    "prop_yacht_seat_03",
    "prop_chair_08",
    "prop_chair_10",
    "prop_ld_bench01",
    "prop_chair_04a",
    "prop_off_chair_01",
    "prop_bench_04",
    "prop_chair_09",
    "prop_rock_chair_01",
    "hei_prop_yah_seat_02",
    "hei_prop_yah_seat_03",
    "hei_prop_yah_seat_01",
    "h4_prop_h4_chair_01a",
    "h4_prop_h4_couch_01a",
    "h4_prop_h4_weed_chair_01a",
    "prop_fib_3b_bench",
    "v_ilev_ph_bench",
    "v_ilev_leath_chr",
    "v_corp_bk_chair3",
    "prop_gc_chair02",
    "v_ilev_fh_dineeamesa",
    "v_ilev_hd_chair",
    "v_ilev_m_sofa",
    "v_ilev_chair02_ped",
    "v_ilev_p_easychair",
    "v_ilev_fh_kitchenstool",
    "prop_off_chair_04_s",
    "prop_ld_farm_couch01",
    "prop_ld_farm_couch02",
    "prop_ld_farm_chair01",
    "v_ret_gc_chair03",
    "prop_old_wood_chair",
    "prop_off_chair_04b",
    "ch_prop_casino_chair_01a",
    "ch_chint01_gamingr1_sofa",
    "ch_prop_casino_track_chair_01",
    "ch_chint03_sofas",
    "ch_chint07_foyer_sofa_01",
    "ch_chint07_foyer_sofa_03",
    "ch_chint07_foyer_sofa_004",
    "h4_mp_h_yacht_armchair_01",
    "h4_mp_h_yacht_armchair_03",
    "h4_mp_h_yacht_armchair_04",
    "h4_mp_h_yacht_sofa_02",
    "h4_mp_h_yacht_sofa_01",
    "h4_mp_h_yacht_strip_chair_01",
    "h4_int_05_wooden_chairs_2",
    "h4_int_05_wood_chair_2",
    "h4_int_05_wooden_chairs_3",
    "h4_int_05_wood_chair_003",
    "h4_int_05_wood_chair_1",
    "h4_int_04_armchair_fireplace",
    "h4_int_04_arm_chair",
    "h4_int_04_chair_chesterfield_01a",
    "h4_int_04_desk_chair"
}

trash_bins_T             = {
    "m23_2_prop_m32_dumpster_01a",
    "prop_cs_dumpster_01a",
    "prop_dumpster_01a",
    "prop_dumpster_02a",
    "prop_dumpster_02b",
    "prop_dumpster_3a",
    "prop_dumpster_4a",
    "prop_dumpster_4b",
    "p_dumpster_t",
}

app_script_names_T       = {
    "apparcadebusiness",
    "apparcadebusinesshub",
    "appavengeroperations",
    "appbailoffice",
    "appbikerbusiness",
    "appbroadcast",
    "appbunkerbusiness",
    "appbusinesshub",
    "appcamera",
    "appchecklist",
    "appcontacts",
    "appcovertops",
    "appemail",
    "appextraction",
    "appfixersecurity",
    "apphackertruck",
    "apphackerden",
    "apphs_sleep",
    "appimportexport",
    "appinternet",
    "appjipmp",
    "appmedia",
    "appmpbossagency",
    "appmpemail",
    "appmpjoblistnew",
    "apporganiser",
    "appprogresshub",
    "apprepeatplay",
    "appsecurohack",
    "appsecuroserv",
    "appsettings",
    "appsidetask",
    "appsmuggler",
    "apptextmessage",
    "apptrackify",
    "appvinewoodmenu",
    "appvlsi",
    "appzit",
    -- "debug_app_select_screen",
}

modshop_script_names     = {
    "arena_carmod",
    "armory_aircraft_carmod",
    "base_carmod",
    "business_hub_carmod",
    "car_meet_carmod",
    "carmod_shop",
    "fixer_hq_carmod",
    "hacker_truck_carmod",
    "hangar_carmod",
    "juggalo_hideout_carmod",
    "personal_carmod_shop",
    "tuner_property_carmod",
    -- "vinewood_premium_garage_carmod",
}

paints_sortByColors      = {
    "All",
    "Beige",
    "Black",
    "Blue",
    "Brown",
    "Gold",
    "Green",
    "Grey",
    "Orange",
    "Pink",
    "Purple",
    "Red",
    "White",
    "Yellow",
}

paints_sortByMfrs        = {
    "All",
    "Alfa Romeo",
    "AMC",
    "Apollo Automobili",
    "Aston Martin",
    "Audi",
    "Austin/Morris",
    "Bentley",
    "BMW",
    "Bugatti",
    "Chevrolet",
    "Dodge",
    "Ferrari",
    "Ford",
    "Honda",
    "Jaguar",
    "Koeniggsegg",
    "Lamborghini",
    "Land Rover",
    "Lexus",
    "Lotus",
    "Mazda",
    "McLaren",
    "Mercedes-AMG",
    "Mercedes-Benz",
    "Nissan",
    "Pagani",
    "Plymouth",
    "Porsche",
    "Rimac Automobili",
    "Rolls-Royce",
    "Spyker",
    "Top Secret Jpn",
    "Toyota",
    "Volkswagen",
}

custom_paints_T          = {
    { name = "AMG Matte Grey",                           hex = "#171717", p = 7,   m = true,  manufacturer = "Mercedes-AMG",      shade = "Grey" },
    { name = "AMG Matte Light Grey",                     hex = "#2B2B2B", p = 8,   m = true,  manufacturer = "Mercedes-AMG",      shade = "Grey" },
    { name = "Green Hell Magno",                         hex = "#00661F", p = 5,   m = true,  manufacturer = "Mercedes-AMG",      shade = "Green" },
    { name = "Yosemite Blue Magno",                      hex = "#142942", p = 63,  m = true,  manufacturer = "Mercedes-AMG",      shade = "Blue" },
    { name = "Solarbeam Yellow I",                       hex = "#AF6605", p = 0,   m = true,  manufacturer = "Mercedes-AMG",      shade = "Yellow" },
    { name = "Solarbeam Yellow II",                      hex = "#7C5C18", p = 37,  m = false, manufacturer = "Mercedes-AMG",      shade = "Yellow" },
    { name = "Solarbeam Yellow III",                     hex = "#BE7813", p = 0,   m = false, manufacturer = "Mercedes-AMG",      shade = "Yellow" },
    { name = "Purple Dragon",                            hex = "#0B020E", p = 11,  m = false, manufacturer = "Apollo Automobili", shade = "Purple" },
    { name = "Golden Dragon",                            hex = "#4A3000", p = 36,  m = false, manufacturer = "Apollo Automobili", shade = "Gold" },
    { name = "Portimao Blue",                            hex = "#000738", p = 64,  m = false, manufacturer = "BMW",               shade = "Blue" },
    { name = "Pure Black",                               hex = "#000000", p = 0,   m = false, manufacturer = "None",              shade = "Black" },
    { name = "TOP SECRET Japan",                         hex = "#5A4B3C", p = 107, m = false, manufacturer = "Top Secret Jpn",    shade = "Gold" },
    { name = "TOP SECRET Japan Alt Gold (GTR R32 650R)", hex = "#8B5C2B", p = 37,  m = false, manufacturer = "Top Secret Jpn",    shade = "Gold" },
    { name = "TOP SECRET Japan Bright Gold (Supra MK4)", hex = "#724C25", p = 97,  m = false, manufacturer = "Top Secret Jpn",    shade = "Gold" },
    { name = "TOP SECRET Japan Light Gold",              hex = "#524A26", p = 90,  m = false, manufacturer = "Top Secret Jpn",    shade = "Gold" },
    { name = "Vantablack",                               hex = "#000100", p = 0,   m = false, manufacturer = "None",              shade = "Black" },
    { name = "Carbon Black",                             hex = "#100F12", p = 7,   m = true,  manufacturer = "None",              shade = "Black" },
    { name = "Pure White",                               hex = "#FFFFFF", p = 112, m = false, manufacturer = "None",              shade = "White" },
    { name = "Off-White",                                hex = "#999999", p = 0,   m = false, manufacturer = "None",              shade = "White" },
    { name = "Hermès White",                             hex = "#BAB6A0", p = 0,   m = false, manufacturer = "None",              shade = "White" },
    { name = "Straw Beige",                              hex = "#615F55", p = 0,   m = false, manufacturer = "None",              shade = "Beige" },
    { name = "Honey Beige",                              hex = "#8C7C68", p = 0,   m = false, manufacturer = "None",              shade = "Beige" },
    { name = "Saw Dust Beige",                           hex = "#FFA057", p = 105, m = false, manufacturer = "None",              shade = "Beige" },
    { name = "Tenzo Milenio Grey",                       hex = "#1B1D26", p = 8,   m = false, manufacturer = "Lamborghini",       shade = "Grey" },
    { name = "Purple Grey",                              hex = "#121015", p = 8,   m = false, manufacturer = "None",              shade = "Grey" },
    { name = "Austin Yellow I",                          hex = "#745613", p = 105, m = false, manufacturer = "BMW",               shade = "Yellow" },
    { name = "Austin Yellow II",                         hex = "#584E1D", p = 91,  m = false, manufacturer = "BMW",               shade = "Yellow" },
    { name = "Sao Paulo Yellow",                         hex = "#D0D53D", p = 91,  m = false, manufacturer = "BMW",               shade = "Yellow" },
    { name = "Better Race Yellow",                       hex = "#FFD700", p = 0,   m = false, manufacturer = "None",              shade = "Yellow" },
    { name = "Bay Leaf Green",                           hex = "#7BA790", p = 0,   m = false, manufacturer = "None",              shade = "Green" },
    { name = "British Racing Green",                     hex = "#000F0E", p = 50,  m = false, manufacturer = "Jaguar",            shade = "Green" },
    { name = "Verde Gea Lucido",                         hex = "#353517", p = 97,  m = false, manufacturer = "Lamborghini",       shade = "Green" },
    { name = "Spring Leaves (Initial-D Iketani's S13)",  hex = "#57876B", p = 4,   m = false, manufacturer = "None",              shade = "Green" },
    { name = "Trippy Green",                             hex = "#00FF7F", p = 92,  m = false, manufacturer = "None",              shade = "Green" },
    { name = "Pfister Green",                            hex = "#54AB3C", p = 90,  m = false, manufacturer = "None",              shade = "Green" },
    { name = "Verde Francesca I",                        hex = "#315447", p = 9,   m = false, manufacturer = "Ferrari",           shade = "Green" },
    { name = "Verde Francesca II",                       hex = "#23403F", p = 3,   m = false, manufacturer = "Ferrari",           shade = "Green" },
    { name = "Willow Green",                             hex = "#607E65", p = 0,   m = false, manufacturer = "Jaguar",            shade = "Green" },
    { name = "Chameleon",                                hex = "#0D020D", p = 54,  m = false, manufacturer = "None",              shade = "Purple" },
    { name = "Cyan",                                     hex = "#00FFFF", p = 73,  m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Crème de Menthe",                          hex = "#547270", p = 112, m = false, manufacturer = "Bugatti",           shade = "Green" },
    { name = "Champagne",                                hex = "#4E443C", p = 107, m = false, manufacturer = "Bugatti",           shade = "Beige" },
    { name = "Exposed Blue Carbon",                      hex = "#030811", p = 0,   m = false, manufacturer = "Bugatti",           shade = "Blue" },
    { name = "Exposed Red Carbon",                       hex = "#250D12", p = 34,  m = false, manufacturer = "Bugatti",           shade = "Red" },
    { name = "Ladybug",                                  hex = "#35000C", p = 29,  m = false, manufacturer = "Bugatti",           shade = "Red" },
    { name = "Petrol Blue",                              hex = "#203E5D", p = 6,   m = false, manufacturer = "Bugatti",           shade = "Blue" },
    { name = "Quartz",                                   hex = "#909EC0", p = 67,  m = false, manufacturer = "Bugatti",           shade = "Grey" },
    { name = "Steel Blue",                               hex = "#101527", p = 5,   m = false, manufacturer = "Bugatti",           shade = "Blue" },
    { name = "Quartz White",                             hex = "#909EC0", p = 0,   m = false, manufacturer = "Bugatti",           shade = "Grey" },
    { name = "French Racing Blue",                       hex = "#003792", p = 11,  m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Police Blue",                              hex = "#2A77A1", p = 0,   m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Bright Blue",                              hex = "#223BA1", p = 0,   m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Deep Sea Blue",                            hex = "#0A1E3E", p = 64,  m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Brighter Midnight Blue",                   hex = "#000128", p = 0,   m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Beautiful Blue",                           hex = "#214FC6", p = 73,  m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Aqua Pearl Blue",                          hex = "#05C1FF", p = 64,  m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Maxi Pad Blue",                            hex = "#36589A", p = 112, m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Bikini Pearl Blue",                        hex = "#002533", p = 68,  m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Lavender Blue I",                          hex = "#5A70F0", p = 67,  m = false, manufacturer = "Jaguar",            shade = "Blue" },
    { name = "Lavender Blue II",                         hex = "#485D78", p = 67,  m = false, manufacturer = "None",              shade = "Blue" },
    { name = "Crayon",                                   hex = "#9693A1", p = 10,  m = false, manufacturer = "None",              shade = "Beige" },
    { name = "Light Orange",                             hex = "#C45C33", p = 0,   m = false, manufacturer = "None",              shade = "Orange" },
    { name = "Seawash",                                  hex = "#455C56", p = 0,   m = false, manufacturer = "None",              shade = "Green" },
    { name = "Hot Pink",                                 hex = "#FF05BE", p = 0,   m = false, manufacturer = "None",              shade = "Pink" },
    { name = "Cassis Pink",                              hex = "#31222A", p = 136, m = false, manufacturer = "None",              shade = "Pink" },
    { name = "Kisama Pink",                              hex = "#990F36", p = 0,   m = false, manufacturer = "None",              shade = "Pink" },
    { name = "Viola Beast Pink",                         hex = "#2E000B", p = 137, m = false, manufacturer = "None",              shade = "Pink" },
    { name = "Bright Wine Red",                          hex = "#280000", p = 27,  m = false, manufacturer = "None",              shade = "Red" },
    { name = "Coca Cola Red",                            hex = "#A5121C", p = 0,   m = false, manufacturer = "None",              shade = "Red" },
    { name = "Chromeo Red",                              hex = "#350000", p = 35,  m = false, manufacturer = "None",              shade = "Red" },
    { name = "Rosso Siviglia",                           hex = "#57000C", p = 27,  m = false, manufacturer = "Ferrari",           shade = "Red" },
    { name = "Rosso Corsa",                              hex = "#D40000", p = 28,  m = false, manufacturer = "Ferrari",           shade = "Red" },
    { name = "Millennium Jade",                          hex = "#3B3F31", p = 102, m = false, manufacturer = "Nissan",            shade = "Green" },
    { name = "Copper Gold",                              hex = "#5A4441", p = 136, m = false, manufacturer = "None",              shade = "Gold" },
    { name = "Taipei Gold",                              hex = "#49231F", p = 99,  m = false, manufacturer = "Koeniggsegg",       shade = "Gold" },
    { name = "Olympic Gold",                             hex = "#706546", p = 104, m = false, manufacturer = "None",              shade = "Gold" },
    { name = "Sandy Gold",                               hex = "#504942", p = 105, m = false, manufacturer = "None",              shade = "Gold" },
    { name = "Mulberry",                                 hex = "#240719", p = 137, m = false, manufacturer = "None",              shade = "Purple" },
    { name = "Onyx",                                     hex = "#353839", p = 103, m = false, manufacturer = "None",              shade = "Grey" },
    { name = "Amethyst",                                 hex = "#27253C", p = 65,  m = false, manufacturer = "Porsche",           shade = "Grey" },
    { name = "AAden Purple",                             hex = "#0C080C", p = 96,  m = false, manufacturer = "Koeniggsegg",       shade = "Purple" },
    { name = "Zjin Purple",                              hex = "#120119", p = 145, m = false, manufacturer = "Koeniggsegg",       shade = "Purple" },
    { name = "Viola Ophelia",                            hex = "#1A000F", p = 7,   m = false, manufacturer = "Lamborghini",       shade = "Purple" },
    { name = "Nismo Grey",                               hex = "#191919", p = 4,   m = false, manufacturer = "Nissan",            shade = "Grey" },
    { name = "Pagani Brown",                             hex = "#201913", p = 94,  m = false, manufacturer = "Pagani",            shade = "Brown" },
    { name = "Tootsie Roll Brown",                       hex = "#1A1110", p = 1,   m = false, manufacturer = "None",              shade = "Brown" },
    { name = "Sage Green",                               hex = "#1A1F15", p = 99,  m = false, manufacturer = "McLaren",           shade = "Green" },
    { name = "K-Purple",                                 hex = "#13062C", p = 63,  m = false, manufacturer = "McLaren",           shade = "Purple" },
    { name = "Pascha Red",                               hex = "#1A0102", p = 0,   m = false, manufacturer = "Porsche",           shade = "Red" },
    { name = "Silver Tempest",                           hex = "#191C1E", p = 7,   m = false, manufacturer = "Bentley",           shade = "Grey" },
    { name = "Raven Black",                              hex = "#0C0C0C", p = 0,   m = false, manufacturer = "Ford",              shade = "Black" },
    { name = "Oak Green I",                              hex = "#0F1916", p = 52,  m = false, manufacturer = "Porsche",           shade = "Green" },
    { name = "Oak Green II",                             hex = "#1D291C", p = 100, m = false, manufacturer = "Porsche",           shade = "Green" },
    { name = "Caribbean Blue",                           hex = "#1F375B", p = 87,  m = false, manufacturer = "Rolls-Royce",       shade = "Blue" },
    { name = "Caribbean Aqua",                           hex = "#163D5B", p = 0,   m = false, manufacturer = "Rolls-Royce",       shade = "Blue" },
    { name = "Caribbean Pearl",                          hex = "#164165", p = 67,  m = false, manufacturer = "Aston Martin",      shade = "Blue" },
    { name = "Hyazinth Red",                             hex = "#580101", p = 0,   m = false, manufacturer = "Mercedes-AMG",      shade = "Red" },
    { name = "Vogue Silver",                             hex = "#646E7A", p = 4,   m = false, manufacturer = "Honda",             shade = "Grey" },
    { name = "Laranja Bittersweet",                      hex = "#AC2612", p = 0,   m = false, manufacturer = "Volkswagen",        shade = "Orange" },
    { name = "Faggio",                                   hex = "#15060A", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Brown" },
    { name = "Vintage Cream",                            hex = "#A19072", p = 0,   m = false, manufacturer = "Dodge",             shade = "Beige" },
    { name = "Baby Blue",                                hex = "#3961B2", p = 3,   m = false, manufacturer = "BMW",               shade = "Blue" },
    { name = "Atlantis Blue I",                          hex = "#002845", p = 54,  m = false, manufacturer = "BMW",               shade = "Blue" },
    { name = "Atlantis Blue II",                         hex = "#02334E", p = 54,  m = false, manufacturer = "BMW",               shade = "Blue" },
    { name = "Alpina Purple",                            hex = "#0E0A19", p = 72,  m = false, manufacturer = "BMW",               shade = "Purple" },
    { name = "Fire Orange",                              hex = "#8A2B03", p = 1,   m = false, manufacturer = "BMW",               shade = "Orange" },
    { name = "Fire Red",                                 hex = "#A70A00", p = 0,   m = false, manufacturer = "BMW",               shade = "Red" },
    { name = "Hockenheim Silver",                        hex = "#7885A2", p = 7,   m = false, manufacturer = "BMW",               shade = "Grey" },
    { name = "Messing",                                  hex = "#1F2018", p = 97,  m = false, manufacturer = "BMW",               shade = "Green" },
    { name = "Java Green I",                             hex = "#16591A", p = 103, m = false, manufacturer = "BMW",               shade = "Green" },
    { name = "Java Green II",                            hex = "#1A5525", p = 94,  m = true,  manufacturer = "BMW",               shade = "Green" },
    { name = "Phoenix Yellow",                           hex = "#7C6D0C", p = 93,  m = false, manufacturer = "BMW",               shade = "Yellow" },
    { name = "Long Beach Blue",                          hex = "#012349", p = 54,  m = false, manufacturer = "BMW",               shade = "Blue" },
    { name = "Marina Blue",                              hex = "#051151", p = 64,  m = false, manufacturer = "BMW",               shade = "Blue" },
    { name = "Purple Silk I",                            hex = "#1F0F25", p = 145, m = false, manufacturer = "BMW",               shade = "Purple" },
    { name = "Long Beach Red",                           hex = "#2D060B", p = 32,  m = false, manufacturer = "Chevrolet",         shade = "Red" },
    { name = "Purple Silk II",                           hex = "#3D2A3D", p = 4,   m = false, manufacturer = "Rolls-Royce",       shade = "Purple" },
    { name = "Alluminio Opaco",                          hex = "#6A7679", p = 0,   m = true,  manufacturer = "Ferrari",           shade = "White" },
    { name = "Avorio",                                   hex = "#989180", p = 0,   m = false, manufacturer = "Ferrari",           shade = "White" },
    { name = "Argento Nurburgring",                      hex = "#4D576A", p = 4,   m = false, manufacturer = "Ferrari",           shade = "Grey" },
    { name = "Azzurro California I",                     hex = "#274059", p = 87,  m = false, manufacturer = "Ferrari",           shade = "Blue" },
    { name = "Azzurro California II",                    hex = "#36506B", p = 69,  m = false, manufacturer = "Ferrari",           shade = "Blue" },
    { name = "Azzurro Dino",                             hex = "#082BA2", p = 64,  m = false, manufacturer = "Ferrari",           shade = "Blue" },
    { name = "Azzurro Monaco",                           hex = "#0F1433", p = 62,  m = false, manufacturer = "Ferrari",           shade = "Blue" },
    { name = "Azzurro Vela",                             hex = "#000D32", p = 87,  m = false, manufacturer = "Ferrari",           shade = "Blue" },
    { name = "BP Green",                                 hex = "#013527", p = 0,   m = false, manufacturer = "Ferrari",           shade = "Green" },
    { name = "Bianco Avus I",                            hex = "#ACB0B2", p = 0,   m = false, manufacturer = "Ferrari",           shade = "White" },
    { name = "Bianco Avus II",                           hex = "#DFF5FF", p = 112, m = false, manufacturer = "Ferrari",           shade = "White" },
    { name = "Bianco Fuji",                              hex = "#B8BABB", p = 0,   m = false, manufacturer = "Ferrari",           shade = "White" },
    { name = "Bianco Italia I",                          hex = "#C3BCB9", p = 11,  m = false, manufacturer = "Ferrari",           shade = "White" },
    { name = "Bianco Italia II",                         hex = "#ABAEB0", p = 0,   m = false, manufacturer = "Ferrari",           shade = "White" },
    { name = "Blu Abu Dhabi",                            hex = "#0B1B27", p = 63,  m = false, manufacturer = "Ferrari",           shade = "Blue" },
    { name = "Blu Corsa",                                hex = "#132BB1", p = 73,  m = false, manufacturer = "Ferrari",           shade = "Blue" },
    { name = "Portofino Blue",                           hex = "#000711", p = 64,  m = false, manufacturer = "Land Rover",        shade = "Blue" },
    { name = "Vegas Yellow I",                           hex = "#916E1D", p = 11,  m = false, manufacturer = "Audi",              shade = "Yellow" },
    { name = "Vegas Yellow II",                          hex = "#8C5F15", p = 0,   m = false, manufacturer = "Audi",              shade = "Yellow" },
    { name = "Honey Gold",                               hex = "#6B4821", p = 0,   m = false, manufacturer = "Rolls-Royce",       shade = "Gold" },
    { name = "Montana Green",                            hex = "#004550", p = 69,  m = false, manufacturer = "Volkswagen",        shade = "Green" },
    { name = "LH Purple",                                hex = "#1C0921", p = 52,  m = false, manufacturer = "Pagani",            shade = "Purple" },
    { name = "Jade Green",                               hex = "#1B504C", p = 0,   m = false, manufacturer = "Porsche",           shade = "Green" },
    { name = "Imperial Maroon",                          hex = "#4F0F13", p = 0,   m = false, manufacturer = "Jaguar",            shade = "Brown" },
    { name = "Mexico Blue",                              hex = "#003EB3", p = 0,   m = false, manufacturer = "Porsche",           shade = "Blue" },
    { name = "Ipanema Brown",                            hex = "#452505", p = 36,  m = false, manufacturer = "Audi",              shade = "Brown" },
    { name = "Shadow Grey",                              hex = "#181E27", p = 7,   m = false, manufacturer = "Chevrolet",         shade = "Grey" },
    { name = "Rosso 70 Anni",                            hex = "#60020C", p = 29,  m = false, manufacturer = "Ferrari",           shade = "Red" },
    { name = "Verde Faunus",                             hex = "#78AA14", p = 4,   m = false, manufacturer = "Lamborghini",       shade = "Green" },
    { name = "Giallo Medio",                             hex = "#43494f", p = 5,   m = false, manufacturer = "Alfa Romeo",        shade = "Yellow" },
    { name = "Silver Sand",                              hex = "#7C766D", p = 0,   m = false, manufacturer = "Rolls-Royce",       shade = "Grey" },
    { name = "Dark Highland Green",                      hex = "#0A1013", p = 54,  m = false, manufacturer = "Ford",              shade = "Green" },
    { name = "Cascade Green '60",                        hex = "#415349", p = 6,   m = false, manufacturer = "Chevrolet",         shade = "Green" },
    { name = "Magma Orange",                             hex = "#F12702", p = 0,   m = false, manufacturer = "Mercedes-AMG",      shade = "Orange" },
    { name = "Rosso Magma",                              hex = "#410409", p = 35,  m = false, manufacturer = "Ferrari",           shade = "Red" },
    { name = "Grabber Blue I",                           hex = "#033663", p = 0,   m = false, manufacturer = "Ford",              shade = "Blue" },
    { name = "Grabber Blue II",                          hex = "#024D8E", p = 0,   m = false, manufacturer = "Ford",              shade = "Blue" },
    { name = "Verde Pampa",                              hex = "#64642A", p = 0,   m = false, manufacturer = "Volkswagen",        shade = "Green" },
    { name = "Midori Green I",                           hex = "#32564F", p = 8,   m = false, manufacturer = "Honda",             shade = "Green" },
    { name = "Midori Green II",                          hex = "#23907D", p = 5,   m = false, manufacturer = "Honda",             shade = "Green" },
    { name = "Midori Green III",                         hex = "#1B4657", p = 5,   m = false, manufacturer = "Honda",             shade = "Green" },
    { name = "Ascot Fawn",                               hex = "#7A736E", p = 0,   m = false, manufacturer = "Jaguar",            shade = "Beige" },
    { name = "Tarocco Orange",                           hex = "#F13C08", p = 37,  m = false, manufacturer = "McLaren",           shade = "Orange" },
    { name = "Mira Orange",                              hex = "#D01A04", p = 0,   m = false, manufacturer = "McLaren",           shade = "Orange" },
    { name = "Papaya Orange",                            hex = "#E56717", p = 0,   m = false, manufacturer = "McLaren",           shade = "Orange" },
    { name = "Volcano Orange",                           hex = "#410C00", p = 36,  m = false, manufacturer = "McLaren",           shade = "Orange" },
    { name = "Volcano Yellow",                           hex = "#D08104", p = 0,   m = false, manufacturer = "McLaren",           shade = "Yellow" },
    { name = "Army Green Wrap",                          hex = "#2A3408", p = 52,  m = true,  manufacturer = "McLaren",           shade = "Green" },
    { name = "LH Blue",                                  hex = "#001854", p = 73,  m = false, manufacturer = "McLaren",           shade = "Blue" },
    { name = "Cerulean Blue",                            hex = "#022458", p = 63,  m = false, manufacturer = "McLaren",           shade = "Blue" },
    { name = "Speedtail Hermès Edition",                 hex = "#080914", p = 73,  m = false, manufacturer = "McLaren",           shade = "Blue" },
    { name = "XPGreen",                                  hex = "#00090F", p = 54,  m = false, manufacturer = "McLaren",           shade = "Green" },
    { name = "Curacao Blue",                             hex = "#226DB8", p = 5,   m = false, manufacturer = "McLaren",           shade = "Blue" },
    { name = "Blu Genziana",                             hex = "#22334C", p = 7,   m = false, manufacturer = "McLaren",           shade = "Blue" },
    { name = "Diamond Alaskan White",                    hex = "#8389A5", p = 7,   m = false, manufacturer = "McLaren",           shade = "White" },
    { name = "Gloss Army Green",                         hex = "#424316", p = 37,  m = false, manufacturer = "McLaren",           shade = "Green" },
    { name = "Pacific Blue",                             hex = "#000D14", p = 67,  m = false, manufacturer = "McLaren",           shade = "Blue" },
    { name = "Azzurro Sardegna",                         hex = "#385170", p = 3,   m = false, manufacturer = "Pagani",            shade = "Blue" },
    { name = "Dino Dream Brown I",                       hex = "#594628", p = 106, m = false, manufacturer = "Pagani",            shade = "Brown" },
    { name = "Dino Dream Brown II",                      hex = "#4F2E11", p = 8,   m = false, manufacturer = "Pagani",            shade = "Brown" },
    { name = "Pagani Huayra Hermès Edition",             hex = "#130B0A", p = 97,  m = false, manufacturer = "Pagani",            shade = "Brown" },
    { name = "Apple Tree Green",                         hex = "#2B5540", p = 0,   m = false, manufacturer = "Aston Martin",      shade = "Green" },
    { name = "Viridian Green",                           hex = "#003A3E", p = 7,   m = false, manufacturer = "Aston Martin",      shade = "Green" },
    { name = "Mint Green",                               hex = "#3C5E5F", p = 99,  m = false, manufacturer = "Aston Martin",      shade = "Green" },
    { name = "Lime Essence",                             hex = "#7D9E0F", p = 91,  m = false, manufacturer = "Aston Martin",      shade = "Green" },
    { name = "Teak Brown",                               hex = "#221B18", p = 95,  m = false, manufacturer = "Audi",              shade = "Brown" },
    { name = "Zanzibar Brown",                           hex = "#734B31", p = 106, m = false, manufacturer = "Audi",              shade = "Brown" },
    { name = "Kingfisher Blue",                          hex = "#09366C", p = 54,  m = false, manufacturer = "Bentley",           shade = "Blue" },
    { name = "Julep",                                    hex = "#776C36", p = 107, m = false, manufacturer = "Bentley",           shade = "Gold" },
    { name = "Dove Grey",                                hex = "#636469", p = 107, m = false, manufacturer = "Bentley",           shade = "Grey" },
    { name = "Bahama Yellow",                            hex = "#8C5624", p = 96,  m = false, manufacturer = "Porsche",           shade = "Yellow" },
    { name = "Signal Yellow",                            hex = "#F47900", p = 2,   m = false, manufacturer = "Porsche",           shade = "Yellow" },
    { name = "Signal Green",                             hex = "#057334", p = 0,   m = false, manufacturer = "Porsche",           shade = "Green" },
    { name = "Nitro Yellow",                             hex = "#AB6F1A", p = 88,  m = false, manufacturer = "Toyota",            shade = "Yellow" },
    { name = "Flare Yellow",                             hex = "#955F24", p = 0,   m = false, manufacturer = "Lexus",             shade = "Yellow" },
    { name = "Sunburst Yellow",                          hex = "#B47400", p = 2,   m = false, manufacturer = "Mazda",             shade = "Yellow" },
    { name = "Lime Yellow",                              hex = "#6B7132", p = 100, m = false, manufacturer = "Nissan",            shade = "Yellow" },
    { name = "Greenish Yellow Mica",                     hex = "#383418", p = 37,  m = false, manufacturer = "Toyota",            shade = "Yellow" },
    { name = "Curious Yellow",                           hex = "#8C8610", p = 0,   m = false, manufacturer = "Plymouth",          shade = "Yellow" },
    { name = "Daytona Yellow",                           hex = "#AD9B4B", p = 0,   m = false, manufacturer = "Chevrolet",         shade = "Yellow" },
    { name = "Butternut Yellow",                         hex = "#999C77", p = 0,   m = false, manufacturer = "Chevrolet",         shade = "Yellow" },
    { name = "Primrose Yellow",                          hex = "#B89D52", p = 0,   m = false, manufacturer = "Jaguar",            shade = "Yellow" },
    { name = "Sand Beige",                               hex = "#54473D", p = 95,  m = false, manufacturer = "Audi",              shade = "Beige" },
    { name = "El Paso Beige",                            hex = "#5B584A", p = 0,   m = false, manufacturer = "Austin/Morris",     shade = "Beige" },
    { name = "Grigio Beige",                             hex = "#998E78", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Beige" },
    { name = "Cava Beige",                               hex = "#A09B85", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Beige" },
    { name = "Nevada Beige",                             hex = "#706457", p = 95,  m = false, manufacturer = "Volkswagen",        shade = "Beige" },
    { name = "Lagune Beige",                             hex = "#6D6754", p = 0,   m = false, manufacturer = "Austin/Morris",     shade = "Beige" },
    { name = "Sandpebble Beige",                         hex = "#AFAA8F", p = 0,   m = false, manufacturer = "Dodge",             shade = "Beige" },
    { name = "Sanidin Beige",                            hex = "#5E5F5C", p = 107, m = false, manufacturer = "Mercedes-Benz",     shade = "Beige" },
    { name = "Cheltenham Beige",                         hex = "#B6B5B3", p = 2,   m = false, manufacturer = "Aston Martin",      shade = "Beige" },
    { name = "Passionate Pink",                          hex = "#91114D", p = 11,  m = false, manufacturer = "Lexus",             shade = "Pink" },
    { name = "Panther Pink",                             hex = "#A2235B", p = 0,   m = false, manufacturer = "Dodge",             shade = "Pink" },
    { name = "Viola Purple",                             hex = "#2A223F", p = 71,  m = false, manufacturer = "Porsche",           shade = "Purple" },
    { name = "Satin Paper Purple",                       hex = "#372439", p = 136, m = false, manufacturer = "Chevrolet",         shade = "Purple" },
    { name = "Midnight Purple",                          hex = "#070206", p = 72,  m = false, manufacturer = "Audi",              shade = "Purple" },
    { name = "Purple Silk",                              hex = "#1F0F25", p = 71,  m = false, manufacturer = "BMW",               shade = "Purple" },
    { name = "MSO R Singh Purple",                       hex = "#180438", p = 71,  m = false, manufacturer = "McLaren",           shade = "Purple" },
    { name = "Cyclamen Purple",                          hex = "#28121D", p = 0,   m = false, manufacturer = "Chevrolet",         shade = "Purple" },
    { name = "Goldfinger Yellow",                        hex = "#C3B269", p = 0,   m = false, manufacturer = "Rolls-Royce",       shade = "Yellow" },
    { name = "Matte Rose Gold",                          hex = "#281A1C", p = 31,  m = true,  manufacturer = "Mercedes-AMG",      shade = "Gold" },
    { name = "Cornish Gold",                             hex = "#908D6D", p = 107, m = false, manufacturer = "Aston Martin",      shade = "Gold" },
    { name = "Sauterne Gold",                            hex = "#5F6658", p = 4,   m = false, manufacturer = "Ford",              shade = "Gold" },
    { name = "Jalop Gold",                               hex = "#786702", p = 88,  m = false, manufacturer = "AMC",               shade = "Gold" },
    { name = "Sunset Gold",                              hex = "#262425", p = 99,  m = false, manufacturer = "Land Rover",        shade = "Gold" },
    { name = "Rio Gold",                                 hex = "#666162", p = 4,   m = false, manufacturer = "Land Rover",        shade = "Gold" },
    { name = "Rose Gold I",                              hex = "#B76E6E", p = 66,  m = false, manufacturer = "None",              shade = "Gold" },
    { name = "Rose Gold II",                             hex = "#322121", p = 66,  m = false, manufacturer = "Koeniggsegg",       shade = "Gold" },
    { name = "Metallic Gold",                            hex = "#5C4C36", p = 37,  m = false, manufacturer = "None",              shade = "Gold" },
    { name = "Champagne Gold I",                         hex = "#4B443D", p = 97,  m = false, manufacturer = "Ford",              shade = "Gold" },
    { name = "Champagne Gold II",                        hex = "#644606", p = 37,  m = false, manufacturer = "Lotus",             shade = "Gold" },
    { name = "Lime Gold",                                hex = "#384432", p = 8,   m = false, manufacturer = "Ford",              shade = "Gold" },
    { name = "Black Olive",                              hex = "#030E10", p = 52,  m = false, manufacturer = "Spyker",            shade = "Green" },
    { name = "Magnetite Black",                          hex = "#1C1F27", p = 0,   m = false, manufacturer = "Mercedes-Benz",     shade = "Black" },
    { name = "Black Pearl",                              hex = "#020202", p = 2,   m = false, manufacturer = "Alfa Romeo",        shade = "Black" },
    { name = "Tuxedo Black",                             hex = "#010101", p = 0,   m = false, manufacturer = "Chevrolet",         shade = "Black" },
    { name = "Absolute Zero White",                      hex = "#9AA2BB", p = 5,   m = false, manufacturer = "Toyota",            shade = "White" },
    { name = "Glacier White",                            hex = "#8590A6", p = 4,   m = false, manufacturer = "Audi",              shade = "White" },
    { name = "Galactic White",                           hex = "#555E6E", p = 7,   m = false, manufacturer = "Rimac Automobili",  shade = "White" },
    { name = "White Sand I",                             hex = "#736260", p = 106, m = false, manufacturer = "Bentley",           shade = "Beige" },
    { name = "White Sand II",                            hex = "#4E4948", p = 8,   m = false, manufacturer = "Bentley",           shade = "Grey" },
    { name = "Diamond White I",                          hex = "#BFC1CC", p = 67,  m = false, manufacturer = "Toyota",            shade = "White" },
    { name = "Diamond White II",                         hex = "#959FB7", p = 0,   m = false, manufacturer = "Mercedes-Benz",     shade = "White" },
    { name = "Super White",                              hex = "#B3B6BC", p = 0,   m = false, manufacturer = "Toyota",            shade = "White" },
    { name = "Porcelain White",                          hex = "#BAC4C4", p = 0,   m = false, manufacturer = "Rolls-Royce",       shade = "White" },
    { name = "Acrylic White",                            hex = "#BCC0C4", p = 0,   m = false, manufacturer = "Rolls-Royce",       shade = "White" },
    { name = "Crystal White",                            hex = "#8692AC", p = 9,   m = false, manufacturer = "Nissan",            shade = "White" },
    { name = "Pearl White",                              hex = "#9A9DA0", p = 111, m = false, manufacturer = "Jaguar",            shade = "White" },
    { name = "Wimbeldon White",                          hex = "#C6C5BA", p = 0,   m = false, manufacturer = "Ford",              shade = "White" },
    { name = "White Platinum",                           hex = "#A2ABB5", p = 0,   m = false, manufacturer = "Ford",              shade = "White" },
    { name = "Colonial White",                           hex = "#D8D8D4", p = 0,   m = false, manufacturer = "Ford",              shade = "White" },
    { name = "Snowshoe White",                           hex = "#C6C4BC", p = 0,   m = false, manufacturer = "Ford",              shade = "White" },
    { name = "Lunare White",                             hex = "#C9C8CE", p = 67,  m = false, manufacturer = "Alfa Romeo",        shade = "White" },
    { name = "Old English White",                        hex = "#ADABA2", p = 0,   m = false, manufacturer = "Austin/Morris",     shade = "White" },
    { name = "Venetian Red",                             hex = "#FD1404", p = 0,   m = false, manufacturer = "Chevrolet",         shade = "Red" },
    { name = "Firenze Red",                              hex = "#4B000D", p = 28,  m = false, manufacturer = "Land Rover",        shade = "Red" },
    { name = "Brilliant Red",                            hex = "#BB000A", p = 9,   m = false, manufacturer = "None",              shade = "Red" },
    { name = "Cardinal Red Magno",                       hex = "#45060B", p = 35,  m = false, manufacturer = "Mercedes-AMG",      shade = "Red" },
    { name = "Rubystone Red",                            hex = "#65033A", p = 0,   m = false, manufacturer = "Porsche",           shade = "Red" },
    { name = "Arena Red",                                hex = "#2A0507", p = 2,   m = false, manufacturer = "Porsche",           shade = "Red" },
    { name = "Guards Red I",                             hex = "#850002", p = 30,  m = false, manufacturer = "Porsche",           shade = "Red" },
    { name = "Guards Red II",                            hex = "#BD001A", p = 0,   m = false, manufacturer = "Porsche",           shade = "Red" },
    { name = "Performance Red",                          hex = "#7C0F11", p = 0,   m = false, manufacturer = "Ford",              shade = "Red" },
    { name = "Catalunya Red",                            hex = "#AC0E06", p = 0,   m = false, manufacturer = "Audi",              shade = "Red" },
    { name = "Candy Apple Red",                          hex = "#AD190F", p = 0,   m = false, manufacturer = "Ford",              shade = "Red" },
    { name = "Infrared",                                 hex = "#440608", p = 31,  m = false, manufacturer = "Lexus",             shade = "Red" },
    { name = "Redline",                                  hex = "#83000E", p = 0,   m = false, manufacturer = "Lexus",             shade = "Red" },
    { name = "Vintage Red",                              hex = "#62090B", p = 0,   m = false, manufacturer = "Mazda",             shade = "Red" },
    { name = "Tango Red",                                hex = "#87121B", p = 0,   m = false, manufacturer = "Audi",              shade = "Red" },
    { name = "Stawberry Red",                            hex = "#320315", p = 137, m = false, manufacturer = "None",              shade = "Red" },
    { name = "Renaissance Red",                          hex = "#7A0F11", p = 0,   m = false, manufacturer = "Toyota",            shade = "Red" },
    { name = "Acid Green",                               hex = "#70AB02", p = 92,  m = false, manufacturer = "Porsche",           shade = "Green" },
    { name = "Agate Grey",                               hex = "#25282F", p = 3,   m = false, manufacturer = "Porsche",           shade = "Grey" },
    { name = "Albert Blue",                              hex = "#0C0F27", p = 1,   m = false, manufacturer = "Porsche",           shade = "Blue" },
    { name = "Averturine Green",                         hex = "#1B1E20", p = 100, m = false, manufacturer = "Porsche",           shade = "Green" },
    { name = "Azzurro Tethys",                           hex = "#4C5F81", p = 67,  m = false, manufacturer = "Porsche",           shade = "Blue" },
    { name = "Brewster Green",                           hex = "#041411", p = 0,   m = false, manufacturer = "Porsche",           shade = "Green" },
    { name = "Burgundy Red",                             hex = "#280000", p = 143, m = false, manufacturer = "Porsche",           shade = "Red" },
    { name = "Acqua Di Fonte",                           hex = "#577E87", p = 11,  m = false, manufacturer = "Alfa Romeo",        shade = "Blue" },
    { name = "Antracite Inglese",                        hex = "#171C1E", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Grey" },
    { name = "Avorio",                                   hex = "#85867E", p = 102, m = false, manufacturer = "Alfa Romeo",        shade = "Beige" },
    { name = "Azzurro Spazio",                           hex = "#97C1B1", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Blue" },
    { name = "Blu Chiaro",                               hex = "#050C1C", p = 63,  m = false, manufacturer = "Alfa Romeo",        shade = "Blue" },
    { name = "Blu Francia",                              hex = "#14285B", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Blue" },
    { name = "Celeste",                                  hex = "#82BFDD", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Blue" },
    { name = "Englese Verde",                            hex = "#0C2118", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Green" },
    { name = "Montreal Green",                           hex = "#003230", p = 51,  m = false, manufacturer = "Alfa Romeo",        shade = "Green" },
    { name = "Farina Red",                               hex = "#890A08", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Red" },
    { name = "Giallo Ocra",                              hex = "#7C5208", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Yellow" },
    { name = "Giallo Pompei",                            hex = "#AFA770", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Yellow" },
    { name = "Giallo Prototipo",                         hex = "#ACBC62", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Yellow" },
    { name = "Grigio Chiaro",                            hex = "#576066", p = 5,   m = false, manufacturer = "Alfa Romeo",        shade = "Grey" },
    { name = "LMS Blue I",                               hex = "#1B3766", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Blue" },
    { name = "LMS Blue II",                              hex = "#1A7399", p = 5,   m = false, manufacturer = "Alfa Romeo",        shade = "Blue" },
    { name = "Periwinkle",                               hex = "#3A3144", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Purple" },
    { name = "Prugna",                                   hex = "#4C1220", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Red" },
    { name = "Rosso Alfa",                               hex = "#6D060F", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Red" },
    { name = "Verde Oliva",                              hex = "#374428", p = 5,   m = false, manufacturer = "Alfa Romeo",        shade = "Green" },
    { name = "Verde Pino",                               hex = "#003037", p = 2,   m = false, manufacturer = "Alfa Romeo",        shade = "Green" },
    { name = "Verde Pino II",                            hex = "#003033", p = 0,   m = false, manufacturer = "Alfa Romeo",        shade = "Green" },
    { name = "Apollo Orange",                            hex = "#CA5B1C", p = 95,  m = false, manufacturer = "Apollo Automobili", shade = "Orange" },
    { name = "B5 Blue",                                  hex = "#043362", p = 68,  m = false, manufacturer = "Dodge",             shade = "Blue" },
    { name = "Bright Blue Poly",                         hex = "#124071", p = 0,   m = false, manufacturer = "Dodge",             shade = "Blue" },
    { name = "Bright Green Poly",                        hex = "#0E582E", p = 100, m = false, manufacturer = "Dodge",             shade = "Green" },
    { name = "Dark Green Poly",                          hex = "#1A1F14", p = 100, m = false, manufacturer = "Dodge",             shade = "Green" },
    { name = "Dark Tan Poly",                            hex = "#4B2009", p = 0,   m = false, manufacturer = "Dodge",             shade = "Orange" },
    { name = "Destroyer Grey",                           hex = "#4F5460", p = 0,   m = false, manufacturer = "Dodge",             shade = "Grey" },
    { name = "F8 Green",                                 hex = "#131E16", p = 97,  m = false, manufacturer = "Dodge",             shade = "Green" },
    { name = "Furious Fuchsia",                          hex = "#501733", p = 137, m = false, manufacturer = "Dodge",             shade = "Pink" },
    { name = "Gold Poly",                                hex = "#362A17", p = 37,  m = false, manufacturer = "Dodge",             shade = "Gold" },
    { name = "Hemi Orange",                              hex = "#9C2611", p = 0,   m = false, manufacturer = "Dodge",             shade = "Orange" },
    { name = "Ice Blue",                                 hex = "#223B4A", p = 0,   m = false, manufacturer = "Dodge",             shade = "Blue" },
    { name = "Light Turquoise Poly",                     hex = "#194252", p = 0,   m = false, manufacturer = "Dodge",             shade = "Blue" },
    { name = "Limelight",                                hex = "#478825", p = 95,  m = false, manufacturer = "Dodge",             shade = "Green" },
    { name = "Reverence Strangler Green",                hex = "#1E4F0C", p = 91,  m = false, manufacturer = "Dodge",             shade = "Green" },
    { name = "Spring Green",                             hex = "#0E4F20", p = 52,  m = false, manufacturer = "Dodge",             shade = "Green" },
    { name = "Sublime Green I",                          hex = "#629100", p = 92,  m = false, manufacturer = "Dodge",             shade = "Green" },
    { name = "Sublime Green II",                         hex = "#69933B", p = 0,   m = false, manufacturer = "Dodge",             shade = "Green" },
    { name = "Sunburst Orange",                          hex = "#400409", p = 36,  m = false, manufacturer = "Dodge",             shade = "Orange" },
    { name = "Violet",                                   hex = "#170F2C", p = 0,   m = false, manufacturer = "Dodge",             shade = "Purple" },
    { name = "Plum Crazy Purple",                        hex = "#1D0D48", p = 1,   m = false, manufacturer = "Dodge",             shade = "Purple" },
    { name = "Winchester Gray",                          hex = "#2E3945", p = 5,   m = false, manufacturer = "Dodge",             shade = "Grey" },
    { name = "Blue Chrome Wrap",                         hex = "#002A72", p = 73,  m = false, manufacturer = "Honda",             shade = "Blue" },
    { name = "Laguna Blue",                              hex = "#001443", p = 11,  m = false, manufacturer = "Honda",             shade = "Blue" },
    { name = "Nord Gray",                                hex = "#212B29", p = 0,   m = false, manufacturer = "Honda",             shade = "Grey" },
    { name = "Sebring Silver",                           hex = "#31353D", p = 4,   m = false, manufacturer = "Honda",             shade = "Grey" },
    { name = "Sonic Grey I",                             hex = "#55637E", p = 0,   m = false, manufacturer = "Honda",             shade = "Grey" },
    { name = "Sonic Grey II",                            hex = "#516EA5", p = 62,  m = false, manufacturer = "Honda",             shade = "Grey" },
    { name = "Suzuka Blue",                              hex = "#28417C", p = 72,  m = false, manufacturer = "Honda",             shade = "Blue" },
    { name = "Valencia Red",                             hex = "#2D0309", p = 30,  m = false, manufacturer = "Honda",             shade = "Red" },
    { name = "Azure Blue",                               hex = "#152F7C", p = 0,   m = false, manufacturer = "Jaguar",            shade = "Blue" },
    { name = "Bluefire Blue",                            hex = "#000E28", p = 71,  m = false, manufacturer = "Jaguar",            shade = "Blue" },
    { name = "C-X75 Dark Blue",                          hex = "#000048", p = 73,  m = false, manufacturer = "Jaguar",            shade = "Blue" },
    { name = "Cotswold Blue",                            hex = "#253C56", p = 0,   m = false, manufacturer = "Jaguar",            shade = "Blue" },
    { name = "C-X75 Orange",                             hex = "#661800", p = 38,  m = false, manufacturer = "Jaguar",            shade = "Orange" },
    { name = "Firesand Orange",                          hex = "#D52204", p = 95,  m = false, manufacturer = "Jaguar",            shade = "Orange" },
    { name = "Golden Sand I",                            hex = "#7F6B68", p = 107, m = false, manufacturer = "Jaguar",            shade = "Gold" },
    { name = "Golden Sand II",                           hex = "#635F54", p = 37,  m = false, manufacturer = "Jaguar",            shade = "Gold" },
    { name = "Opalescent Silver Blue",                   hex = "#3A5F7F", p = 4,   m = false, manufacturer = "Jaguar",            shade = "Blue" },
    { name = "Sherwood Green",                           hex = "#2E3D36", p = 0,   m = false, manufacturer = "Jaguar",            shade = "Green" },
    { name = "Silverstone Green",                        hex = "#001519", p = 54,  m = false, manufacturer = "Jaguar",            shade = "Green" },
    { name = "Valencia Orange",                          hex = "#5F160E", p = 36,  m = false, manufacturer = "Jaguar",            shade = "Orange" },
    { name = "Sunburst Yellow",                          hex = "#847206", p = 0,   m = false, manufacturer = "Aston Martin",      shade = "Yellow" },
    { name = "Tiffany Blue",                             hex = "#20ADF5", p = 0,   m = false, manufacturer = "Aston Martin",      shade = "Blue" },
    { name = "Yellow Tang I",                            hex = "#7C6B29", p = 0,   m = false, manufacturer = "Aston Martin",      shade = "Yellow" },
    { name = "Yellow Tang II",                           hex = "#615516", p = 89,  m = false, manufacturer = "Aston Martin",      shade = "Yellow" },
    { name = "Slipstream Green",                         hex = "#2B412A", p = 102, m = false, manufacturer = "Aston Martin",      shade = "Green" },
    { name = "Skyfall Silver",                           hex = "#21252D", p = 111, m = false, manufacturer = "Aston Martin",      shade = "Grey" },
    { name = "Racing Green",                             hex = "#15272A", p = 5,   m = false, manufacturer = "Aston Martin",      shade = "Green" },
    { name = "Ocellus Teal",                             hex = "#00081A", p = 70,  m = false, manufacturer = "Aston Martin",      shade = "Blue" },
    { name = "Mariana Blue",                             hex = "#0A0B1B", p = 6,   m = false, manufacturer = "Aston Martin",      shade = "Blue" },
    { name = "Liquid Petroleum",                         hex = "#222F36", p = 7,   m = false, manufacturer = "Aston Martin",      shade = "Grey" },
    { name = "Mako Blue",                                hex = "#517E91", p = 4,   m = false, manufacturer = "Aston Martin",      shade = "Blue" },
    { name = "Hyper Red",                                hex = "#3C0612", p = 30,  m = false, manufacturer = "Aston Martin",      shade = "Red" },
}

vehicle_classes_t        = {
    [0] = "Compacts",
    [1] = "Sedans",
    [2] = "SUVs",
    [3] = "Coupes",
    [4] = "Muscle",
    [5] = "Sports Classics",
    [6] = "Sports",
    [7] = "Super",
    [8] = "Motorcycles",
    [9] = "Off-road",
    [10] = "Industrial",
    [11] = "Utility",
    [12] = "Vans",
    [13] = "Cycles",
    [14] = "Boats",
    [15] = "Helicopters",
    [16] = "Planes",
    [17] = "Service",
    [18] = "Emergency",
    [19] = "Military",
    [20] = "Commercial",
    [21] = "Trains",
    [22] = "Open Wheel"
}

collision_invalid_models = {
    3008087081,
    415536433,
    874602658,
    693843550,
    4189527861,
    1152297372,
    3907562202,
    2954040756,
    1198649884,
    1067874014,
}

supported_sale_scripts   = {
    ["gb_smuggler"] = { -- air
        {               -- (1.70) while .*?0 < func_.*?\(func_.*?, func_.*?, .*?Local_....?\.f_....?, -1
            l = 1985,
            o = 1035,
            v = 0
        },
        { -- (1.70) if .*?Local_....?\.f_....? > 0 && func_.*?&.*?Local_....?\.f_....?\), 30000, 0
            l = 1985,
            o = 1078,
            v = 1
        },
    },

    ["gb_gunrunning"] = {
        { -- (1.70) .*?Local_1...?\.f_...? = func_.*?\(func_.*?\(\), .*?Local_1...?\.f_...?, .*?Param0, -1\);
            l = 1262,
            o = 774,
            v = 0
        },
        { -- (1.70) if .*?Local_.*? != Local_....?\.f_...? && Local_....?\.f_...? > 0\)
            l = 1262,
            o = 816,
            v = 1
        },
    },

    ["gb_contraband_sell"] = {
        { -- (1.70) MISC::CLEAR_BIT\(.*?Local_...?\.f_1\), .*?Param0
            l = 563,
            o = 1,
            v = 99999
        },
    },

    ["gb_biker_contraband_sell"] = {
        { -- (1.70) else if .*?!func_.*?\(1\) && .*?Local_...?\.f_...? > 0\)
            l = 725,
            o = 122,
            v = 15
        },
    },

    ["fm_content_acid_lab_sell"] = {
        b = 5557, -- GENERICBITSET_I_WON -- (1.70) if .*?func_...?\(&.*?Local_....?, .*?Param0 // (uLocal_5557 = 4;)
        l = 5653, -- (1.70) if .*?Local_5...?\.f_....? == 0\)
        o = 1309
    },

    -- ["fm_content_smuggler_sell"] = {
    --   b = 3991, -- GENERICBITSET_I_WON -- (1.70) if .*?func_...?\(&.*?Local_....?, .*?Param0 // (uLocal_3991 = 4;)
    --   l = 4133, -- (1.70) if .*?Local_4...?\.f_....? == 0\)
    --   o = 489
    -- },
}

simplified_scr_names     = {
    { scr = "fm_content_smuggler_sell", sn = "Hangar (Land. Not supported.)" },
    { scr = "gb_smuggler",              sn = "Hangar (Air)" },
    { scr = "gb_contraband_sell",       sn = "CEO" },
    { scr = "gb_gunrunning",            sn = "Bunker" },
    { scr = "gb_biker_contraband_sell", sn = "Biker Business" },
    { scr = "fm_content_acid_lab_sell", sn = "Acid Lab" },
}

should_terminate_scripts = {
    "appArcadeBusinessHub",
    "appsmuggler",
    "appbikerbusiness",
    "appbunkerbusiness",
    "appbusinesshub"
}

movement_options_t       = {
    { name = "Default",            mvmt = nil,                                      wmvmt = nil,                         strf = nil,                                        wanim = nil },
    { name = "Arrogant (Female)",  mvmt = "move_f@arrogant@a",                      wmvmt = nil,                         strf = nil,                                        wanim = "Female" },
    { name = "Bodybuilder",        mvmt = "move_m@muscle@a",                        wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Businessman",        mvmt = "move_m@business@a",                      wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Ballistic",          mvmt = "anim_group_move_ballistic",              wmvmt = "anim_group_move_ballistic", strf = "move_strafe@ballistic",                    wanim = "Ballistic" },
    { name = "Cop",                mvmt = "move_m@intimidation@cop@unarmed",        wmvmt = nil,                         strf = "move_strafe@cop",                          wanim = "Default" },
    { name = "Depressed (Male)",   mvmt = "move_m@depressed@a",                     wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Depressed (Female)", mvmt = "move_f@depressed@a",                     wmvmt = nil,                         strf = nil,                                        wanim = "Female" },
    { name = "Drunk",              mvmt = "move_m@drunk@verydrunk",                 wmvmt = "move_m@drunk@verydrunk",    strf = "move_strafe@first_person@drunk",           wanim = "Hillbilly" },
    { name = "Fatass (Male)",      mvmt = "move_m@fat@a",                           wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Fatass (Female)",    mvmt = "move_f@fat@a",                           wmvmt = nil,                         strf = nil,                                        wanim = "Female" },
    { name = "Franklin",           mvmt = "move_p_m_one",                           wmvmt = nil,                         strf = nil,                                        wanim = "Franklin" },
    { name = "Gansta",             mvmt = "move_m@gangster@ng",                     wmvmt = nil,                         strf = "move_strafe@gang",                         wanim = "Gang1H" },
    { name = "Heels 01",           mvmt = "move_f@heels@c",                         wmvmt = nil,                         strf = nil,                                        wanim = "Female" },
    { name = "Heels 02",           mvmt = "move_f@heels@d",                         wmvmt = nil,                         strf = nil,                                        wanim = "Female" },
    { name = "Hiker (Male)",       mvmt = "move_m@hiking",                          wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Hiker (Female)",     mvmt = "move_f@hiking",                          wmvmt = nil,                         strf = nil,                                        wanim = "Female" },
    { name = "Hipster",            mvmt = "move_m@hipster@a",                       wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "HOBO",               mvmt = "move_m@hobo@a",                          wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Hoe",                mvmt = "move_f@maneater",                        wmvmt = nil,                         strf = nil,                                        wanim = "Female" },
    { name = "Injured (Male)",     mvmt = "move_m@injured",                         wmvmt = nil,                         strf = "move_strafe@injured",                      wanim = "Default" },
    { name = "Injured (Female)",   mvmt = "move_f@injured",                         wmvmt = nil,                         strf = "move_strafe@injured",                      wanim = "Female" },
    { name = "Jimmy",              mvmt = "move_characters@jimmy@slow@",            wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Lamar",              mvmt = "ANIM_GROUP_MOVE_LEMAR_ALLEY",            wmvmt = nil,                         strf = nil,                                        wanim = "Gang1H" },
    { name = "Lester",             mvmt = "move_heist_lester",                      wmvmt = nil,                         strf = nil,                                        wanim = "Hillbilly" },
    { name = "Michael",            mvmt = "move_p_m_zero",                          wmvmt = nil,                         strf = nil,                                        wanim = "Michael" },
    { name = "Sad",                mvmt = "move_m@sad@a",                           wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Sexy",               mvmt = "move_f@sexy@a",                          wmvmt = nil,                         strf = nil,                                        wanim = "Female" },
    { name = "Swag",               mvmt = "move_m@swagger",                         wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Tough",              mvmt = "move_m@tough_guy@",                      wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Trevor",             mvmt = "move_p_m_two",                           wmvmt = nil,                         strf = nil,                                        wanim = "Trevor" },
    { name = "Upper Class",        mvmt = "move_m@posh@",                           wmvmt = nil,                         strf = nil,                                        wanim = "Default" },
    { name = "Zombie",             mvmt = "clipset@anim@ingame@move_m@zombie@core", wmvmt = nil,                         strf = "clipset@anim@ingame@move_m@zombie@strafe", wanim = "ZOMBIE" },
}

-- fuck it. I'll do it manually since my smol brain
--
-- Can not figure out a better way.
ceo_warehouses_t         = {
    ["Convenience Store Lockup"] = {
        size = 0, max = 16, coords = vec3:new(249.246918, -1955.651978, 23.161957)
    },
    ["Celltowa Unit"] = {
        size = 0, max = 16, coords = vec3:new(898.484314, -1031.882446, 34.966454)
    },
    ["White Widow Garage"] = {
        size = 0, max = 16, coords = vec3:new(-1081.083740, -1261.013184, 5.648909)
    },
    ["Pacific Bait Storage"] = {
        size = 0, max = 16, coords = vec3:new(51.311188, -2568.470947, 6.004591)
    },
    ["Pier 400 Utility Building"] = {
        size = 0, max = 16, coords = vec3:new(272.409424, -3015.267090, 5.707359)
    },
    ["Foreclosed Garage"] = {
        size = 0, max = 16, coords = vec3:new(-424.773499, 184.146530, 80.752899)
    },
    ["GEE Warehouse"] = {
        size = 1, max = 42, coords = vec3:new(1563.832031, -2135.110840, 77.616447)
    },
    ["Derriere Lingerie Backlot"] = {
        size = 1, max = 42, coords = vec3:new(-1269.286133, -813.215820, 17.107399)
    },
    ["Fridgit Annexe"] = {
        size = 1, max = 42, coords = vec3:new(-528.074585, -1782.701904, 21.483055)
    },
    ["Discount Retail Unit"] = {
        size = 1, max = 42, coords = vec3:new(349.901184, 327.976440, 104.303856)
    },
    ["Disused Factory Outlet"] = {
        size = 1, max = 42, coords = vec3:new(-328.013458, -1354.755371, 31.296524)
    },
    ["LS Marine Building 3"] = {
        size = 1, max = 42, coords = vec3:new(-308.772247, -2698.393799, 6.000292)
    },
    ["Old Power Station"] = {
        size = 1, max = 42, coords = vec3:new(541.587646, -1944.362793, 24.985096)
    },
    ["Railyard Warehouse"] = {
        size = 1, max = 42, coords = vec3:new(503.738037, -653.082642, 24.751144)
    },
    ["Wholesale Furniture"] = {
        size = 2, max = 111, coords = vec3:new(1041.059814, -2172.653076, 31.488876)
    },
    ["West Vinewood Backlot"] = {
        size = 2, max = 111, coords = vec3:new(-245.651718, 202.504669, 83.792648)
    },
    ["Xero Gas Factory"] = {
        size = 2, max = 111, coords = vec3:new(-1045.004395, -2023.150146, 13.161570)
    },
    ["Logistics Depot"] = {
        size = 2, max = 111, coords = vec3:new(922.555481, -1560.048950, 30.756647)
    },
    ["Bilgeco Warehouse"] = {
        size = 2, max = 111, coords = vec3:new(-876.108032, -2734.502930, 13.844264)
    },
    ["Walker & Sons Warehouse"] = {
        size = 2, max = 111, coords = vec3:new(93.278641, -2216.144775, 6.033320)
    },
    ["Cypress Warehouses"] = {
        size = 2, max = 111, coords = vec3:new(1015.361633, -2510.986572, 28.302608)
    },
    ["Darnell Bros Warehouse"] = {
        size = 2, max = 111, coords = vec3:new(762.672363, -909.193054, 25.250854)
    },
}

mc_business_ids_t        = {
    { name = "Fake Documents",  id = 0, unit_max = 60, val_offset = 17319, blip = 498, possible_ids = { 5, 10, 15, 20 } },
    { name = "Weed",            id = 1, unit_max = 80, val_offset = 17323, blip = 496, possible_ids = { 2, 7, 12, 17 } },
    { name = "Fake Cash",       id = 2, unit_max = 40, val_offset = 17320, blip = 500, possible_ids = { 4, 9, 14, 19 } },
    { name = "Methamphetamine", id = 3, unit_max = 20, val_offset = 17322, blip = 499, possible_ids = { 1, 6, 11, 16 } },
    { name = "Cocaine",         id = 4, unit_max = 10, val_offset = 17321, blip = 497, possible_ids = { 3, 8, 13, 18 } },
}

hangar_info_t            = {
    [1] = { name = "LSIA Hangar 1", coords = vec3:new(-1148.908447, -3406.064697, 13.945053) },
    [2] = { name = "LSIA Hangar A17", coords = vec3:new(-1393.322021, -3262.968262, 13.944828) },
    [3] = { name = "Fort Zancudo Hangar A2", coords = vec3:new(-2022.336304, 3154.936768, 32.810272) },
    [4] = { name = "Fort Zancudo Hangar 3497", coords = vec3:new(-1879.105957, 3106.792969, 32.810234) },
    [5] = { name = "Fort Zancudo Hangar 3499", coords = vec3:new(-2470.278076, 3274.427734, 32.835461) },
}

bunker_info_t            = {
    [21] = { name = "Grand Senora Oilfields Bunker", coords = vec3:new(494.680878, 3015.895996, 41.041725) },
    [22] = { name = "Grand Senora Desert Bunker", coords = vec3:new(849.619812, 3024.425781, 41.266800) },
    [23] = { name = "Route 68 Bunker", coords = vec3:new(40.422565, 2929.004395, 55.746357) },
    [24] = { name = "Farmhouse Bunker", coords = vec3:new(1571.949341, 2224.597168, 78.350952) },
    [25] = { name = "Smoke Tree Road Bunker", coords = vec3:new(2107.135254, 3324.630615, 45.371754) },
    [26] = { name = "Thomson Scrapyard Bunker", coords = vec3:new(2488.706055, 3164.616699, 49.080124) },
    [27] = { name = "Grapeseed Bunker", coords = vec3:new(1798.502930, 4704.956543, 39.995476) },
    [28] = { name = "Paleto Forest Bunker", coords = vec3:new(-754.225769, 5944.171875, 19.836382) },
    [29] = { name = "Raton Canyon Bunker", coords = vec3:new(-388.333160, 4338.322754, 56.103130) },
    [30] = { name = "Lago Zancudo Bunker", coords = vec3:new(-3030.341797, 3334.570068, 10.105902) },
    [31] = { name = "Chumash Bunker", coords = vec3:new(-3156.140625, 1376.710693, 17.073570) },
}

aircraft_mgs_t           = {
    "VEHICLE_WEAPON_DOGFIGHTER_MG",
    "VEHICLE_WEAPON_HUNTER_MG",
    "VEHICLE_WEAPON_MICROLIGHT_MG",
    "VEHICLE_WEAPON_ROGUE_MG",
    "VEHICLE_WEAPON_SEABREEZE_MG",
    "VEHICLE_WEAPON_TULA_MG",
    "VEHICLE_WEAPON_TULA_NOSEMG",
    "VEHICLE_WEAPON_AVENGER_CANNON",
    "VEHICLE_WEAPON_BOMBUSHKA_CANNON",
    "VEHICLE_WEAPON_HUNTER_CANNON",
    "VEHICLE_WEAPON_ROGUE_CANNON",
    "VEHICLE_WEAPON_STRIKEFORCE_CANNON",
    "VEHICLE_WEAPON_RAIJU_CANNONS",
    "VEHICLE_WEAPON_AKULA_TURRET_SINGLE",
    "VEHICLE_WEAPON_AKULA_TURRET_DUAL",
    "VEHICLE_WEAPON_MOGUL_TURRET",
    "VEHICLE_WEAPON_MOGUL_DUALTURRET",
    "VEHICLE_WEAPON_NOSE_TURRET_VALKYRIE",
    "VEHICLE_WEAPON_TURRET_VALKYRIE",
    "VEHICLE_WEAPON_PLAYER_LAZER",
    "VEHICLE_WEAPON_PLAYER_SAVAGE",
    "VEHICLE_WEAPON_PLAYER_HUNTER",
    "VEHICLE_WEAPON_PLAYER_BUZZARD",
}
