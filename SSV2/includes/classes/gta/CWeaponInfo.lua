local CWeaponFiringPatternAliases = require("includes.classes.gta.CWeaponFiringPatternAliases")
---@enum eWeaponDamageType
Enums.eWeaponDamageType           = {
	Unknown          = 0,
	None             = 1,
	Melee            = 2,
	Bullet           = 3,
	BulletRubber     = 4,
	Explosive        = 5,
	Fire             = 6,
	Collision        = 7,
	Fall             = 8,
	Drown            = 9,
	Electric         = 10,
	BarbedWire       = 11,
	FireExtinguisher = 12,
	Smoke            = 13,
	WaterCannon      = 14,
	Tranquilizer     = 15
}

---@enum eWeaponFireType
Enums.eWeaponFireType             = {
	None               = 0,
	Melee              = 1,
	InstantHit         = 2,
	DelayedHit         = 3,
	ProjectTile        = 4,
	VolumetricParticle = 5
}

---@enum eWeaponWheelSlot
Enums.eWeaponWheelSlot            = {
	Pistol    = 0,
	SMG       = 1,
	Rifle     = 2,
	Sniper    = 3,
	Melee     = 4,
	ShotGun   = 5,
	Heavy     = 6,
	Throwable = 7
}

---@enum eWeaponEffectGroup
Enums.eWeaponEffectGroup          = {
	PunchKick      = 0,
	MeleeWood      = 1,
	MeleeMetal     = 2,
	MeleeSharp     = 3,
	MeleeGeneric   = 4,
	PistolSmall    = 5,
	PistolLarge    = 6,
	PistolSilenced = 7,
	Rubber         = 8,
	SMG            = 9,
	ShotGun        = 10,
	RifleAssault   = 11,
	RifleSniper    = 12,
	Rocket         = 13,
	Grenade        = 14,
	Molotov        = 15,
	Fire           = 16,
	Explosion      = 17,
	Laser          = 18,
	Stungun        = 19,
	HeavyMG        = 20,
	VehicleMG      = 21,
}

---@class CWeaponInfo
---@field protected m_ptr pointer
---@field m_name_hash pointer<joaat_t>  //0x0010
---@field m_model_hash pointer<joaat_t> //0x0014
---@field m_audio_hash pointer<joaat_t> //0x0018
---@field m_slot_hash pointer<joaat_t>  //0x001C
---@field m_damage_type pointer<eWeaponDamageType> //0x0020
---@field m_fire_type pointer<eWeaponFireType> //0x0054
---@field m_wheel_slot pointer<eWeaponWheelSlot> //0x0058
---@field m_group_hash pointer<joaat_t> //0x005C
---@field m_clip_size pointer<uint32_t> //0x0070
---@field m_damage pointer<float> //0x00B0
---@field m_vehicle_damage_modifier pointer<float> //0x00D4
---@field m_force pointer<float> //0x00D8
---@field m_force_on_ped pointer<float> //0x00DC
---@field m_force_on_vehicle pointer<float> //0x00E0
---@field m_force_on_heli pointer<float> //0x00E4
---@field m_force_max_strength_mult pointer<float> //0x00F8
---@field m_projectile_force pointer<float> //0x0108
---@field m_frag_impulse pointer<float> //0x010C
---@field m_penetration pointer<float> //0x0110
---@field m_speed pointer<float> //0x011C
---@field m_bullets_in_batch pointer<uint32_t> //0x0120
---@field m_bullets_per_anime_loop pointer<uint32_t> //0x0138
---@field m_time_between_shots pointer<float> //0x013C
---@field m_should_fire_time_left pointer<float> //0x0140
---@field m_alt_wait_time pointer<float> //0x0150
---@field m_effect_group pointer<eWeaponEffectGroup> //sWeaponFx:At(0x0)
---@field m_vehicle_weapon_hash pointer<joaat_t> //0x02B4
---@field m_default_camera_hash pointer<joaat_t> //0x02B8
---@field m_aim_camera_hash pointer<joaat_t> //0x02BC
---@field m_fire_camera_hash pointer<joaat_t> //0x02C0
---@field m_camera_fov pointer<float> //0x02FC
---@field m_reticule_scale pointer<float> //0x05A8
---@field m_reticule_style_hash pointer<joaat_t> //0x05AC
---@field m_firing_pattern_aliases CWeaponFiringPatternAliases //0x0920
---@overload fun(ptr: pointer): CWeaponInfo
local CWeaponInfo                 = { m_ptr = nullptr }
CWeaponInfo.__index               = CWeaponInfo
---@diagnostic disable-next-line: param-type-mismatch
setmetatable(CWeaponInfo, {
	__call = function(_, ...)
		return CWeaponInfo.new(...)
	end
})

---@param ptr pointer
---@return CWeaponInfo?
function CWeaponInfo.new(ptr)
	if (not ptr or not ptr:is_valid()) then
		return
	end

	ptr = ptr:deref()
	return setmetatable({
		m_ptr                     = ptr,
		m_name_hash               = ptr:add(0x0010),
		m_model_hash              = ptr:add(0x0014),
		m_audio_hash              = ptr:add(0x0018),
		m_slot_hash               = ptr:add(0x001C),
		m_damage_type             = ptr:add(0x0020),
		m_fire_type               = ptr:add(0x0054),
		m_wheel_slot              = ptr:add(0x0058),
		m_group_hash              = ptr:add(0x005C),
		m_clip_size               = ptr:add(0x0070),
		m_damage                  = ptr:add(0x00B0),
		m_vehicle_damage_modifier = ptr:add(0x00D4),
		m_force                   = ptr:add(0x00D8),
		m_force_on_ped            = ptr:add(0x00DC),
		m_force_on_vehicle        = ptr:add(0x00E0),
		m_force_on_heli           = ptr:add(0x00E4),
		m_force_max_strength_mult = ptr:add(0x00F8),
		m_projectile_force        = ptr:add(0x0108),
		m_frag_impulse            = ptr:add(0x010C),
		m_penetration             = ptr:add(0x0110),
		m_speed                   = ptr:add(0x011C),
		m_bullets_in_batch        = ptr:add(0x0120),
		m_bullets_per_anime_loop  = ptr:add(0x0138),
		m_time_between_shots      = ptr:add(0x013C),
		m_should_fire_time_left   = ptr:add(0x0140),
		m_alt_wait_time           = ptr:add(0x0150),
		m_effect_group            = ptr:add(0x0170),
		m_vehicle_weapon_hash     = ptr:add(0x02B4),
		m_default_camera_hash     = ptr:add(0x02B8),
		m_aim_camera_hash         = ptr:add(0x02BC),
		m_fire_camera_hash        = ptr:add(0x02C0),
		m_camera_fov              = ptr:add(0x02FC),
		m_reticule_scale          = ptr:add(0x05A8),
		m_reticule_style_hash     = ptr:add(0x05AC),
		m_firing_pattern_aliases  = CWeaponFiringPatternAliases(ptr:add(0x0920):deref())
		---@diagnostic disable-next-line: param-type-mismatch
	}, CWeaponInfo)
end

---@return boolean
function CWeaponInfo:IsValid()
	return self.m_ptr and self.m_ptr:is_valid()
end

---@return pointer
function CWeaponInfo:GetPointer()
	return self.m_ptr
end

---@return uint64_t
function CWeaponInfo:GetAddress()
	return self.m_ptr:get_address()
end

return CWeaponInfo
