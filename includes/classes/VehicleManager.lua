---@diagnostic disable

---@class VehicleManager
VehicleManager = {}
VehicleManager.__index = VehicleManager

function VehicleManager.OnEnter()
    Self.Vehicle.Current      = Self.GetVehicle()
    Self.Vehicle.IsCar        = VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current))
    Self.Vehicle.IsQuad       = VEHICLE.IS_THIS_MODEL_A_QUADBIKE(ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current))
    Self.Vehicle.IsPlane      = VEHICLE.IS_THIS_MODEL_A_PLANE(ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current))
    Self.Vehicle.IsHeli       = VEHICLE.IS_THIS_MODEL_A_HELI(ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current))
    Self.Vehicle.EngineHealth = VEHICLE.GET_VEHICLE_ENGINE_HEALTH(Self.Vehicle.Current)
    Self.Vehicle.BodyHealth   = VEHICLE.GET_VEHICLE_BODY_HEALTH(Self.Vehicle.Current)
    Self.Vehicle.IsFlatbed    = ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current) == flatbedModel
    Self.Vehicle.IsEngineOn   = VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current)

    Self.Vehicle.IsBoat  = (
        VEHICLE.IS_THIS_MODEL_A_BOAT(ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current)) or
        VEHICLE.IS_THIS_MODEL_A_JETSKI(ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current))
    )

    Self.Vehicle.IsSportsCar = (
        Self.Vehicle.IsCar and
        (
            Game.Vehicle.IsSportsOrSuper(Self.Vehicle.Current) or
            Game.Vehicle.IsSportsCar(Self.Vehicle.Current)
        ) or
        false
    )

    Self.Vehicle.IsBike = (
        VEHICLE.IS_THIS_MODEL_A_BIKE(ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current)) and
        (VEHICLE.GET_VEHICLE_CLASS(Self.Vehicle.Current) ~= 13) and
        (ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Current) ~= 0x7B54A9D3)
    )

    Self.Vehicle.DoorLockState = (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(Self.Vehicle.Current) <= 1) and 1 or 2

    if Self.Vehicle.IsEngineOn then
        Self.Vehicle.Speed = ENTITY.GET_ENTITY_SPEED(Self.Vehicle.Current)
        Self.Vehicle.Gear  = VEHICLE.GET_VEHICLE_CURRENT_DRIVE_GEAR_(Self.Vehicle.Current)
        Self.Vehicle.RPM   = VEHICLE.GET_VEHICLE_CURRENT_REV_RATIO_(Self.Vehicle.Current)

        
        if not using_nos then
            Self.Vehicle.MaxSpeed = VEHICLE.GET_VEHICLE_ESTIMATED_MAX_SPEED(Self.Vehicle.Current)
        end
    end

    if (
        Self.IsDriving() and
        (Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad) and
        VEHICLE.GET_IS_VEHICLE_ENGINE_RUNNING(Self.Vehicle.Current)
    ) then
        Self.Vehicle.IsEngineBrakeDisabled     = Memory.GetVehicleHandlingFlag(Self.Vehicle.Current, HF._FREEWHEEL_NO_GAS)
        Self.Vehicle.IsTractionControlDisabled = Memory.GetVehicleHandlingFlag(Self.Vehicle.Current, HF._FORCE_NO_TC_OR_SC)
        Self.Vehicle.HasKersBoost              = Memory.GetVehicleHandlingFlag(Self.Vehicle.Current, HF._HAS_KERS)
        Self.Vehicle.IsOffroaderEnabled        = Memory.GetVehicleHandlingFlag(Self.Vehicle.Current, HF._OFFROAD_ABILITIES_X2)
        Self.Vehicle.HasRallyTires             = Memory.GetVehicleHandlingFlag(Self.Vehicle.Current, HF._HAS_RALLY_TYRES)
        Self.Vehicle.IsLowSpeedWheelieEnabled  = Memory.GetVehicleHandlingFlag(Self.Vehicle.Current, HF._LOW_SPEED_WHEELIES)

        if Self.IsDriving() and Self.Vehicle.Speed > 1 then
            local speed_vector = ENTITY.GET_ENTITY_SPEED_VECTOR(Self.Vehicle.Current, true)
            Self.Vehicle.IsDrifting = (
                VEHICLE.IS_VEHICLE_ON_ALL_WHEELS(Self.Vehicle.Current) and
                (speed_vector.x ~= 0) and (speed_vector.x > 6 or speed_vector.x < -6)
            )
        else
            if Self.Vehicle.IsDrifting then
                Self.Vehicle.IsDrifting = false
            end
        end
    end

    if Self.IsDriving() and (Self.Vehicle.Current ~= Self.Vehicle.Previous) then
        VehicleManager.OnSwitch()
    end
end

function VehicleManager.OnSwitch()
    if (
        (Self.Vehicle.Previous > 0) and
        ENTITY.DOES_ENTITY_EXIST(Self.Vehicle.Previous) and
        ENTITY.IS_ENTITY_A_VEHICLE(Self.Vehicle.Previous)
    ) then
        if Self.Vehicle.HasLoudRadio then
            AUDIO.SET_VEHICLE_RADIO_LOUD(Self.Vehicle.Previous, false)
            Self.Vehicle.HasLoudRadio = false
        end

        if not has_custom_tires then
            VEHICLE.TOGGLE_VEHICLE_MOD(Self.Vehicle.Previous, 20, false)
        end

        if (
            (default_tire_smoke.r ~= driftSmoke_T.r) or
            (default_tire_smoke.g ~= driftSmoke_T.g) or
            (default_tire_smoke.b ~= driftSmoke_T.b)
        ) then
            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(
                Self.Vehicle.Previous,
                default_tire_smoke.r,
                default_tire_smoke.g,
                default_tire_smoke.b
            )
        end

        if (
            VEHICLE.IS_THIS_MODEL_A_CAR(ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Previous)) and
            (VEHICLE.GET_VEHICLE_DOOR_LOCK_STATUS(Self.Vehicle.Previous) ~= 1)
        ) then
            VEHICLE.SET_VEHICLE_DOORS_LOCKED(Self.Vehicle.Previous, 1)
            VEHICLE.SET_VEHICLE_ALARM(Self.Vehicle.Previous, false)
        end

        if Self.Vehicle.HasUnbreakableWindows then
            VEHICLE.SET_DONT_PROCESS_VEHICLE_GLASS(Self.Vehicle.Previous, false)
            Self.Vehicle.HasUnbreakableWindows = false
        end

        if engine_sound_changed then
            AUDIO.FORCE_USE_AUDIO_GAME_OBJECT(
                Self.Vehicle.Previous,
                vehicles.get_vehicle_display_name(
                    ENTITY.GET_ENTITY_MODEL(Self.Vehicle.Previous)
                )
            )
            Game.Vehicle.SetAcceleration(Self.Vehicle.Previous, 1.0)
            engine_sound_changed = false
        end
    end
    Self.Vehicle.Previous = Self.Vehicle.Current
end

VehicleManager.WhileOnFoot = function()
    if Self.Vehicle.Speed ~= 0 then Self.Vehicle.Speed = 0 end
    if Self.Vehicle.Gear ~= 0 then Self.Vehicle.Gear = 0 end
    if Self.Vehicle.RPM ~= 0 then Self.Vehicle.RPM = 0 end
    if Self.Vehicle.MaxSpeed ~= 0 then Self.Vehicle.MaxSpeed = 0 end
    if Self.Vehicle.IsDrifting then Self.Vehicle.IsDrifting = false end

    if (Self.Vehicle.Current ~= 0) and not ENTITY.DOES_ENTITY_EXIST(Self.Vehicle.Current) then
        Self.Vehicle.Current = 0
    end
end
