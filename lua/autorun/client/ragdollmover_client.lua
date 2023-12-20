
local TYPE_ENTITY	 = 1
local TYPE_NUMBER	 = 2
local TYPE_VECTOR	 = 3
local TYPE_ANGLE	 = 4
local TYPE_BOOL		 = 5

local function SyncOneClient(self, name)
	if SERVER or not self.rgm then return end

	local v = self.rgm[name]
	if v == nil then return end

	net.Start("rgmSyncClient")

	net.WriteString(name)

	local Type = string.lower(type(v))
	if Type == "entity" then
		net.WriteUInt(TYPE_ENTITY, 3)
		net.WriteEntity(v)
	elseif Type == "number" then
		net.WriteUInt(TYPE_NUMBER, 3)
		net.WriteFloat(v)
	elseif Type == "vector" then
		net.WriteUInt(TYPE_VECTOR, 3)
		net.WriteVector(v)
	elseif Type == "angle" then
		net.WriteUInt(TYPE_ANGLE, 3)
		net.WriteAngle(v)
	elseif Type == "boolean" then
		net.WriteUInt(TYPE_BOOL, 3)
		net.WriteBit(v)
	end
	net.SendToServer()
end

hook.Add("InitPostEntity", "rgmClientSetup", function()
	local pl = LocalPlayer()

	pl.rgmSyncClient = SyncOneClient

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
