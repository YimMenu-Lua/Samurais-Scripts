local robbery_types <const> = {
    {
        name = "The Cargo Ship",
        fm_prog = 126,
        scope_bs = 1,
        disrupt = 3,
    },
    {
        name = "The Gangbanger",
        fm_prog = 126,
        scope_bs = 3,
        disrupt = 3,
    },
    {
        name = "The Duggan",
        fm_prog = 126,
        scope_bs = 4,
        disrupt = 3,
    },
    {
        name = "The Podium",
        fm_prog = 126,
        scope_bs = 8,
        disrupt = 3,
    },
    {
        name = "The McTony",
        fm_prog = 126,
        scope_bs = 16,
        disrupt = 3,
    },
}

local robbery_status_tostring <const> = { "Available", "In Progress", "Completed" }

---@class SalvageYard
local SalvageYard = {}
SalvageYard.__index = SalvageYard

---@return SalvageYard
function SalvageYard:init()
    local instance = setmetatable({
        robbery_cooldown_string = "Unknown.",
    }, self)

    ThreadManager:CreateNewThread("SS_SALVAGE", function()
        instance:Start()
    end)

    Backend:RegisterEventCallback(eBackendEvent.RELOAD_UNLOAD, function()
        instance:Reset()
    end)

    Backend:RegisterEventCallback(eBackendEvent.SESSION_SWITCH, function()
        instance:Reset()
    end)

    return instance
end

---@return boolean
function SalvageYard:OwnsSalvageYard()
    return stats.get_int("MPX_SALVAGE_YARD_OWNED") ~= 0
end

---@param slot integer
---@return string|nil
function SalvageYard:CheckWeeklyRobberyStatus(slot)
    local statName  = "MPX_SALV23_VEHROB_STATUS" .. slot
    local status    = stats.get_int(statName)
    return robbery_status_tostring[status+1]
end

---@param slot integer
---@return boolean
function SalvageYard:IsLiftTaken(slot)
    local statName = "MPX_MPSV_MODEL_SALVAGE_LIFT" .. slot
    return stats.get_int(statName) ~= 0
end

function SalvageYard:SetCooldownString()
    local cooldown = stats.get_int("MPX_SALV23_VEHROB_CD")
    if cooldown <= 0 then
        self.robbery_cooldown_string = _T("SY_CD_NONE")
    else
        self.robbery_cooldown_string = _T("SY_CD_ACTIVE")
    end
end

---@return string
function SalvageYard:GetCooldownString()
    return self.robbery_cooldown_string
end

function SalvageYard:DisableCooldown()
    stats.set_int("MPX_SALV23_VEHROB_CD", 0)
    self.robbery_cooldown_string = _T("SY_CD_DISABLED")
end

function SalvageYard:DisableWeeklyCooldown()
    local week = stats.get_int("MPX_SALV23_WEEK_SYNC")
    --
end

---@param slot integer
---@return string|nil
function SalvageYard:GetCarFromSlot(slot)
    local modelStat = "MPX_MODEL_SALVAGE_VEH" .. slot
    local model = stats.get_int(modelStat)
    if model == 0 then return nil end

    return VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
end

---@return string
function SalvageYard:GetRobberyTypeName()
    local id = stats.get_int("MPX_SALV23_VEH_ROB")
    return robbery_types[id+1].name or "Unknown"
end

function SalvageYard:GetRobberyType()
    return stats.get_int("MPX_SALV23_VEH_ROB")
end

function SalvageYard:GetRobberyValue()
    return stats.get_int("MPX_SALV23_SALE_VAL")
end

function SalvageYard:GetRobberyKeepState()
    return stats.get_bool("MPX_SALV23_CAN_KEEP")
end

function SalvageYard:CompletePreparation()
    local current = self:GetRobberyType()
    local info = robbery_types[current+1]
    if (not info) then
        Toast:ShowError("Salvage Yard", "Failed to get current robbery. Are you sure you started one?")
        return
    end

    stats.set_int("MPX_SALV23_FM_PROG", info.fm_prog)
    stats.set_int("MPX_SALV23_SCOPE_BS", info.scope_bs)
    stats.set_int("MPX_SALV23_DISRUPT", info.disrupt)
    Toast:ShowSuccess("Salvage Yard", _T("SY_PREP_SKIP"))
end

function SalvageYard:DoubleCarWorth()
    local current_worth = stats.get_int("MPX_SALV23_SALE_VAL")
    stats.set_int("MPX_SALV23_SALE_VAL", current_worth * 2)
end

---@return string
function SalvageYard:GetCarNameFromHash(hash)
    return VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(hash)
end

function SalvageYard:Start()
    self:SetCooldownString()
end

function SalvageYard:Reset()
    self.robbery_cooldown_string = "Unknown."
end

return SalvageYard
