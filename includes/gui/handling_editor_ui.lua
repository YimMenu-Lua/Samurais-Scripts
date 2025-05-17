---@diagnostic disable

function HandingEditorUI()
    local f_PosY = 300
    if self.get_veh() ~= 0 then
        f_PosY = f_PosY * 1.7
    end

    ImGui.BeginChild("HandlingEditorChild", 500, f_PosY, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)
    noEngineBraking, nebrUsed = ImGui.Checkbox("Disable Engine Braking", noEngineBraking)
    UI.Tooltip(_T("NOENGINEBRAKING_DESC_"))
    if nebrUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("noEngineBraking", noEngineBraking)
        if not noEngineBraking then
            if Self.Vehicle.IsEngineBrakeDisabled then
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._FREEWHEEL_NO_GAS, false)
            end
        end
    end

    ImGui.SameLine()
    ImGui.Dummy(37, 1)
    ImGui.SameLine()
    kersBoost, kbUsed = ImGui.Checkbox("KERS Boost", kersBoost)
    UI.Tooltip(_T("KERSBOOST_DESC_"))
    if kbUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("kersBoost", kersBoost)
        if not kersBoost then
            if Self.Vehicle.HasKersBoost then
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._HAS_KERS, false)
                script.run_in_fiber(function()
                    if VEHICLE.GET_VEHICLE_HAS_KERS(Self.Vehicle.Current) then
                        VEHICLE.SET_VEHICLE_KERS_ALLOWED(Self.Vehicle.Current, false)
                    end
                end)
            end
        end
    end

    offroaderx2, offroadrUsed = ImGui.Checkbox("Better Offroad Capabilities", offroaderx2)
    UI.Tooltip(_T("OFFROADERX2_DESC_"))
    if offroadrUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("offroaderx2", offroaderx2)
        if not offroaderx2 then
            if Self.Vehicle.IsOffroaderEnabled then
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._OFFROAD_ABILITIES_X2, false)
            end
        end
    end

    ImGui.SameLine()
    ImGui.Dummy(15, 1)
    ImGui.SameLine()
    rallyTires, rallytiresUsed = ImGui.Checkbox("Rally Tires", rallyTires)
    UI.Tooltip(_T("RALLYTIRES_DESC_"))
    if rallytiresUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("rallyTires", rallyTires)
        if not rallyTires then
            if Self.Vehicle.HasRallyTires then
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._HAS_RALLY_TYRES, false)
            end
        end
    end

    noTractionCtrl, notcUsed = ImGui.Checkbox("Force No Traction Control", noTractionCtrl)
    UI.Tooltip(_T("FORCE_NO_TC_DESC_"))
    if notcUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("noTractionCtrl", noTractionCtrl)
        if not noTractionCtrl then
            if Self.Vehicle.IsTractionControlDisabled and (Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._FORCE_NO_TC_OR_SC, false)
            end
        end
    end

    ImGui.SameLine()
    ImGui.Dummy(20, 1)
    ImGui.SameLine()
    easyWheelie, ezwUsed = ImGui.Checkbox("Easy Wheelie", easyWheelie)
    UI.Tooltip(_T("EASYWHEELIE_DESC_"))
    if ezwUsed then
        UI.WidgetSound("Nav2")
        CFG:SaveItem("easyWheelie", easyWheelie)
        if not easyWheelie then
            if Self.Vehicle.IsLowSpeedWheelieEnabled and (Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._LOW_SPEED_WHEELIES, false)
            end
        end
    end

    ImGui.Spacing()
    ImGui.SetWindowFontScale(1.2)
    ImGui.SeparatorText("MISC")
    ImGui.SetWindowFontScale(1.0)

    if self.get_veh() ~= 0 then
        rocketBoost, rbUsed = ImGui.Checkbox("Rocket Boost",
            Memory.GetVehicleModelFlag(Self.Vehicle.Current, VMF._HAS_ROCKET_BOOST))
        UI.Tooltip(_T("ROCKET_BOOST_DESC_"))
        if rbUsed and (Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
            UI.WidgetSound("Nav2")
            Memory.SetVehicleModelFlag(Self.Vehicle.Current, VMF._HAS_ROCKET_BOOST, rocketBoost)
            if not Game.Vehicle.IsElectric(Self.Vehicle.Current) then
                script.run_in_fiber(function()
                    if not rocketBoost and (Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
                        STREAMING.REMOVE_NAMED_PTFX_ASSET("veh_impexp_rocket")
                    else
                        Game.RequestNamedPtfxAsset("veh_impexp_rocket")
                    end
                end)
            end
        end

        ImGui.SameLine()
        ImGui.Dummy(25, 1)
        ImGui.SameLine()
        vehJump, vjUsed = ImGui.Checkbox("Vehicle Jump",
            Memory.GetVehicleModelFlag(Self.Vehicle.Current, VMF._JUMPING_CAR))
        UI.Tooltip(_T("VEH_JUMP_DESC_"))
        if vjUsed then
            UI.WidgetSound("Nav2")
            if (Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
                Memory.SetVehicleModelFlag(Self.Vehicle.Current, VMF._JUMPING_CAR, vehJump)
                script.run_in_fiber(function()
                    VEHICLE.SET_USE_HIGHER_CAR_JUMP(Self.Vehicle.Current, vehJump)
                end)
            end
        end

        if vehJump then
            ImGui.SameLine()
            ImGui.Dummy(28, 1)
            ImGui.SameLine()
            ImGui.BeginDisabled(not Self.Vehicle.IsCar)
            vehChute, vehChuteUsed = ImGui.Checkbox("Parachute",
                Memory.GetVehicleModelFlag(Self.Vehicle.Current, VMF._HAS_PARACHUTE))
            ImGui.EndDisabled()
            UI.Tooltip(_T("VEH_PARACHUTE_DESC_"))
            if vehChuteUsed then
                UI.WidgetSound("Nav2")
                if Self.Vehicle.IsCar then
                    Memory.SetVehicleModelFlag(Self.Vehicle.Current, VMF._HAS_PARACHUTE, vehChute)
                end
            end
        else
            if vehChute then
                vehChute = false
            end
        end

        b_RwSteering, rwstrUsed = ImGui.Checkbox(
            "Rear Wheel Steering",
            Memory.GetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_REARWHEELS)
        )
        UI.Tooltip(_T("REAR_WHEEL_STEERING_DESC_"))
        if rwstrUsed then
            UI.WidgetSound("Nav2")
            if b_RwSteering and (Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
                if b_AwSteering then
                    Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_ALL_WHEELS, false)
                    b_AwSteering = false
                end
                if b_HandbrakeSteering then
                    Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._HANDBRAKE_REARWHEELSTEER, false)
                    b_HandbrakeSteering = false
                end
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_REARWHEELS, true)
            else
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_REARWHEELS, false)
            end
        end

        ImGui.SameLine()
        b_AwSteering, awstrUsed = ImGui.Checkbox("All Wheel Steering",
            Memory.GetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_ALL_WHEELS))
        UI.Tooltip(_T("ALL_WHEEL_STEERING_DESC_"))
        if awstrUsed then
            UI.WidgetSound("Nav2")
            if b_AwSteering and (Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
                if b_RwSteering then
                    Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_REARWHEELS, false)
                    b_RwSteering = false
                end
                if b_HandbrakeSteering then
                    Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._HANDBRAKE_REARWHEELSTEER, false)
                    b_HandbrakeSteering = false
                end
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_ALL_WHEELS, true)
            else
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_ALL_WHEELS, false)
            end
        end

        b_HandbrakeSteering, hbstrUsed = ImGui.Checkbox("Handbrake Steering",
            Memory.GetVehicleHandlingFlag(Self.Vehicle.Current, HF._HANDBRAKE_REARWHEELSTEER))
        UI.Tooltip(_T("HANDBRAKE_STEERING_DESC_"))
        if hbstrUsed then
            UI.WidgetSound("Nav2")
            if b_HandbrakeSteering and (Self.Vehicle.IsCar or Self.Vehicle.IsBike or Self.Vehicle.IsQuad) then
                if b_RwSteering then
                    Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_REARWHEELS, false)
                    b_RwSteering = false
                end
                if b_AwSteering then
                    Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._STEER_ALL_WHEELS, false)
                    b_AwSteering = false
                end
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._HANDBRAKE_REARWHEELSTEER, true)
            else
                Memory.SetVehicleHandlingFlag(Self.Vehicle.Current, HF._HANDBRAKE_REARWHEELSTEER, false)
            end
        end
        ImGui.Spacing()
        UI.ColoredText(_T("STEERING_FLAGS_NOTE_TXT_"), "orange", 0.8, 25)
    else
        ImGui.Text(_T("GET_IN_VEH_WARNING_"))
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()
end
