---@diagnostic disable

function WeaponsUI()
    ImGui.BeginChild("WeaponChild", 400, 500, true)
    ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, 25, 25)

    Triggerbot, TbUsed = ImGui.Checkbox(_T("TRIGGERBOT_CB_"), Triggerbot)
    UI.Tooltip(_T("TRIGGERBOT_DESC_"))
    if TbUsed then
        CFG:SaveItem("Triggerbot", Triggerbot)
        UI.WidgetSound("Nav2")
    end

    if Triggerbot then
        ImGui.SameLine(); aimEnemy, aimEnemyUsed = ImGui.Checkbox(_T("ENEMY_ONLY_CB_"), aimEnemy)
        if aimEnemyUsed then
            CFG:SaveItem("aimEnemy", aimEnemy)
            UI.WidgetSound("Nav2")
        end
    end

    MagicBullet, mbUsed = ImGui.Checkbox(_T("MAGIC_BULLET_CB_"), MagicBullet)
    UI.Tooltip(_T("MAGIC_BULLET_DESC_"))
    if mbUsed then
        CFG:SaveItem("MagicBullet", MagicBullet)
        UI.WidgetSound("Nav2")
    end

    autoKill, autoKillUsed = ImGui.Checkbox(_T("AUTOKILL_CB_"), autoKill)
    UI.Tooltip(_T("AUTOKILL_DESC_"))
    if autoKillUsed then
        CFG:SaveItem("autoKill", autoKill)
        UI.WidgetSound("Nav2")
    end

    runaway, runawayUsed = ImGui.Checkbox(_T("ENEMIES_FLEE_CB_"), runaway)
    UI.Tooltip(_T("ENEMIES_FLEE_DESC_"))
    if runawayUsed then
        CFG:SaveItem("runaway", runaway)
        UI.WidgetSound("Nav2")
        if runaway then
            publicEnemy = false
        end
    end

    replace_pool_q, rpqUsed = ImGui.Checkbox(_T("KATANA_CB_"), replace_pool_q)
    UI.Tooltip(_T("KATANA_DESC_"))
    if rpqUsed then
        CFG:SaveItem("replace_pool_q", replace_pool_q)
        UI.WidgetSound("Nav2")
    end

    if replace_pool_q then
        ImGui.Text(_T("KATANA_WPN_CHOICE_TXT_")); ImGui.SameLine(); ImGui.SetNextItemWidth(140)
        katana_replace_index, kriUsed = ImGui.Combo("##kri", katana_replace_index,
            { "Baseball Bat", "Golf Club", "Machete", "Pool Que" }, 4)
        UI.Tooltip(_T("KATANA_WPN_CHOICE_DESC_"))
        if kriUsed then
            UI.WidgetSound("Nav")
            if katana_replace_index == 0 then
                katana_replace_model = 0x958A4A8F
            elseif katana_replace_index == 1 then
                katana_replace_model = 0x440E4788
            elseif katana_replace_index == 2 then
                katana_replace_model = 0xDD5DF8D9
            elseif katana_replace_index == 3 then
                katana_replace_model = 0x94117305
            end
            CFG:SaveItem("katana_replace_model", katana_replace_model)
            CFG:SaveItem("katana_replace_index", katana_replace_index)
            script.run_in_fiber(function(sw)
                if WEAPON.IS_PED_ARMED(Self.GetPedID(), 7) then
                    WEAPON.SET_CURRENT_PED_WEAPON(Self.GetPedID(), 0xA2719263, true)
                end
                sw:sleep(300)
                if WEAPON.HAS_PED_GOT_WEAPON(Self.GetPedID(), katana_replace_model, false) then
                    WEAPON.SET_CURRENT_PED_WEAPON(Self.GetPedID(), katana_replace_model, true)
                end
            end)
        end
    end

    laserSight, laserSightUSed = ImGui.Checkbox(_T("LASER_SIGHT_CB_"), laserSight)
    UI.Tooltip(_T("LASER_SIGHT_DESC_"))
    if laserSightUSed then
        CFG:SaveItem("laserSight", laserSight)
        UI.WidgetSound("Nav2")
    end
    if laserSight then
        ImGui.Text(_T("LASER_CHOICE_TXT_"))
        laser_switch, lsrswUsed = ImGui.RadioButton("Red", laser_switch, 0)
        ImGui.SameLine(); laser_switch, lsrswUsed_2 = ImGui.RadioButton("Green", laser_switch, 1)
        ImGui.SameLine(); laser_switch, lsrswUsed_3 = ImGui.RadioButton("Blue", laser_switch, 2)
        if lsrswUsed or lsrswUsed_2 or lsrswUsed_3 then
            UI.WidgetSound("Nav")
            if laser_switch == 0 then
                laser_choice = {
                    r = 237,
                    g = 47,
                    b = 50,
                }
            elseif laser_switch == 1 then
                laser_choice = {
                    r = 204,
                    g = 204,
                    b = 102,
                }
            else
                laser_choice = {
                    r = 20,
                    g = 75,
                    b = 159,
                }
            end
            CFG:SaveItem("laser_switch", laser_switch)
            CFG:SaveItem("laser_choice", laser_choice)
        end
    end
    ImGui.PopStyleVar()
    ImGui.EndChild()
end
