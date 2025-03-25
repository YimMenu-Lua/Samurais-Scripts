---@diagnostic disable

function weaponUI()
    HashGrabber, HgUsed = ImGui.Checkbox(_T("HASHGRABBER_CB_"), HashGrabber)
    UI.helpMarker(false, _T("HASHGRABBER_DESC_"))
    if HgUsed then
        UI.widgetSound("Nav2")
    end

    Triggerbot, TbUsed = ImGui.Checkbox(_T("TRIGGERBOT_CB_"), Triggerbot)
    UI.helpMarker(false, _T("TRIGGERBOT_DESC_"))
    if TbUsed then
        CFG:SaveItem("Triggerbot", Triggerbot)
        UI.widgetSound("Nav2")
    end

    if Triggerbot then
        ImGui.SameLine(); aimEnemy, aimEnemyUsed = ImGui.Checkbox(_T("ENEMY_ONLY_CB_"), aimEnemy)
        if aimEnemyUsed then
            CFG:SaveItem("aimEnemy", aimEnemy)
            UI.widgetSound("Nav2")
        end
    end

    MagicBullet, mbUsed = ImGui.Checkbox(_T("MAGIC_BULLET_CB_"), MagicBullet)
    UI.helpMarker(false, _T("MAGIC_BULLET_DESC_"))
    if mbUsed then
        CFG:SaveItem("MagicBullet", MagicBullet)
        UI.widgetSound("Nav2")
    end

    autoKill, autoKillUsed = ImGui.Checkbox(_T("AUTOKILL_CB_"), autoKill)
    UI.helpMarker(false, _T("AUTOKILL_DESC_"))
    if autoKillUsed then
        CFG:SaveItem("autoKill", autoKill)
        UI.widgetSound("Nav2")
    end

    runaway, runawayUsed = ImGui.Checkbox(_T("ENEMIES_FLEE_CB_"), runaway)
    UI.helpMarker(false, _T("ENEMIES_FLEE_DESC_"))
    if runawayUsed then
        CFG:SaveItem("runaway", runaway)
        UI.widgetSound("Nav2")
        if runaway then
            publicEnemy = false
        end
    end

    replace_pool_q, rpqUsed = ImGui.Checkbox(_T("KATANA_CB_"), replace_pool_q)
    UI.helpMarker(false, _T("KATANA_DESC_"))
    if rpqUsed then
        CFG:SaveItem("replace_pool_q", replace_pool_q)
        UI.widgetSound("Nav2")
    end

    if replace_pool_q then
        ImGui.Text(_T("KATANA_WPN_CHOICE_TXT_")); ImGui.SameLine(); ImGui.SetNextItemWidth(140)
        katana_replace_index, kriUsed = ImGui.Combo("##kri", katana_replace_index,
            { "Baseball Bat", "Golf Club", "Machete", "Pool Que" }, 4)
        UI.toolTip(false, _T("KATANA_WPN_CHOICE_DESC_"))
        if kriUsed then
            UI.widgetSound("Nav")
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
                if WEAPON.IS_PED_ARMED(self.get_ped(), 7) then
                    WEAPON.SET_CURRENT_PED_WEAPON(self.get_ped(), 0xA2719263, true)
                end
                sw:sleep(300)
                if WEAPON.HAS_PED_GOT_WEAPON(self.get_ped(), katana_replace_model, false) then
                    WEAPON.SET_CURRENT_PED_WEAPON(self.get_ped(), katana_replace_model, true)
                end
            end)
        end
    end

    laserSight, laserSightUSed = ImGui.Checkbox(_T("LASER_SIGHT_CB_"), laserSight)
    UI.helpMarker(false, _T("LASER_SIGHT_DESC_"))
    if laserSightUSed then
        CFG:SaveItem("laserSight", laserSight)
        UI.widgetSound("Nav2")
    end
    if laserSight then
        ImGui.Text(_T("LASER_CHOICE_TXT_"))
        laser_switch, lsrswUsed = ImGui.RadioButton("Red", laser_switch, 0)
        ImGui.SameLine(); laser_switch, lsrswUsed_2 = ImGui.RadioButton("Green", laser_switch, 1)
        ImGui.SameLine(); laser_switch, lsrswUsed_3 = ImGui.RadioButton("Blue", laser_switch, 2)
        if lsrswUsed or lsrswUsed_2 or lsrswUsed_3 then
            UI.widgetSound("Nav")
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
end
