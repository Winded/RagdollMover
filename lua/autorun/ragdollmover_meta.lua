
--[[
	Other functionality that isn't part of the rgm module.
]]

resource.AddSingleFile("resource/localization/en/ragdollmover_tools.properties")
resource.AddSingleFile("resource/localization/en/ragdollmover_ui.properties")

local MAX_EDICT_BITS = 13

local TYPE_ENTITY	 = 1
local TYPE_NUMBER	 = 2
local TYPE_VECTOR	 = 3
local TYPE_ANGLE	 = 4
local TYPE_BOOL		 = 5

RAGDOLLMOVER = {}

if SERVER then

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

hook.Add("PlayerDisconnected", "RGMCleanupGizmos", function(pl)
	if IsValid(RAGDOLLMOVER[pl].Axis) then
		RAGDOLLMOVER[pl].Axis:Remove()
	end
	RAGDOLLMOVER[pl] = nil
end)

local NumpadBindRot, NumpadBindScale = {}, {}
local RotKey, ScaleKey = {}, {}
local rgmMode = {}

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

	if not pl:GetTool() then return end
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

	if not pl:GetTool() then return end
	if pl:GetTool().Mode ~= "ragdollmover" or pl:GetActiveWeapon():GetClass() ~= "gmod_tool" then return end
	if RotKey[pl] == ScaleKey[pl] then return end
	RAGDOLLMOVER[pl].Scale = not RAGDOLLMOVER[pl].Scale
	RAGDOLLMOVER[pl].Rotate = false

	RAGDOLLMOVER.Sync(pl, "Rotate", "Scale")
	return true
end)

elseif CLIENT then

net.Receive("RAGDOLLMOVER_META", function(len) -- rgmSync
	local pl = LocalPlayer()

	-- See edge case explanation below
	if IsValid(pl) and not RAGDOLLMOVER[pl] then RAGDOLLMOVER[pl] = {} end

	local count = net.ReadInt(4)

	for i = 1, count do
		local name = net.ReadString()

		local type = net.ReadUInt(3)
		local value = nil
		if type == TYPE_ENTITY then
			-- Read the entity index instead of the entity itself, so we can do our own validation step later
			value = net.ReadUInt(MAX_EDICT_BITS)
		elseif type == TYPE_NUMBER then
			value = net.ReadFloat()
		elseif type == TYPE_VECTOR then
			value = net.ReadVector()
		elseif type == TYPE_ANGLE then
			value = net.ReadAngle()
		elseif type == TYPE_BOOL then
			value = net.ReadBit() == 1
		end

		-- Sometimes, entities are not available during startup in multiplayer.   
		if type == TYPE_ENTITY then
			timer.Create("RAGDOLLMOVER_VALIDATE_ENTITY", 0.1, 10, function()
				-- Edge case: If ragdollmover is already deployed on the player in the server, then the net.Receive callback calls,
				-- but the local player is not initialized. We can initialize pl here and also set the RAGDOLLMOVER[pl]
				-- table
				pl = LocalPlayer()
				if not RAGDOLLMOVER[pl] then RAGDOLLMOVER[pl] = {} end

				if IsValid(Entity(value)) and IsValid(pl) then
					RAGDOLLMOVER[pl][name] = Entity(value)
					timer.Remove("RAGDOLLMOVER_VALIDATE_ENTITY")
				end
			end)
		else
			RAGDOLLMOVER[pl][name] = value
		end
	end
end)

end
