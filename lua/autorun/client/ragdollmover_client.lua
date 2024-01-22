
local TYPE_ENTITY	 = 1
local TYPE_NUMBER	 = 2
local TYPE_VECTOR	 = 3
local TYPE_ANGLE	 = 4
local TYPE_BOOL		 = 5

hook.Add("InitPostEntity", "rgmClientSetup", function()
	local pl = LocalPlayer()

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
