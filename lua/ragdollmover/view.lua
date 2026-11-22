if CLIENT then
    local function rgmSendView()
        local pl = LocalPlayer()
        if not IsValid(pl) then return end
        local weap = pl:GetActiveWeapon()
        local tool = pl:GetTool()
        local equipped = IsValid(weap) and weap:GetClass() == "gmod_tool" and tool and tool:GetMode() == "ragdollmover"
        if not equipped then return end

        local eyePos = MainEyePos()

        net.Start("rgmSendView", true)
        net.WriteDouble(eyePos[1])
        net.WriteDouble(eyePos[2])
        net.WriteDouble(eyePos[3])
        net.WriteAngle(MainEyeAngles())
        net.WriteBool(vgui.CursorVisible())
        net.WriteBool(eyePos ~= pl:EyePos())
        net.SendToServer()
    end
    timer.Remove("rgmSendView")
    timer.Create("rgmSendView", 0.1, 0, rgmSendView)
    hook.Add("rgmInit", "rgmSendView", function ()        
        timer.Create("rgmSendView", 0.1, 0, rgmSendView)
    end)
else
    RAGDOLLMOVER_VIEWS = {}

    hook.Add("SetupMove", "rgmAddView", function (pl)
        if not RAGDOLLMOVER_VIEWS[pl] then
            RAGDOLLMOVER_VIEWS[pl] = {Vector(), Angle(), false, false}
        end
    end)

    hook.Add("PlayerDisconnected", "rgmClearView", function(pl)
        RAGDOLLMOVER_VIEWS[pl] = nil
    end)

    util.AddNetworkString("rgmSendView")
    net.Receive("rgmSendView", function (len, ply)
        local eyePosX = net.ReadDouble()
        local eyePosY = net.ReadDouble()
        local eyePosZ = net.ReadDouble()
        local eyeVec = net.ReadAngle()
        local cursorVisible = net.ReadBool()
        local inThirdPerson = net.ReadBool()
        RAGDOLLMOVER_VIEWS[ply][1]:SetUnpacked(eyePosX, eyePosY, eyePosZ)
        RAGDOLLMOVER_VIEWS[ply][2]:Set(eyeVec)
        RAGDOLLMOVER_VIEWS[ply][3] = cursorVisible
        RAGDOLLMOVER_VIEWS[ply][4] = inThirdPerson
    end)
end