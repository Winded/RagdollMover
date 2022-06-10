
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

	local count = 1
	net.WriteInt(count, 32)

	net.WriteString(name)

	local Type = string.lower(type(v))
	if Type == "entity" then
		net.WriteInt(TYPE_ENTITY, 8)
		net.WriteEntity(v)
	elseif Type == "number" then
		net.WriteInt(TYPE_NUMBER, 8)
		net.WriteFloat(v)
	elseif Type == "vector" then
		net.WriteInt(TYPE_VECTOR, 8)
		net.WriteVector(v)
	elseif Type == "angle" then
		net.WriteInt(TYPE_ANGLE, 8)
		net.WriteAngle(v)
	elseif Type == "boolean" then
		net.WriteInt(TYPE_BOOL, 8)
		net.WriteBit(v)
	end
	net.SendToServer()
end

hook.Add("InitPostEntity", "rgmClientSetup", function()
	local pl = LocalPlayer()

	pl.rgmSyncClient = SyncOneClient

	if ConVarExists("ragdollmover_rotatebutton") then
		local BindRot = GetConVar("ragdollmover_rotatebutton"):GetInt()

		net.Start("rgmSetToggleRot")
		net.WriteInt(BindRot, 32)
		net.SendToServer()
	end

	if ConVarExists("ragdollmover_scalebutton") then
		local BindScale = GetConVar("ragdollmover_scalebutton"):GetInt()

		net.Start("rgmSetToggleScale")
		net.WriteInt(BindScale, 32)
		net.SendToServer()
	end
end)
