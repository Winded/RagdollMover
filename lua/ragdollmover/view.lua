if CLIENT then
    -- For developers: If you're wondering about the increased net cost all of a sudden if you've installed Ragdoll Mover,
    -- this is the cause. To preserve Ragdoll Mover's legacy systems without breaking anything, the view module is 
    -- meant to replace the view state depending on if the player is in third person or not

    local updateCVar = CreateConVar("ragdollmover_view_updateinterval", '0.01', {FCVAR_ARCHIVE, FCVAR_CHEAT}, "The window in seconds which a client equipped with Ragdoll Mover shall send its view", 0, 1)

    local EPSILON = 1e-3
    local lastCheck = CurTime()
    local function calcView(pl, origin, angles, fov, znear, zfar)
        local now = CurTime()
        if now - lastCheck < updateCVar:GetFloat() then return end
        lastCheck = now

        local weap = pl:GetActiveWeapon()
        local tool = pl:GetTool()
        local equipped = IsValid(weap) and weap:GetClass() == "gmod_tool" and tool and tool:GetMode() == "ragdollmover"
        if not equipped then return end

        local mainEyePos = origin
        local plEyePos = pl:EyePos()
        local offset = plEyePos - mainEyePos
        local offsetDiffers = offset:LengthSqr() >= EPSILON

        net.Start("rgmSendView", true)
        net.WriteDouble(mainEyePos[1])
        net.WriteDouble(mainEyePos[2])
        net.WriteDouble(mainEyePos[3])
        net.WriteAngle(angles)
        net.WriteBool(vgui.CursorVisible())
        net.WriteBool(offsetDiffers)
        net.SendToServer()
    end
    hook.Remove("CalcView", "rgmSendView")
    hook.Add("CalcView", "rgmSendView", calcView)
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