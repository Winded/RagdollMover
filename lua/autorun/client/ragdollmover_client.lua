
hook.Add("rgmInit", "rgmClientSetup", function()

	if ConVarExists("ragdollmover_lockselected") then -- i should use some lua variable instead of console variable so it would reset properly
		RunConsoleCommand("ragdollmover_lockselected", 0)
	end

	if ConVarExists("ragdollmover_rotatebutton") then
		local BindRot = GetConVar("ragdollmover_rotatebutton"):GetInt()

		if util.NetworkStringToID("RAGDOLLMOVER_META") ~= 0 then
			net.Start("RAGDOLLMOVER_META")
			net.WriteUInt(0, 1)
			net.WriteInt(BindRot, 8)
			net.SendToServer()
		end
	end

	if ConVarExists("ragdollmover_scalebutton") then
		local BindScale = GetConVar("ragdollmover_scalebutton"):GetInt()

		if util.NetworkStringToID("RAGDOLLMOVER_META") ~= 0 then
			net.Start("RAGDOLLMOVER_META")
			net.WriteUInt(1, 1)
			net.WriteInt(BindScale, 8)
			net.SendToServer()
		end
	end
end)
