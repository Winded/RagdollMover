
--[[
	Other functionality that isn't part of the rgm module.
]]

local MAX_EDICT_BITS = 13

local TYPE_ENTITY	 = 1
local TYPE_NUMBER	 = 2
local TYPE_VECTOR	 = 3
local TYPE_ANGLE	 = 4
local TYPE_BOOL		 = 5

RAGDOLLMOVER = RAGDOLLMOVER or {}

local shouldCallHook = false
hook.Add("EntityKeyValue", "RGMAllowTool", function(ent, key, val)
	-- I couldn't find a clean, direct way to add ragdollmover to the m_tblToolsAllowed for both
	-- loading into a map or loading a save on the same map.
	if key == "gmod_allowtools" and not string.find(val, "ragdollmover") then
		shouldCallHook = true
	end

	-- We can't call the hook at the same time the key is gmod_allowtools because ent.m_tblToolsAllowed 
	-- must exist (which relies on the gmod_allowtools key), but it doesn't yet
	if shouldCallHook and key ~= "gmod_allowtools" then
		hook.Run("RGMAllowTool", ent)
		shouldCallHook = false
	end
end)

-- Some brush entities only allow a select number of tools (see https://wiki.facepunch.com/gmod/Sandbox_Specific_Mapping)
-- Without this, the gizmos would not be "selectable"
hook.Add("RGMAllowTool", "RGMAllowTool", function(ent)
	-- If the table is not filled, we don't want to insert it, as it would make other tools not work
	if istable(ent.m_tblToolsAllowed) and #ent.m_tblToolsAllowed > 0 then
		table.insert(ent.m_tblToolsAllowed, "ragdollmover")
	end
end)

if SERVER then

resource.AddWorkshop("104575630")

util.AddNetworkString("RAGDOLLMOVER_META")

hook.Add("PlayerSpawn", "rgmSpawn", function(pl) --PlayerSpawn is a hook that runs only serverside btw
	if not RAGDOLLMOVER[pl] then
		RAGDOLLMOVER[pl] = {}
		RAGDOLLMOVER[pl].rgmPosLocks = {}
		RAGDOLLMOVER[pl].rgmAngLocks = {}
		RAGDOLLMOVER[pl].rgmBoneLocks = {}
		RAGDOLLMOVER[pl].rgmEntLocks = {}
		RAGDOLLMOVER[pl].rgmPhysMove = {}
		RAGDOLLMOVER[pl].Rotate = false
		RAGDOLLMOVER[pl].Scale = false
		RAGDOLLMOVER[pl].GizmoOffset = Vector(0, 0, 0)
		RAGDOLLMOVER[pl].PropRagdoll = false
		RAGDOLLMOVER[pl].PlViewEnt = 0
	end
end)

local NumpadBindRot, NumpadBindScale = {}, {}
local RotKey, ScaleKey = {}, {}
local rgmMode = {}

hook.Add("PlayerDisconnected", "RGMCleanupGizmos", function(pl)
	if IsValid(RAGDOLLMOVER[pl].Axis) then
		RAGDOLLMOVER[pl].Axis:Remove()
	end
	if NumpadBindRot[pl] then numpad.Remove(NumpadBindRot[pl]) end
	if NumpadBindScale[pl] then numpad.Remove(NumpadBindScale[pl]) end
	RAGDOLLMOVER[pl] = nil
end)

if game.SinglePlayer() then

saverestore.AddSaveHook("RGMbinds", function(save)
	saverestore.WriteTable(NumpadBindRot, save)
	saverestore.WriteTable(NumpadBindScale, save)
end)

saverestore.AddRestoreHook("RGMbinds", function(save)
	NumpadBindRot = saverestore.ReadTable(save)
	NumpadBindScale = saverestore.ReadTable(save)
end)

end

function RAGDOLLMOVER.Sync(pl, ...)
	if CLIENT or not RAGDOLLMOVER[pl] then return end

	net.Start("RAGDOLLMOVER_META") -- rgmSync

	local arg = {...}
	local count = #arg
	net.WriteInt(count, 4)

	for k, v in ipairs(arg) do
		net.WriteString(v)

		local val = RAGDOLLMOVER[pl][v]

		local Type = string.lower(type(val))
		if Type == "entity" then
			net.WriteUInt(TYPE_ENTITY, 3)
			net.WriteUInt(val:EntIndex(), MAX_EDICT_BITS)
		elseif Type == "number" then
			net.WriteUInt(TYPE_NUMBER, 3)
			net.WriteFloat(val)
		elseif Type == "vector" then
			net.WriteUInt(TYPE_VECTOR, 3)
			net.WriteVector(val)
		elseif Type == "angle" then
			net.WriteUInt(TYPE_ANGLE, 3)
			net.WriteAngle(val)
		elseif Type == "boolean" then
			net.WriteUInt(TYPE_BOOL, 3)
			net.WriteBit(val)
		end
	end

	net.Send(pl)
end

local NETFUNC = {

	function(len, pl) -- 1 - rgmSetToggleRot
		local key = net.ReadInt(8)
		if not key then return end

		RotKey[pl] = key
		if NumpadBindRot[pl] then numpad.Remove(NumpadBindRot[pl]) end
		NumpadBindRot[pl] = numpad.OnDown(pl, key, "rgmAxisChangeStateRot")
	end,

	function(len, pl) -- 2 - rgmSetToggleScale
		local key = net.ReadInt(8)
		if not key then return end

		ScaleKey[pl] = key
		if NumpadBindScale[pl] then numpad.Remove(NumpadBindScale[pl]) end
		NumpadBindScale[pl] = numpad.OnDown(pl, key, "rgmAxisChangeStateScale")
	end

}

net.Receive("RAGDOLLMOVER_META", function(len, pl)
	NETFUNC[net.ReadUInt(1) + 1](len, pl)
end)

numpad.Register("rgmAxisChangeStateRot", function(pl)
	if not RAGDOLLMOVER[pl] then RAGDOLLMOVER[pl] = {} end
	if not rgmMode[pl] then rgmMode[pl] = 1 end

	if not pl:GetTool() or RAGDOLLMOVER[pl].Moving then return end
	if pl:GetTool().Mode ~= "ragdollmover" or pl:GetActiveWeapon():GetClass() ~= "gmod_tool" then return end
	if RotKey[pl] == ScaleKey[pl] then
		rgmMode[pl] = rgmMode[pl] + 1
		if rgmMode[pl] > 3 then rgmMode[pl] = 1 end

		RAGDOLLMOVER[pl].Rotate = rgmMode[pl] == 2
		RAGDOLLMOVER[pl].Scale = rgmMode[pl] == 3
	else
		RAGDOLLMOVER[pl].Rotate = not RAGDOLLMOVER[pl].Rotate
		RAGDOLLMOVER[pl].Scale = false
	end

	RAGDOLLMOVER.Sync(pl, "Rotate", "Scale")
	return true
end)

numpad.Register("rgmAxisChangeStateScale", function(pl)
	if not RAGDOLLMOVER[pl] then RAGDOLLMOVER[pl] = {} end

	if not pl:GetTool() or RAGDOLLMOVER[pl].Moving then return end
	if pl:GetTool().Mode ~= "ragdollmover" or pl:GetActiveWeapon():GetClass() ~= "gmod_tool" then return end
	if RotKey[pl] == ScaleKey[pl] then return end
	RAGDOLLMOVER[pl].Scale = not RAGDOLLMOVER[pl].Scale
	RAGDOLLMOVER[pl].Rotate = false

	RAGDOLLMOVER.Sync(pl, "Rotate", "Scale")
	return true
end)

elseif CLIENT then

local buffer = {}

net.Receive("RAGDOLLMOVER_META", function(len) -- rgmSync
	local count = net.ReadInt(4)

	for i = 1, count do
		local name = net.ReadString()

		local type = net.ReadUInt(3)
		local value = nil
		if type == TYPE_ENTITY then
			value = {net.ReadUInt(MAX_EDICT_BITS)}
		elseif type == TYPE_NUMBER then
			value = net.ReadFloat()
		elseif type == TYPE_VECTOR then
			value = net.ReadVector()
		elseif type == TYPE_ANGLE then
			value = net.ReadAngle()
		elseif type == TYPE_BOOL then
			value = net.ReadBit() == 1
		end

		buffer[name] = value
	end
end)

local pl = LocalPlayer()

hook.Remove("Think", "rgmClientBuffer") -- for hotloading

hook.Add("InitPostEntity", "rgmMetaInitPlayer", function()
	pl = LocalPlayer()
	if not RAGDOLLMOVER[pl] then RAGDOLLMOVER[pl] = {} end

	hook.Add("Think", "rgmClientBuffer", function()
		if IsValid(pl) and not RAGDOLLMOVER[pl] then RAGDOLLMOVER[pl] = {} end

		if next(buffer) then
			for name, value in pairs(buffer) do
				if not istable(value) then
					RAGDOLLMOVER[pl][name] = value
				else
					RAGDOLLMOVER[pl][name] = (Entity(value[1]))
				end
			end
			buffer = {}
		end
	end)
end)

end
