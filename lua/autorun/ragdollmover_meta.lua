
--[[
	Other functionality that isn't part of the rgm module.
]]

resource.AddSingleFile("resource/localization/en/ragdollmover_tools.properties")

local TYPE_ENTITY	 = 1
local TYPE_NUMBER	 = 2
local TYPE_VECTOR	 = 3
local TYPE_ANGLE	 = 4
local TYPE_BOOL		 = 5

local function Sync(self)
	if CLIENT or not self.rgm then return end

	net.Start("rgmSync")

	local count = table.Count(self.rgm)
	net.WriteInt(count, 32)

	for k, v in pairs(self.rgm) do
		net.WriteString(k)

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
	end

	net.Send(self)
end

local function SyncOne(self, name)
	if CLIENT or not self.rgm then return end

	local v = self.rgm[name]
	if v == nil then return end

	net.Start("rgmSync")

	local count = 1
	net.WriteInt(count, 32)

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

	net.Send(self)
end

hook.Add("PlayerSpawn", "rgmSpawn", function(pl) --PlayerSpawn is a hook that runs only serverside btw
	if not pl.rgm then
		pl.rgm = {}
		pl.rgmPosLocks = {}
		pl.rgmAngLocks = {}
		pl.rgmBoneLocks = {}
		pl.rgmEntLocks = {}
		pl.rgm.Rotate = false
		pl.rgm.Scale = false
		pl.rgm.GizmoOffset = Vector(0, 0, 0)
		pl.rgm.PropRagdoll = false
	end

	if not pl.rgmSync or not pl.rgmSyncOne then
		pl.rgmSync = Sync
		pl.rgmSyncOne = SyncOne
	end
end)

if SERVER then

util.AddNetworkString("rgmSync")

else

net.Receive("rgmSync", function(len)
	local pl = LocalPlayer()
	if not pl.rgm then pl.rgm = {} end

	local count = net.ReadInt(32)

	for i=1, count do
		local name = net.ReadString()

		local type = net.ReadUInt(3)
		local value = nil
		if type == TYPE_ENTITY then
			value = net.ReadEntity()
		elseif type == TYPE_NUMBER then
			value = net.ReadFloat()
		elseif type == TYPE_VECTOR then
			value = net.ReadVector()
		elseif type == TYPE_ANGLE then
			value = net.ReadAngle()
		elseif type == TYPE_BOOL then
			value = net.ReadBit() == 1
		end
		pl.rgm[name] = value
	end
end)

end
