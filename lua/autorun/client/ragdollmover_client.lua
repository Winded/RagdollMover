
hook.Add("InitPostEntity", "rgmClientSetup", function()

	if ConVarExists("ragdollmover_rotatebutton") then
		local BindRot = GetConVar("ragdollmover_rotatebutton"):GetInt()

		if util.NetworkStringToID("rgmSetToggleRot") ~= 0 then
			net.Start("rgmSetToggleRot")
			net.WriteInt(BindRot, 8)
			net.SendToServer()
		end
	end

	if ConVarExists("ragdollmover_scalebutton") then
		local BindScale = GetConVar("ragdollmover_scalebutton"):GetInt()

		if util.NetworkStringToID("rgmSetToggleScale") ~= 0 then
			net.Start("rgmSetToggleScale")
			net.WriteInt(BindScale, 8)
			net.SendToServer()
		end
	end
end)
