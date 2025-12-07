---@class StructRobberyType
local StructRobberyType = {
    ["The Cargo Ship"] = {
        id = 0,
        fm_prog = 126,
        scope_bs = 1,
        disrupt = 3,
    },
    ["The Gangbanger"] = {
        id = 1,
        fm_prog = 126,
        scope_bs = 3,
        disrupt = 3,
    },
    ["The Duggan"] = {
        id = 2,
        fm_prog = 126,
        scope_bs = 4,
        disrupt = 3,
    },
    ["The Podium"] = {
        id = 3,
        fm_prog = 126,
        scope_bs = 8,
        disrupt = 3,
    },
    ["The McTony"] = {
        id = 4,
        fm_prog = 126,
        scope_bs = 16,
        disrupt = 3,
    },
}

---@class SalvageYard
local SalvageYard = {}
SalvageYard.__index = SalvageYard

---@return SalvageYard
function SalvageYard:init()
    local instance = setmetatable({
        robbery_cooldown_string = "loading...",
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

---@returns integer
function SalvageYard:OwnsSalvageYard()
    return stats.get_int("MPX_SALVAGE_YARD_OWNED") ~= 0
end

---@param slot integer
---@returns string|nil
function SalvageYard:CheckWeeklyRobberyStatus(slot)
    local statName  = "MPX_SALV23_VEHROB_STATUS" .. slot
    local status    = stats.get_int(statName)
    if status == 0 then
        return "Available"
    elseif status == 1 then
        return "In Progress"
    elseif status == 2 then
        return "Completed"
    else 
        return nil
    end
end

---@param slot integer
---@returns carHash|boolean
function SalvageYard:LiftTaken(slot)
    local statName = "MPX_MPSV_MODEL_SALVAGE_LIFT" .. slot
    local status   = stats.get_int(statName)
    if status == 0 then
        return false
    else
        return true
    end
end

---@returns string
function SalvageYard:SetCooldownString()
    local cooldown = stats.get_int("MPX_SALV23_VEHROB_CD")
    if cooldown <= 0 then
        self.robbery_cooldown_string = _T("SY_CD_NONE")
        return
    else
        self.robbery_cooldown_string    = _T("SY_CD_ACTIVE")
    end
end

---@returns string
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
    local modelStat = "MPX_MPSV_MODEL_SALVAGE_VEH" .. slot
    local model = stats.get_int(modelStat)
    if model == 0 then return nil end

    return tostring(model) --.... why it returns model id instead of hash
    -- return VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(model)
end

---@return string
function SalvageYard:GetRobberyTypeName()
    local t = stats.get_int("MPX_SALV23_VEH_ROB")
    for name, info in pairs(StructRobberyType) do
        if info.id == t then
            return name
        end
    end

    return "Unknown"
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
    for name, info in pairs(StructRobberyType) do
        if info.id == self:GetRobberyType() then
            stats.set_int("MPX_SALV23_FM_PROG", info.fm_prog)
            stats.set_int("MPX_SALV23_SCOPE_BS", info.scope_bs)
            stats.set_int("MPX_SALV23_DISRUPT", info.disrupt)
            Toast:ShowMessage("Salvage Yard", _T("SY_PREP_SKIP"))
            return
        end
    end
end

function SalvageYard:DoubleCarWorth()
    local current_worth = stats.get_int("MPX_SALV23_SALE_VAL")
    stats.set_int("MPX_SALV23_SALE_VAL", current_worth * 2)
end

---@returns string
function SalvageYard:GetCarNameFromHash(hash)
    return VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(hash)
end

function SalvageYard:Start()
    self:SetCooldownString()
end

function SalvageYard:Reset()
    self.robbery_cooldown_string = ""
end

return SalvageYard