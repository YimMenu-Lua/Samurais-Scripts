---@diagnostic disable: undefined-global, lowercase-global

local SelfGrid = GridRenderer:New(2, 25, 25)
SelfGrid:AddCheckbox(
    _T("AUTOHEAL_"),
    "Regen",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("AUTOHEAL_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    _T("CROUCHCB_"),
    "replaceSneakAnim",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("CROUCH_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    _T("REPLACE_PA_CB_"),
    "replacePointAct",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("REPLACE_PA_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    _T("PHONEANIMS_CB_"),
    "phoneAnim",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("PHONEANIMS_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    _T("SPRINT_INSIDE_CB_"),
    "sprintInside",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("SPRINT_INSIDE_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    _T("LOCKPICK_CB_"),
    "lockPick",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("LOCKPICK_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    _T("ACTION_MODE_CB_"),
    "disableActionMode",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("ACTION_MODE_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    "Clumsy",
    "clumsy",
    function()
        rod = false
        CFG:SaveItem("rod", false)
        if clumsy then
            script.run_in_fiber(function()
                if not PED.CAN_PED_RAGDOLL(Self.GetPedID()) then
                    YimToast:ShowWarning(
                        "Samurais Scripts",
                        "This option will not work if you're blocking ragdoll. Please make sure 'No Ragdoll' option is disabled in YimMennu."
                    )
                end
            end)
        end
    end,
    nil,
    true,
    function()
        UI.Tooltip(_T("CLUMSY_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    "Ragdoll On Demand",
    "rod",
    function()
        clumsy = false
        CFG:SaveItem("clumsy", false)
        if rod then
            script.run_in_fiber(function()
                if not PED.CAN_PED_RAGDOLL(Self.GetPedID()) then
                    YimToast:ShowWarning(
                        "Samurais Scripts",
                        "This option will not work if you're blocking ragdoll. Please make sure 'No Ragdoll' option is disabled in YimMennu."
                    )
                end
            end)
        end
    end,
    nil,
    true,
    function()
        UI.Tooltip(_T("ROD_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    "Ragdoll Sound",
    "ragdoll_sound",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("RAGDOLL_SOUND_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    "Hide & Seek",
    "hideFromCops",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("HIDENSEEK_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    _T("HATSINVEHS_CB_"),
    "hatsinvehs",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("HATSINVEHS_DESC_"))
    end
)

SelfGrid:AddCheckbox(
    _T("NOVEHRAGDOLL_CB_"),
    "novehragdoll",
    nil,
    nil,
    true,
    function()
        UI.Tooltip(_T("NOVEHRAGDOLL_DESC_"))
    end
)

function SelfUI()
    ImGui.BeginChild("SelfChild", 500, 500, true)
    SelfGrid:Draw()
    ImGui.EndChild()
end
