
TOOL.Name = "#tool.ragdollmover.name"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["localpos"] = 0
TOOL.ClientConVar["localang"] = 1
TOOL.ClientConVar["localoffset"] = 1
TOOL.ClientConVar["relativerotate"] = 0
TOOL.ClientConVar["scale"] = 10
TOOL.ClientConVar["width"] = 0.5
TOOL.ClientConVar["fulldisc"] = 0
TOOL.ClientConVar["disablefilter"] = 0
TOOL.ClientConVar["lockselected"] = 0
TOOL.ClientConVar["scalechildren"] = 0
TOOL.ClientConVar["drawskeleton"] = 0
TOOL.ClientConVar["snapenable"] = 0
TOOL.ClientConVar["snapamount"] = 30

TOOL.ClientConVar["ik_leg_L"] = 0
TOOL.ClientConVar["ik_leg_R"] = 0
TOOL.ClientConVar["ik_hand_L"] = 0
TOOL.ClientConVar["ik_hand_R"] = 0
TOOL.ClientConVar["ik_chain_1"] = 0
TOOL.ClientConVar["ik_chain_2"] = 0
TOOL.ClientConVar["ik_chain_3"] = 0
TOOL.ClientConVar["ik_chain_4"] = 0
TOOL.ClientConVar["ik_chain_5"] = 0
TOOL.ClientConVar["ik_chain_6"] = 0
TOOL.ClientConVar["hipkneeroll"] = 3
TOOL.ClientConVar["ignoredaxis"] = 3

TOOL.ClientConVar["unfreeze"] = 0
TOOL.ClientConVar["updaterate"] = 0.01

TOOL.ClientConVar["rotatebutton"] = MOUSE_MIDDLE
TOOL.ClientConVar["scalebutton"] = MOUSE_RIGHT

local ConstrainedAllowed

local RGM_NOTIFY = {
	BONELOCK_FAILED = {id = 0, iserror = true},
	BONELOCK_SUCCESS = {id = 1, iserror = false},
	BONELOCK_FAILED_NOTPHYS = {id = 2, iserror = true},
	BONELOCK_FAILED_SAME = {id = 3, iserror = true},
	ENTLOCK_FAILED_NONPHYS = {id = 4, iserror = true},
	ENTLOCK_FAILED_NOTALLOWED = {id = 5,iserror = true},
	ENTLOCK_SUCCESS = {id = 6, iserror = false},
	ENTSELECT_LOCKRESPONSE = {id = 20, iserror = true},
}

local function RGMGetBone(pl, ent, bone)
	--------------------------------------------------------- yeah this part is from locrotscale
	local phys, physobj
	pl.rgm.IsPhysBone = false

	local count = ent:GetPhysicsObjectCount()
	local isragdoll = ent:GetClass() == "prop_ragdoll"

	for i = 0, count - 1 do
		local b = ent:TranslatePhysBoneToBone(i)
		if bone == b then 
			phys = i
			pl.rgm.IsPhysBone = true
		end
	end

	if count == 1 then
		if not isragdoll and bone == 0 then
			phys = 0
			pl.rgm.IsPhysBone = true
		end
	end
	---------------------------------------------------------
	local bonen = phys or bone

	pl.rgm.PhysBone = bonen
	if pl.rgm.IsPhysBone and isragdoll then -- physics props only have 1 phys object which is tied to bone -1, and that bone doesn't really exist
		pl.rgm.Bone = ent:TranslatePhysBoneToBone(bonen)
	else
		pl.rgm.Bone = bonen
	end
end

local function rgmFindEntityChildren(parent)
	local children = {}

	local function RecursiveFindChildren(entity)
		for k, ent in pairs(entity:GetChildren()) do
			if not IsValid(ent) or ent:IsWorld() or ent:IsConstraint() or not isstring(ent:GetModel()) or not util.IsValidModel(ent:GetModel()) then continue end

			table.insert(children, ent)
			RecursiveFindChildren(ent)
		end
	end

	RecursiveFindChildren(parent)

	return children
end

local function rgmGetConstrainedEntities(parent)
	local conents = {}
	local children = {}

	conents = constraint.GetAllConstrainedEntities(parent)
	conents[parent] = nil
	if parent.rgmPRidtoent then
		for k, ent in pairs(parent.rgmPRidtoent) do
			conents[ent] = nil
		end
	end

	local count = 1

	for _, ent in pairs(conents) do
		if not IsValid(ent) or ent:IsWorld() or ent:IsConstraint() or not util.IsValidModel(ent:GetModel()) or IsValid(ent:GetParent()) then continue end
		if ent:GetPhysicsObjectCount() > 0 then
			children[count] = ent
			count = count + 1
		end
	end

	return children
end

if SERVER then

util.AddNetworkString("rgmUpdateLists")

util.AddNetworkString("rgmUpdateEntInfo")

util.AddNetworkString("rgmAskForPhysbones")
util.AddNetworkString("rgmAskForPhysbonesResponse")
util.AddNetworkString("rgmAskForNodeUpdatePhysics")
util.AddNetworkString("rgmAskForNodeUpdatePhysicsResponse")

util.AddNetworkString("rgmAskForParented")
util.AddNetworkString("rgmAskForParentedResponse")

util.AddNetworkString("rgmSelectBone")
util.AddNetworkString("rgmSelectBoneResponse")

util.AddNetworkString("rgmLockBone")
util.AddNetworkString("rgmLockBoneResponse")
util.AddNetworkString("rgmLockToBone")
util.AddNetworkString("rgmLockToBoneResponse")
util.AddNetworkString("rgmUnlockToBone")
util.AddNetworkString("rgmUnlockToBoneResponse")
util.AddNetworkString("rgmLockConstrained")
util.AddNetworkString("rgmLockConstrainedResponse")
util.AddNetworkString("rgmUnlockConstrained")

util.AddNetworkString("rgmSelectEntity")

util.AddNetworkString("rgmResetGizmo")
util.AddNetworkString("rgmOperationSwitch")
util.AddNetworkString("rgmSetGizmoToBone")
util.AddNetworkString("rgmUpdateGizmo")

util.AddNetworkString("rgmResetAll")
util.AddNetworkString("rgmResetPos")
util.AddNetworkString("rgmResetAng")
util.AddNetworkString("rgmResetScale")
util.AddNetworkString("rgmScaleZero")
util.AddNetworkString("rgmAdjustBone")
util.AddNetworkString("rgmGizmoOffset")

util.AddNetworkString("rgmUpdateSliders")

util.AddNetworkString("rgmNotification")

ConstrainedAllowed = CreateConVar("sv_ragdollmover_allow_constrained_locking", 1, FCVAR_ARCHIVE + FCVAR_NOTIFY, "Allow usage of locking constrained entities to Ragdoll Mover's selected entity (Can be abused by attempting to move a lot of entities)", 0, 1)

net.Receive("rgmAskForPhysbones", function(len, pl)
	local entcount = net.ReadUInt(13)
	local ents = {}

	for i = 1, entcount do
		ents[i] = net.ReadEntity()
	end

	if not next(ents) then return end
	local sendents = {}

	for i, ent in ipairs(ents) do
		if not IsValid(ent) then continue end
		local count = ent:GetPhysicsObjectCount() - 1
		if count ~= -1 then
			table.insert(sendents, ent)
		end
	end

	net.Start("rgmAskForPhysbonesResponse")
	net.WriteUInt(#sendents, 13)
	for _, ent in ipairs(sendents) do
		net.WriteEntity(ent)

		local count = ent:GetPhysicsObjectCount() - 1
		net.WriteUInt(count, 8)
		for i = 0, count do
			local bone = ent:TranslatePhysBoneToBone(i)
			if bone == -1 then bone = 0 end
			local poslock = pl.rgmPosLocks[ent] and pl.rgmPosLocks[ent][i] or nil
			local anglock = pl.rgmAngLocks[ent] and pl.rgmAngLocks[ent][i] or nil
			local bonelock = pl.rgmBoneLocks[ent] and pl.rgmBoneLocks[ent][i] or nil

			net.WriteUInt(bone, 8)
			net.WriteBool(poslock ~= nil)
			net.WriteBool(anglock ~= nil)
			net.WriteBool(bonelock ~= nil)
		end
	end
	net.Send(pl)
end)

net.Receive("rgmAskForNodeUpdatePhysics", function(len, pl)
	local isphys = net.ReadBool()
	local entcount = net.ReadUInt(13)
	local reents, ents = {}, {}

	for i = 1, entcount do
		reents[i] = net.ReadEntity()
	end

	local validcount = 0
	for i, ent in ipairs(reents) do
		if not IsValid(ent) then continue end
		validcount = validcount + 1
		ents[validcount] = ent
	end

	if not next(ents) then return end

	net.Start("rgmAskForNodeUpdatePhysicsResponse")
		net.WriteBool(isphys)
		net.WriteUInt(validcount, 13)
		for i, ent in ipairs(ents) do
			net.WriteEntity(ent)

			local count = ent:GetPhysicsObjectCount()
			net.WriteUInt(count, 8)
			if count ~= 0 then
				for i = 0, count - 1 do
					local bone = ent:TranslatePhysBoneToBone(i)
					if bone == -1 then bone = 0 end
					net.WriteUInt(bone, 8)
				end
			end

		end
	net.Send(pl)
end)

net.Receive("rgmAskForParented", function(len, pl)
	local entcount = net.ReadUInt(13)
	local ents = {}

	for i = 1, entcount do
		ents[i] = net.ReadEntity()
	end

	local parented = {}
	local pcount = 0

	for _, ent in ipairs(ents) do
		if not IsValid(ent) or not IsValid(ent:GetParent()) then continue end

		parented[ent] = {}
		pcount = pcount + 1

		for i = 0, ent:GetBoneCount() - 1 do
			if ent:GetParent():LookupBone(ent:GetBoneName(i)) then
				table.insert(parented[ent], i)
			end
		end
	end

	if next(parented) then
		net.Start("rgmAskForParentedResponse")
			net.WriteUInt(pcount, 13)
			for ent, bones in pairs(parented) do
				net.WriteEntity(ent)
				net.WriteUInt(#bones, 10)
				for k, id in ipairs(bones) do
					net.WriteUInt(id, 10)
				end
			end
		net.Send(pl)
	end
end)

net.Receive("rgmSelectBone", function(len, pl)
	local ent = net.ReadEntity()
	local bone = net.ReadUInt(10)

	pl.rgm.BoneToResetTo = (ent:GetClass() == "prop_ragdoll") and ent:TranslatePhysBoneToBone(0) or 0
	pl.rgm.Entity = ent
	RGMGetBone(pl, ent, bone)
	pl:rgmSync()

	net.Start("rgmSelectBoneResponse")
		net.WriteBool(pl.rgm.IsPhysBone)
		net.WriteEntity(ent)
		net.WriteUInt(pl.rgm.Bone, 10)
	net.Send(pl)
end)

net.Receive("rgmLockBone", function(len, pl)
	local ent = net.ReadEntity()
	local mode = net.ReadUInt(2)
	local bone = net.ReadUInt(10)
	local physbone = bone
	local boneid

	if not IsValid(ent) or ent:TranslateBoneToPhysBone(physbone) == -1 then return end
	if ent:GetClass() ~= "prop_ragdoll" and not ent.rgmPRenttoid then return end

	if ent:GetClass() == "prop_ragdoll" then
		physbone = rgm.BoneToPhysBone(ent,bone)
		boneid = physbone
	else
		boneid = ent.rgmPRenttoid[ent]
	end

	if mode == 1 then
		if not pl.rgmPosLocks[ent][boneid] then
			pl.rgmPosLocks[ent][boneid] = ent:GetPhysicsObjectNum(physbone)
		else
			pl.rgmPosLocks[ent][boneid] = nil
		end
	elseif mode == 2 then
		if not pl.rgmAngLocks[ent][boneid] then
			pl.rgmAngLocks[ent][boneid] = ent:GetPhysicsObjectNum(physbone)
		else
			pl.rgmAngLocks[ent][boneid] = nil
		end
	end

	local poslock, anglock = IsValid(pl.rgmPosLocks[ent][boneid]), IsValid(pl.rgmAngLocks[ent][boneid])

	net.Start("rgmLockBoneResponse")
		net.WriteEntity(ent)
		net.WriteUInt(bone, 10)
		net.WriteBool(poslock)
		net.WriteBool(anglock)
	net.Send(pl)
end)

local function RecursiveFindIfParent(ent, lockbone, locktobone)
	local parent = ent:GetBoneParent(locktobone)
	if parent then
		if parent == lockbone then
			return true
		elseif parent == -1 then
			return false
		else
			return RecursiveFindIfParent(ent, lockbone, parent)
		end
	end
end

local function RecursiveFindIfParentPropRagdoll(parentent, childent)
	local parent = childent.rgmPRparent
	if not parent then return false end

	parent = childent.rgmPRidtoent[parent]
	if parent == parentent then
		return true
	else
		return RecursiveFindIfParentPropRagdoll(parentent, parent)
	end
end

net.Receive("rgmLockToBone", function(len, pl)
	local lockent = net.ReadEntity()
	local lockedbone = net.ReadUInt(10)
	local originent = net.ReadEntity()
	local lockorigin = net.ReadUInt(10)

	if not IsValid(lockent) or not IsValid(originent) or not ((lockent:GetClass() == "prop_ragdoll") or (lockent:GetClass() == "prop_physics")) or not ((originent:GetClass() == "prop_ragdoll") or (originent:GetClass() == "prop_physics")) then return end
	if lockent.rgmPRenttoid then
		lockedbone = lockent.rgmPRenttoid[lockent]
	end
	if originent.rgmPRenttoid then
		lockorigin = originent.rgmPRenttoid[originent]
	end


	local physcheck = not lockent.rgmPRenttoid and (not rgm.BoneToPhysBone(lockent, lockedbone) or not rgm.BoneToPhysBone(originent, lockorigin))
	local samecheck = lockedbone == lockorigin

	if physcheck or samecheck then
		local err = samecheck and RGM_NOTIFY.BONELOCK_FAILED_SAME.id or RGM_NOTIFY.BONELOCK_FAILED_NOTPHYS.id

		net.Start("rgmNotification")
			net.WriteUInt(err, 5)
		net.Send(pl)
		return
	end

	if lockent == originent then
		if not RecursiveFindIfParent(lockent, lockedbone, lockorigin) then
			local bone = rgm.BoneToPhysBone(lockent,lockedbone)
			lockorigin = rgm.BoneToPhysBone(lockent,lockorigin)

			pl.rgmBoneLocks[lockent][bone] = { id = lockorigin, ent = lockent }
			pl.rgmPosLocks[lockent][bone] = nil
			pl.rgmAngLocks[lockent][bone] = nil

			net.Start("rgmLockToBoneResponse")
				net.WriteEntity(lockent)
				net.WriteUInt(lockedbone, 10)
			net.Send(pl)
		else
			net.Start("rgmNotification")
				net.WriteUInt(RGM_NOTIFY.BONELOCK_FAILED.id, 5)
			net.Send(pl)
		end
	else
		if not RecursiveFindIfParentPropRagdoll(lockent, originent) then
			pl.rgmBoneLocks[lockent][lockedbone] = { id = lockorigin, ent = originent }
			pl.rgmPosLocks[lockent][lockedbone] = nil
			pl.rgmAngLocks[lockent][lockedbone] = nil

			net.Start("rgmLockToBoneResponse")
				net.WriteEntity(lockent)
				net.WriteUInt(0, 10)
			net.Send(pl)
		else
			net.Start("rgmNotification")
				net.WriteUInt(RGM_NOTIFY.BONELOCK_FAILED.id, 5)
			net.Send(pl)
		end
	end
end)

net.Receive("rgmUnlockToBone", function(len, pl)
	local ent = net.ReadEntity()
	local unlockbone = net.ReadUInt(10)
	local bone = rgm.BoneToPhysBone(ent,unlockbone)

	if ent.rgmPRenttoid then
		bone = ent.rgmPRenttoid[ent]
	end

	pl.rgmBoneLocks[ent][bone] = nil

	net.Start("rgmUnlockToBoneResponse")
		net.WriteEntity(ent)
		net.WriteUInt(unlockbone, 10)
	net.Send(pl)
end)

net.Receive("rgmLockConstrained", function(len, pl)
	local ent = net.ReadEntity()
	local lockent = net.ReadEntity()
	local physbone = 0

	local convar = ConstrainedAllowed:GetBool()
	if not convar then
		net.Start("rgmNotification")
			net.WriteUInt(RGM_NOTIFY.ENTLOCK_FAILED_NOTALLOWED.id, 5)
		net.Send(pl)
		return
	end

	if not IsValid(ent) or not IsValid(lockent) then return end

	if net.ReadBool() then
		local boneid = net.ReadUInt(8)

		if not ent.rgmPRenttoid then
			if not rgm.BoneToPhysBone(ent, boneid) then
				net.Start("rgmNotification")
					net.WriteUInt(RGM_NOTIFY.ENTLOCK_FAILED_NONPHYS.id, 5)
				net.Send(pl)
				return
			end

			physbone = rgm.BoneToPhysBone(ent, boneid)
		else
			physbone = ent.rgmPRenttoid[ent]
		end
	end

	pl.rgmEntLocks[lockent] = {id = physbone, ent = ent}

	net.Start("rgmLockConstrainedResponse")
		net.WriteBool(true)
		net.WriteEntity(lockent)
	net.Send(pl)
end)

net.Receive("rgmUnlockConstrained", function(len, pl)
	local lockent = net.ReadEntity()

	if not IsValid(lockent) then return end

	pl.rgmEntLocks[lockent] = nil

	net.Start("rgmLockConstrainedResponse")
		net.WriteBool(false)
		net.WriteEntity(lockent)
	net.Send(pl)
end)

net.Receive("rgmSelectEntity", function(len, pl)
	local ent = net.ReadEntity()

	if net.ReadBool() then
		net.Start("rgmNotification")
			net.WriteUInt(RGM_NOTIFY.ENTSELECT_LOCKRESPONSE.id, 5)
		net.Send(pl)
		return
	end

	if not IsValid(ent) then return end

	pl.rgm.Entity = ent
	pl.rgm.BoneToResetTo = (ent:GetClass() == "prop_ragdoll") and ent:TranslatePhysBoneToBone(0) or 0
	pl.rgmPosLocks = {}
	pl.rgmAngLocks = {}
	pl.rgmBoneLocks = {}

	if ent.rgmPRidtoent then
		for id, e in pairs(ent.rgmPRidtoent) do
			pl.rgmPosLocks[e] = {}
			pl.rgmAngLocks[e] = {}
			pl.rgmBoneLocks[e] = {}
		end
	else
		pl.rgmPosLocks[ent] = {}
		pl.rgmAngLocks[ent] = {}
		pl.rgmBoneLocks[ent] = {}
	end

	pl.rgmEntLocks = {}

	if not ent.rgmbonecached then -- also taken from locrotscale. some hacky way to cache the bones?
		local p = pl.rgmSwep:GetParent()
		pl.rgmSwep:FollowBone(ent, 0)
		pl.rgmSwep:SetParent(p)
		ent.rgmbonecached = true
	end

	RGMGetBone(pl, ent, 0)
	pl:rgmSync()

	local physchildren = rgmGetConstrainedEntities(ent)

	net.Start("rgmUpdateEntInfo")
		net.WriteEntity(ent)

		net.WriteUInt(#physchildren, 13)
		for _, ent in ipairs(physchildren) do
			net.WriteEntity(ent)
		end
	net.Send(pl)
end)

net.Receive("rgmResetGizmo", function(len, pl)
	if not pl.rgm then return end
	pl.rgm.GizmoOffset:Set(vector_origin)

	net.Start("rgmUpdateGizmo")
	net.WriteVector(pl.rgm.GizmoOffset)
	net.Send(pl)
end)

net.Receive("rgmOperationSwitch", function(len, pl)
	local tool = pl:GetTool("ragdollmover")
	if not tool then return end

	tool:SetOperation(1)
end)

net.Receive("rgmSetGizmoToBone", function(len, pl)
	local vector = net.ReadVector()
	if not vector or not pl.rgm then return end
	local axis = pl.rgm.Axis
	local ent = pl.rgm.Entity

	if ent:GetClass() == "prop_ragdoll" and pl.rgm.IsPhysBone then
		ent = ent:GetPhysicsObjectNum(pl.rgm.PhysBone)
	end

	if axis.localizedoffset then
		vector = WorldToLocal(vector, angle_zero, ent:GetPos(), ent:GetAngles())
	else
		vector = WorldToLocal(vector, angle_zero, ent:GetPos(), angle_zero)
	end

	pl.rgm.GizmoOffset = vector

	net.Start("rgmUpdateGizmo")
	net.WriteVector(pl.rgm.GizmoOffset)
	net.Send(pl)
end)

local function RecursiveBoneFunc(bone, ent, func, param)
	func(bone, param)

	for _, id in ipairs(ent:GetChildBones(bone)) do
		RecursiveBoneFunc(id, ent, func, param)
	end
end

net.Receive("rgmResetAll", function(len, pl)
	local ent = net.ReadEntity()
	local bone = net.ReadUInt(10)
	local children = net.ReadBool()

	if not IsValid(ent) then return end

	if children then
		RecursiveBoneFunc(bone, ent, function(bon)
			ent:ManipulateBonePosition(bon, vector_origin)
			ent:ManipulateBoneAngles(bon, angle_zero)
			ent:ManipulateBoneScale(bon, Vector(1, 1, 1))
		end)
	else
		ent:ManipulateBonePosition(bone, vector_origin)
		ent:ManipulateBoneAngles(bone, angle_zero)
		ent:ManipulateBoneScale(bone, Vector(1, 1, 1))
	end

	net.Start("rgmUpdateSliders")
	net.Send(pl)
end)

net.Receive("rgmResetPos", function(len, pl)
	local ent = net.ReadEntity()
	local children = net.ReadBool()
	local bone = net.ReadUInt(10)

	if not IsValid(ent) then return end

	if children then
		RecursiveBoneFunc(bone, ent, function(bone, param) ent:ManipulateBonePosition(bone, param) end, vector_origin)
	else
		ent:ManipulateBonePosition(bone, vector_origin)
	end

	net.Start("rgmUpdateSliders")
	net.Send(pl)
end)

net.Receive("rgmResetAng", function(len, pl)
	local ent = net.ReadEntity()
	local children = net.ReadBool()
	local bone = net.ReadUInt(10)

	if children then
		RecursiveBoneFunc(bone, ent, function(bone, param) ent:ManipulateBoneAngles(bone, param) end, angle_zero)
	else
		ent:ManipulateBoneAngles(bone, angle_zero)
	end

	net.Start("rgmUpdateSliders")
	net.Send(pl)
end)

net.Receive("rgmResetScale", function(len, pl)
	local ent = net.ReadEntity()
	local children = net.ReadBool()
	local bone = net.ReadUInt(10)

	if children then
		RecursiveBoneFunc(bone, ent, function(bone, param) ent:ManipulateBoneScale(bone, param) end, Vector(1, 1, 1))
	else
		ent:ManipulateBoneScale(bone, Vector(1, 1, 1))
	end

	net.Start("rgmUpdateSliders")
	net.Send(pl)
end)

net.Receive("rgmScaleZero", function(len, pl)
	local ent = net.ReadEntity()
	local children = net.ReadBool()
	local bone = net.ReadUInt(10)

	if children then
		RecursiveBoneFunc(bone, ent, function(bone, param) ent:ManipulateBoneScale(bone, param) end, vector_origin)
	else
		ent:ManipulateBoneScale(bone, vector_origin)
	end

	net.Start("rgmUpdateSliders")
	net.Send(pl)
end)

net.Receive("rgmAdjustBone", function(len, pl)
	local ManipulateBone = {}
	local ent = pl.rgm.Entity
	if not IsValid(ent) then return end

	ManipulateBone[1] = function(axis, value)
		local Change = ent:GetManipulateBonePosition(pl.rgm.Bone)
		Change[axis] = value

		ent:ManipulateBonePosition(pl.rgm.Bone, Change)
	end

	ManipulateBone[2] = function(axis, value)
		local Change = ent:GetManipulateBoneAngles(pl.rgm.Bone)
		Change[axis] = value

		ent:ManipulateBoneAngles(pl.rgm.Bone, Change)
	end

	ManipulateBone[3] = function(axis, value)
		local rgmaxis, bone = pl.rgm.Axis, pl.rgm.Bone
		local PrevScale = ent:GetManipulateBoneScale(bone)
		local Change = ent:GetManipulateBoneScale(bone)
		Change[axis] = value

		if rgmaxis.scalechildren then
			local scalediff = Change - PrevScale

			local function RecursiveBoneScale(ent, bone, scale)
				local oldscale = ent:GetManipulateBoneScale(bone)
				ent:ManipulateBoneScale(bone, oldscale + scale)

				for _, cbone in ipairs(ent:GetChildBones(bone)) do
					RecursiveBoneScale(ent, cbone, scale)
				end
			end

			RecursiveBoneScale(ent, bone, scalediff)
		else
			ent:ManipulateBoneScale(bone, Change)
		end
	end

	local mode, axis, value = net.ReadInt(3), net.ReadInt(3), net.ReadFloat()

	ManipulateBone[mode](axis, value)
end)

net.Receive("rgmGizmoOffset", function(len, pl)
	local axis = net.ReadUInt(3)
	local value = net.ReadFloat()

	pl.rgm.GizmoOffset[axis] = value
end)

hook.Add("PlayerDisconnected", "RGMCleanupGizmos", function(pl)
	if IsValid(pl.rgm.Axis) then
		pl.rgm.Axis:Remove()
	end
end)

end

concommand.Add("ragdollmover_resetroot", function(pl)
	if not IsValid(pl.rgm.Entity) then return end
	local bone = pl.rgm.Bone

	RGMGetBone(pl, pl.rgm.Entity, pl.rgm.BoneToResetTo)
	pl.rgm.BoneToResetTo = bone

	pl:rgmSync()

	net.Start("rgmSelectBoneResponse")
		net.WriteBool(pl.rgm.IsPhysBone)
		net.WriteEntity(pl.rgm.Entity)
		net.WriteUInt(pl.rgm.Bone, 10)
	net.Send(pl)
end)

function TOOL:Deploy()
	if SERVER then
		local pl = self:GetOwner()
		local axis = pl.rgm.Axis
		if not IsValid(axis) then
			axis = ents.Create("rgm_axis")
			axis:Spawn()
			axis.Owner = pl
			pl.rgm.Axis = axis
		end
	end
end

local function EntityFilter(ent)
	return (ent:GetClass() == "prop_ragdoll" or ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_effect") or (GetConVar("ragdollmover_disablefilter"):GetBool() and not ent:IsWorld())
end

function TOOL:LeftClick(tr)

	if self:GetOperation() == 1 then

		if SERVER then
			local pl = self:GetOwner()
			local axis, ent = pl.rgm.Axis, pl.rgm.Entity

			if not IsValid(axis) or not IsValid(ent) then self:SetOperation(0) return true end
			local offset = tr.HitPos

			if ent:GetClass() == "prop_ragdoll" and pl.rgm.IsPhysBone then
				ent = ent:GetPhysicsObjectNum(pl.rgm.PhysBone)
			elseif ent:GetClass() == "prop_physics" then
				ent = ent:GetPhysicsObjectNum(0)
			end

			if axis.localizedoffset then
				offset = WorldToLocal(offset, angle_zero, ent:GetPos(), ent:GetAngles())
			else
				offset = WorldToLocal(offset, angle_zero, ent:GetPos(), angle_zero)
			end

			pl.rgm.GizmoOffset = offset

			net.Start("rgmUpdateGizmo")
			net.WriteVector(pl.rgm.GizmoOffset)
			net.Send(pl)
		end

		self:SetOperation(0)
		return true

	end

	if CLIENT then return false end

	local pl = self:GetOwner()

	if pl.rgm.Moving then return false end

	local axis = pl.rgm.Axis
	if not IsValid(axis) then
		pl:ChatPrint("Axis entity isn't found. Spawning new one, try selecting the entity again.")
		axis = ents.Create("rgm_axis")
		axis:Spawn()
		axis.Owner = pl
		pl.rgm.Axis = axis
		return false
	end
	if not axis.Axises then
		axis:Setup()
	end

	local collision = axis:TestCollision(pl,self:GetClientNumber("scale",10))
	local ent = pl.rgm.Entity

	if collision and IsValid(ent) then

		if _G["physundo"] and _G["physundo"].Create then
			_G["physundo"].Create(ent,pl)
		end

		local apart = collision.axis

		pl.rgmISPos = collision.hitpos*1
		pl.rgmISDir = apart:GetAngles():Forward()

		pl.rgmOffsetPos = WorldToLocal(apart:GetPos(),apart:GetAngles(),collision.hitpos,apart:GetAngles())

		local opos = apart:WorldToLocal(collision.hitpos)
		local obj = ent:GetPhysicsObjectNum(pl.rgm.PhysBone)
		local grabang = apart:LocalToWorldAngles(Angle(0,0,Vector(opos.y,opos.z,0):Angle().y))
		local _p
		if obj then 
			_p,pl.rgmOffsetAng = WorldToLocal(apart:GetPos(),obj:GetAngles(),apart:GetPos(),grabang)
			pl.rgmOffsetTable = rgm.GetOffsetTable(self, ent, pl.rgm.Rotate, pl.rgmBoneLocks, pl.rgmEntLocks)
		end
		if IsValid(ent:GetParent()) and not (ent:GetClass() == "prop_ragdoll") then -- ragdolls don't seem to care about parenting
			local pang = ent:GetParent():LocalToWorldAngles(ent:GetLocalAngles())
			_, pl.rgmOffsetAng = WorldToLocal(apart:GetPos(),pang,apart:GetPos(),grabang)
		end

		pl.rgm.StartAngle = WorldToLocal(collision.hitpos, angle_zero, apart:GetPos(), apart:GetAngles())
		if ent:GetClass() ~= "prop_ragdoll" and pl.rgm.IsPhysBone then
			pl.rgm.Bone = 0
		end
		pl.rgm.NPhysBonePos = ent:GetManipulateBonePosition(pl.rgm.Bone)
		pl.rgm.NPhysBoneAng = ent:GetManipulateBoneAngles(pl.rgm.Bone)
		pl.rgm.NPhysBoneScale = ent:GetManipulateBoneScale(pl.rgm.Bone)

		local ignore = { pl }

		if ent.rgmPRidtoent then
			for id, e in pairs(ent.rgmPRidtoent) do
				table.insert(ignore, e)
			end
		else
			ignore[2] = ent
		end

		local function FindRecursiveIfParent(findid, id, ent)
			if ent.rgmPRidtoent then
				if ent.rgmPRparent then
					if ent.rgmPRparent == findid then return true end
					return FindRecursiveIfParent(findid, ent.rgmPRparent, ent.rgmPRidtoent[ent.rgmPRparent])
				else
					return false
				end
			else
				local parent = rgm.GetPhysBoneParent(ent, id)
				if parent then
					if parent == findid then return true end
					return FindRecursiveIfParent(findid, parent, ent)
				else
					return false
				end
			end
		end

		if pl.rgm.IsPhysBone then
			for lockent, data in pairs(pl.rgmEntLocks) do
				if FindRecursiveIfParent(data.id, pl.rgm.PhysBone, ent) then continue end
				table.insert(ignore, lockent)
			end
		end

		pl.rgm.Ignore = ignore

		local dirnorm = (collision.hitpos-axis:GetPos())
		dirnorm:Normalize()
		pl.rgm.DirNorm = dirnorm
		pl.rgm.MoveAxis = apart
		pl.rgm.KeyDown = true
		pl.rgm.Moving = true
		pl:rgmSync()
		return false

	elseif IsValid(tr.Entity) and EntityFilter(tr.Entity) then

		local entity = tr.Entity

		if entity ~= pl.rgm.Entity and self:GetClientNumber("lockselected") ~= 0 then
			net.Start("rgmNotification")
				net.WriteUInt(RGM_NOTIFY.ENTSELECT_LOCKRESPONSE.id, 5)
			net.Send(pl)
			return false
		end

		pl.rgm.Entity = entity

		if not entity.rgmbonecached then -- also taken from locrotscale. some hacky way to cache the bones?
			pl.rgmSwep = self.SWEP
			local p = self.SWEP:GetParent()
			self.SWEP:FollowBone(entity, 0)
			self.SWEP:SetParent(p)
			entity.rgmbonecached = true
		end

		RGMGetBone(pl, entity, entity:TranslatePhysBoneToBone(tr.PhysicsBone))
		pl.rgm.BoneToResetTo = (entity:GetClass() == "prop_ragdoll") and entity:TranslatePhysBoneToBone(0) or 0 -- used for quickswitching to root bone and back

		if ent ~= entity and (not entity.rgmPRenttoid or not entity.rgmPRenttoid[ent]) then
			local children = rgmFindEntityChildren(entity)
			local physchildren = rgmGetConstrainedEntities(entity)
			pl.rgm.PropRagdoll = entity.rgmPRidtoent and true or false

			net.Start("rgmUpdateLists")
				net.WriteBool(pl.rgm.PropRagdoll)
				if pl.rgm.PropRagdoll then
					local rgment = pl.rgm.Entity
					local count = #rgment.rgmPRidtoent + 1

					net.WriteUInt(count, 13) -- technically entity limit is 4096, but doubtful single prop ragdoll would reach that, but still...

					for id, ent in pairs(rgment.rgmPRidtoent) do
						net.WriteEntity(ent)
						net.WriteUInt(id, 13)

						net.WriteBool(ent.rgmPRparent and true or false)
						if ent.rgmPRparent then
							net.WriteUInt(ent.rgmPRparent, 13)
						end

						if ent == entity then
							net.WriteUInt(0, 13)
							continue
						end

						local entchildren = rgmFindEntityChildren(ent)
						net.WriteUInt(#entchildren, 13)

						for k, v in ipairs(entchildren) do
							net.WriteEntity(v)
						end
					end
				end

				net.WriteEntity(entity)

				net.WriteUInt(#children, 13)
				for k, v in ipairs(children) do
					net.WriteEntity(v)
				end

				net.WriteUInt(#physchildren, 13)
				for _, ent in ipairs(physchildren) do
					net.WriteEntity(ent)
				end
			net.Send(pl)

			pl.rgmPosLocks = {}
			pl.rgmAngLocks = {}
			pl.rgmBoneLocks = {}

			if entity.rgmPRidtoent then
				for id, ent in pairs(entity.rgmPRidtoent) do
					pl.rgmPosLocks[ent] = {}
					pl.rgmAngLocks[ent] = {}
					pl.rgmBoneLocks[ent] = {}
				end
			else
				pl.rgmPosLocks[entity] = {}
				pl.rgmAngLocks[entity] = {}
				pl.rgmBoneLocks[entity] = {}
			end

			pl.rgmEntLocks = {}
		end

		pl:rgmSync()

		net.Start("rgmSelectBoneResponse")
			net.WriteBool(pl.rgm.IsPhysBone)
			net.WriteEntity(pl.rgm.Entity)
			net.WriteUInt(pl.rgm.Bone, 10)
		net.Send(pl)
	end

	return false
end

function TOOL:RightClick(tr)

	if self:GetOperation() == 1 then

		if SERVER then
			local pl = self:GetOwner()
			local axis = pl.rgm.Axis
			local ent, rgment = tr.Entity, pl.rgm.Entity
			local offset

			if not IsValid(axis) or not IsValid(rgment) then self:SetOperation(0) return true end

			if IsValid(ent) then
				local object = ent:GetPhysicsObjectNum(tr.PhysicsBone)
				if not object then object = ent end
				offset = object:GetPos()
			else
				offset = tr.HitPos
			end

			if rgment:GetClass() == "prop_ragdoll" and pl.rgm.IsPhysBone then
				rgment = rgment:GetPhysicsObjectNum(pl.rgm.PhysBone)
			elseif rgment:GetClass() == "prop_physics" then
				rgment = rgment:GetPhysicsObjectNum(0)
			end

			if axis.localizedoffset then
				offset = WorldToLocal(offset, angle_zero, rgment:GetPos(), rgment:GetAngles())
			else
				offset = WorldToLocal(offset, angle_zero, rgment:GetPos(), angle_zero)
			end

			pl.rgm.GizmoOffset = offset

			net.Start("rgmUpdateGizmo")
			net.WriteVector(pl.rgm.GizmoOffset)
			net.Send(pl)
		end

		self:SetOperation(0)
		return true

	end

	return false
end

function TOOL:Reload()
	if CLIENT then return false end
	if self:GetOperation() == 1 then
		self:SetOperation(0)
		return false
	end

	local pl = self:GetOwner()
		RunConsoleCommand("ragdollmover_resetroot")
	return false
end

function TOOL:Think()
	if CLIENT then
		local pl = self:GetOwner()
		if not pl.rgm then return end

		if pl.rgm.Moving then return end -- don't want to keep updating this stuff when we move stuff, so it'll go smoother

		local ent, axis = pl.rgm.Entity, pl.rgm.Axis -- so, this thing... bone position and angles seem to work clientside best, whereas server's ones are kind of shite
		if IsValid(ent) and IsValid(axis) and pl.rgm.Bone then
			local bone = pl.rgm.Bone
			local pos, ang = ent:GetBonePosition(bone)
			if pos == ent:GetPos() then
				local matrix = ent:GetBoneMatrix(bone)
				pos = matrix:GetTranslation()
				ang = matrix:GetAngles()
			end
			if ent:GetBoneParent(bone) ~= -1 then
				local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
				local ang = matrix:GetAngles()
				pl.rgm.GizmoParent = ang
			else
				pl.rgm.GizmoParent = nil
			end

			pl.rgm.GizmoPos = pos
			pl.rgm.GizmoAng = ang
			pl:rgmSyncClient("GizmoPos")
			pl:rgmSyncClient("GizmoAng")
			pl:rgmSyncClient("GizmoParent")
		else
			pl.rgm.GizmoPos = nil
			pl.rgm.GizmoAng = nil
			pl.rgm.GizmoParent = nil
			pl:rgmSyncClient("GizmoPos")
			pl:rgmSyncClient("GizmoAng")
			pl:rgmSyncClient("GizmoParent")
		end
	end

if SERVER then

	if not self.LastThink then self.LastThink = CurTime() end
	if CurTime() < self.LastThink + self:GetClientNumber("updaterate",0.01) then return end

	local pl = self:GetOwner()
	local ent = pl.rgm.Entity

	local axis = pl.rgm.Axis
	if IsValid(axis) then
		if axis.localizedpos ~= (self:GetClientNumber("localpos",1) ~= 0) then
			axis.localizedpos = (self:GetClientNumber("localpos",1) ~= 0)
		end
		if axis.localizedang ~= (self:GetClientNumber("localang",1) ~= 0) then
			axis.localizedang = (self:GetClientNumber("localang",1) ~= 0)
		end
		if axis.localizedoffset ~= (self:GetClientNumber("localoffset",1) ~= 0) then
			axis.localizedoffset = (self:GetClientNumber("localoffset",1) ~= 0)
		end
		if axis.relativerotate ~= (self:GetClientNumber("relativerotate",1) ~= 0) then
			axis.relativerotate = (self:GetClientNumber("relativerotate",1) ~= 0)
		end
		if axis.scalechildren ~= (self:GetClientNumber("scalechildren",1) ~= 0) then
			axis.scalechildren = (self:GetClientNumber("scalechildren",1) ~= 0)
		end
	end

	local moving = pl.rgm.Moving or false
	local rotate = pl.rgm.Rotate or false
	local scale = pl.rgm.Scale or false
	if moving then

		if not pl:KeyDown(IN_ATTACK) then

			if pl.rgm.IsPhysBone then
				if self:GetClientNumber("unfreeze",1) > 0 then
					for i=0,ent:GetPhysicsObjectCount()-1 do
						if pl.rgmOffsetTable[i].moving then
							local obj = ent:GetPhysicsObjectNum(i)
							obj:EnableMotion(true)
							obj:Wake()
						end
						if pl.rgmOffsetTable[i].locked and ConstrainedAllowed:GetBool() then
							for lockent, bonetable in pairs(pl.rgmOffsetTable[i].locked) do
								for j=0, lockent:GetPhysicsObjectCount()-1 do
									if  bonetable[j].moving then
										local obj = lockent:GetPhysicsObjectNum(j)
										obj:EnableMotion(true)
										obj:Wake()
									end
								end
							end
						end
					end
				end
			end

			pl.rgm.Moving = false
			pl:rgmSyncOne("Moving")
			net.Start("rgmUpdateSliders")
			net.Send(pl)
			return
		end

		if not IsValid(axis) then return end

		local eyepos,eyeang = rgm.EyePosAng(pl)

		local apart = pl.rgm.MoveAxis
		local bone = pl.rgm.PhysBone

		if not IsValid(ent) then
			pl.rgm.Moving = false
			return
		end

		local snapamount = 0
		if self:GetClientNumber("snapenable",0) ~= 0 then
			snapamount = self:GetClientNumber("snapamount", 1)
			snapamount = snapamount < 1 and 1 or snapamount
		end

		local tracepos = nil
		if pl:KeyDown(IN_SPEED) then

			local tr = util.TraceLine({
				start = pl:EyePos(),
				endpos = pl:EyePos() + pl:GetAimVector()*4096,
				filter = pl.rgm.Ignore
			})
			tracepos = tr.HitPos
		end

		local physbonecount = ent:GetBoneCount() - 1
		if physbonecount == nil then return end

		if not scale then
			if IsValid(ent:GetParent()) and bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not (ent:GetClass() == "prop_ragdoll") then -- is parented
				local pos, ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir,0,snapamount,pl.rgm.StartAngle,nil,nil,nil,tracepos)
				ent:SetLocalPos(pos)
				ent:SetLocalAngles(ang)

			elseif pl.rgm.IsPhysBone then -- moving physbones
				local isik,iknum = rgm.IsIKBone(self,ent,bone)

				local pos,ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir,1,snapamount,pl.rgm.StartAngle,nil,nil,nil,tracepos)

				local physcount = ent:GetPhysicsObjectCount()-1
				if pl.rgm.PropRagdoll then
					physcount = #ent.rgmPRidtoent
					bone = ent.rgmPRenttoid[ent]
				end

				local obj = ent:GetPhysicsObjectNum(pl.rgm.PropRagdoll and 0 or bone)
				if not isik or iknum == 3 or (rotate and (iknum == 1 or iknum == 2)) then
					obj:EnableMotion(true)
					obj:Wake()
					obj:SetPos(pos)
					obj:SetAngles(ang)
					obj:EnableMotion(false)
					obj:Wake()
				elseif iknum == 2 then
					for k,v in pairs(ent.rgmIKChains) do
						if v.knee == bone or (ent.rgmPRidtoent and ent.rgmPRidtoent[v.knee] == ent) then
							local intersect = apart:GetGrabPos(eyepos,eyeang)
							local obj1
							local obj2

							if not pl.rgm.PropRagdoll then
								obj1 = ent:GetPhysicsObjectNum(v.hip)
								obj2 = ent:GetPhysicsObjectNum(v.foot)
							else
								obj1 = ent.rgmPRidtoent[v.hip]:GetPhysicsObjectNum(0)
								obj2 = ent.rgmPRidtoent[v.foot]:GetPhysicsObjectNum(0)
							end

							local kd = (intersect-(obj2:GetPos()+(obj1:GetPos()-obj2:GetPos())))
							kd:Normalize()
							ent.rgmIKChains[k].ikkneedir = kd*1
						end
					end
				end

				local postable = rgm.SetOffsets(self,ent,pl.rgmOffsetTable,{b = bone,p = obj:GetPos(),a = obj:GetAngles()}, pl.rgmAngLocks, pl.rgmPosLocks)

				if not isik or iknum ~= 2 then
					postable[bone].dontset = true
				end

				for i=0, physcount do
					if postable[i] and not postable[i].dontset then
						local ent = not pl.rgm.PropRagdoll and ent or ent.rgmPRidtoent[i]
						local boneid = not pl.rgm.PropRagdoll and i or 0

						local obj = ent:GetPhysicsObjectNum(boneid)

	--					local poslen = postable[i].pos:Length()
	--					local anglen = Vector(postable[i].ang.p,postable[i].ang.y,postable[i].ang.r):Length()

						--Temporary solution for INF and NaN decimals crashing the game (Even rounding doesnt fix it)
	--					if poslen > 2 and anglen > 2 then
							obj:EnableMotion(true)
							obj:Wake()
							obj:SetPos(postable[i].pos)
							obj:SetAngles(postable[i].ang)
							obj:EnableMotion(false)
							obj:Wake()
	--					end
					end

					if postable[i] and postable[i].locked and ConstrainedAllowed:GetBool() then
						for lockent, bones in pairs(postable[i].locked) do
							for j=0,lockent:GetPhysicsObjectCount()-1 do
								if bones[j] then
									local obj = lockent:GetPhysicsObjectNum(j)
	--								local poslen = bones[j].pos:Length()
	--								local anglen = Vector(bones[j].ang.p,bones[j].ang.y,bones[j].ang.r):Length()

									--Temporary solution for INF and NaN decimals crashing the game (Even rounding doesnt fix it)
	--								if poslen > 2 and anglen > 2 then
										obj:EnableMotion(true)
										obj:Wake()
										obj:SetPos(bones[j].pos)
										obj:SetAngles(bones[j].ang)
										obj:EnableMotion(false)
										obj:Wake()
	--								end

								end
							end
						end
					end
				end


				-- if not pl:GetNWBool("ragdollmover_keydown") then
			else -- moving nonphysbones
				local pos, ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir,2,snapamount,pl.rgm.StartAngle,pl.rgm.NPhysBonePos,pl.rgm.NPhysBoneAng,nil,tracepos) -- if a bone is not physics one, we pass over "start angle" thing

				ent:ManipulateBoneAngles(bone, ang)
				ent:ManipulateBonePosition(bone, pos)
			end
		else -- scaling
			bone = pl.rgm.Bone
			local prevscale = ent:GetManipulateBoneScale(bone)
			local sc, ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir,2,snapamount,pl.rgm.StartAngle,pl.rgm.NPhysBonePos,pl.rgm.NPhysBoneAng,pl.rgm.NPhysBoneScale)

			if axis.scalechildren then
				local scalediff = sc - prevscale

				local function RecursiveBoneScale(ent, bone, scale)
					local oldscale = ent:GetManipulateBoneScale(bone)
					ent:ManipulateBoneScale(bone, oldscale + scale)

					for _, cbone in ipairs(ent:GetChildBones(bone)) do
						RecursiveBoneScale(ent, cbone, scale)
					end
				end

				RecursiveBoneScale(ent, bone, scalediff)
			else
				ent:ManipulateBoneScale(bone, sc)
			end

		end

	end

	local tr = pl:GetEyeTrace()
	if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_ragdoll" then
		local b = tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone)
		pl.rgm.AimedBone = b
		pl:rgmSyncOne("AimedBone")
	end

	self.LastThink = CurTime()

end

end

if CLIENT then

	TOOL.Information = {
		{ name = "left_gizmomode", op = 1 },
		{ name = "right_gizmomode", op = 1 },
		{ name = "reload_gizmomode", op = 1 },
		{ name = "left_default", op = 0 },
		{ name = "info_default", op = 0 },
		{ name = "reload_default", op = 0 },
	}

local BONE_PHYSICAL = 1
local BONE_NONPHYSICAL = 2
local BONE_PROCEDURAL = 3
local BONE_PARENTED = 4

local function GetRecursiveBones(ent, boneid, tab, depth)
	for k, v in ipairs(ent:GetChildBones(boneid)) do
		local bone = {id = v, Type = BONE_NONPHYSICAL, parent = boneid, depth = depth + 1}

		if ent:BoneHasFlag(v, 4) then -- BONE_ALWAYS_PROCEDURAL flag
			bone.Type = BONE_PROCEDURAL
		end

		table.insert(tab, bone)
		GetRecursiveBones(ent, v, tab, bone.depth)
	end
end

local function GetRecursiveBonesExclusive(ent, boneid, lastvalidbone, tab, physcheck, isphys, depth)
	for k, v in ipairs(ent:GetChildBones(boneid)) do
		local bone = {id = v, Type = BONE_NONPHYSICAL, parent = lastvalidbone, depth = depth + 1}
		local newlastvalid = lastvalidbone

		if ent:BoneHasFlag(v, 4) then -- BONE_ALWAYS_PROCEDURAL flag
			bone.Type = BONE_PROCEDURAL
		end
		if physcheck[v] then
			bone.Type = BONE_PHYSICAL
		end

		if (isphys and bone.Type == BONE_PHYSICAL) or (not isphys and bone.Type ~= BONE_PHYSICAL) then 
			newlastvalid = v
			table.insert(tab, bone)
		end

		GetRecursiveBonesExclusive(ent, v, newlastvalid, tab, physcheck, isphys, bone.depth)
	end
end

local function GetRecursiveEntities(ents, parentid, parentent, tab, depth)
	for ent, data in pairs(ents) do
		if data.parent == parentid then
			local entdata = { ent = ent, id = data.id, parent = parentent, depth = depth + 1 }

			table.insert(tab, entdata)
			GetRecursiveEntities(ents, entdata.id, ent, tab, entdata.depth)
		end
	end
end

local function GetModelName(ent)
	local name = ent:GetModel()
	local splitname = string.Split(name, "/")
	return splitname[#splitname]
end

local function CCheckBox(cpanel,text,cvar)
	local CB = vgui.Create("DCheckBoxLabel",cpanel)
	CB:SetText(text)
	CB:SetConVar(cvar)
	CB:SetDark(true)
	cpanel:AddItem(CB)
	return CB
end
local function CNumSlider(cpanel,text,cvar,min,max,dec)
	local SL = vgui.Create("DNumSlider",cpanel)
	SL:SetText(text)
	SL:SetDecimals(dec)
	SL:SetMinMax(min,max)
	SL:SetConVar(cvar)
	SL:SetDark(true)

	cpanel:AddItem(SL)

	return SL
end
local function CManipSlider(cpanel, text, mode, axis, min, max, dec, textentry)
	local slider = vgui.Create("DNumSlider",cpanel)
	slider:SetText(text)
	slider:SetDecimals(dec)
	slider:SetMinMax(min,max)
	slider:SetDark(true)
	slider:SetValue(0)
	if mode == 3 then
		slider:SetDefaultValue(1)
	else
		slider:SetDefaultValue(0)
	end

	function slider:OnValueChanged(value)
		if ManipSliderUpdating or self.busy then return end
		self.busy = true
		net.Start("rgmAdjustBone")
		net.WriteInt(mode, 3)
		net.WriteInt(axis, 3)
		net.WriteFloat(value)
		net.SendToServer()

		textentry:SetValue(math.Round(textentry.Sliders[1]:GetValue(), 2) .. " " .. math.Round(textentry.Sliders[2]:GetValue(), 2) .. " " .. math.Round(textentry.Sliders[3]:GetValue(), 2))
		self.busy = false
	end

	cpanel:AddItem(slider)

	return slider
end
local function CManipEntry(cpanel, mode)
	local entry = vgui.Create("DTextEntry", cpanel, slider1, slider2, slider3)
	entry:SetValue("0 0 0")
	entry:SetUpdateOnType(true)
	entry.OnValueChange = function(self, value)
		if ManipSliderUpdating or self.busy then return end
		self.busy = true

		local values = string.Explode(" ", value)
		for i = 1, 3 do
			if values[i] and tonumber(values[i]) and IsValid(entry.Sliders[i]) then
				entry.Sliders[i]:SetValue(tonumber(values[i]))
			end
		end
		self.busy = false
	end

	entry.Sliders = {}

	cpanel:AddItem(entry)

	return entry
end
local function CGizmoSlider(cpanel, text, axis, min, max, dec)
	local slider = vgui.Create("DNumSlider", cpanel)
	slider:SetText(text)
	slider:SetDecimals(dec)
	slider:SetMinMax(min,max)
	slider:SetDark(true)
	slider:SetValue(0)
	slider:SetDefaultValue(0)

	function slider:OnValueChanged(value)
		net.Start("rgmGizmoOffset")
		net.WriteInt(axis, 3)
		net.WriteFloat(value)
		net.SendToServer()
	end

	cpanel:AddItem(slider)

	return slider
end
local function CButton(cpanel, text, func, arg)
	local butt = vgui.Create("DButton", cpanel)
	butt:SetText(text)
	function butt:DoClick()
		func(arg)
	end
	cpanel:AddItem(butt)
	return butt
end
local function CCol(cpanel,text, notexpanded)
	local cat = vgui.Create("DCollapsibleCategory",cpanel)
	cat:SetExpanded(1)
	cat:SetLabel(text)
	cpanel:AddItem(cat)
	local col = vgui.Create("DPanelList")
	col:SetAutoSize(true)
	col:SetSpacing(5)
	col:EnableHorizontal(false)
	col:EnableVerticalScrollbar(true)
	col.Paint = function()
		surface.DrawRect(0, 0, 500, 500)
	end
	cat:SetContents(col)
	cat:SetExpanded(not notexpanded)
	return col, cat
end
local function CBinder(cpanel)
	local parent = vgui.Create("Panel", cpanel)
	cpanel:AddItem(parent)

	local bindrot = vgui.Create("DBinder", parent)
	bindrot.Label = vgui.Create("DLabel", parent)
	bindrot:SetConVar("ragdollmover_rotatebutton")
	bindrot:SetSize(100, 50)

	bindrot.Label:SetText("#tool.ragdollmover.bindrot")
	bindrot.Label:SetDark(true)
	bindrot.Label:SizeToContents()

	function bindrot:OnChange(keycode)
		net.Start("rgmSetToggleRot")
		net.WriteInt(keycode, 32)
		net.SendToServer()
	end

	local bindsc = vgui.Create("DBinder", parent)
	bindsc.Label = vgui.Create("DLabel", parent)
	bindsc:SetConVar("ragdollmover_scalebutton")
	bindsc:SetSize(100, 50)

	bindsc.Label:SetText("#tool.ragdollmover.bindscale")
	bindsc.Label:SetDark(true)
	bindsc.Label:SizeToContents()

	function bindsc:OnChange(keycode)
		net.Start("rgmSetToggleScale")
		net.WriteInt(keycode, 32)
		net.SendToServer()
	end

	local rotw, scw = bindrot.Label:GetWide(), bindsc.Label:GetWide()

	parent.PerformLayout = function()
		parent:SetHeight(80)

		bindrot:SetPos(parent:GetWide()/2 - 100 - 5 - 30 *(parent:GetWide()/217 - 1), 25)
		bindrot.Label:SetPos(bindrot:GetX() + 50 - rotw/2, 0)
		bindrot.Label:SetWidth(parent:GetWide()/2 - bindrot.Label:GetX())

		bindsc:SetPos(parent:GetWide()/2 + 5 + 30 *(parent:GetWide()/217 - 1), 25)
		bindsc.Label:SetPos(bindsc:GetX() + 50 - scw/2, 0)
		bindsc.Label:SetWidth(parent:GetWide() - bindsc.Label:GetX())
	end
end

local AdditionalIKs = {
	"ragdollmover_ik_chain_1",
	"ragdollmover_ik_chain_2",
	"ragdollmover_ik_chain_3",
	"ragdollmover_ik_chain_4",
	"ragdollmover_ik_chain_5",
	"ragdollmover_ik_chain_6"
}

local function CBAdditionalIKs(cpanel, text)
	local butt = vgui.Create("DButton", cpanel)
	butt:SetText(text)
	function butt:DoClick()
		local menu = DermaMenu(false, cpanel)
		local panel = vgui.Create("Panel")
		panel:SetSize(100, 125)
		panel.iks = {}

		for i = 1, 6 do
			panel.iks[i] = vgui.Create("DCheckBoxLabel", panel)
			panel.iks[i]:SetText(language.GetPhrase("tool.ragdollmover.ikchain") .. " " ..i)
			panel.iks[i]:SetDark(true)
			panel.iks[i]:SetConVar(AdditionalIKs[i])
			panel.iks[i]:SetSize(90, 15)
			panel.iks[i]:SetPos(5, 5 + 20*(i - 1))
		end

		menu:AddPanel(panel)
		menu:Open()
	end
	cpanel:AddItem(butt)

	return butt
end

local function RGMResetGizmo()
	local pl = LocalPlayer()
	if not pl.rgm then return end
	net.Start("rgmResetGizmo")
	net.SendToServer()
end

local function RGMGizmoMode()
	local pl = LocalPlayer()
	if not pl.rgm then return end
	net.Start("rgmOperationSwitch")
	net.SendToServer()
end

local function RGMSelectAllIK()
	local ik1, ik2, ik3, ik4 = GetConVar("ragdollmover_ik_leg_L"):GetBool(), GetConVar("ragdollmover_ik_leg_R"):GetBool(), GetConVar("ragdollmover_ik_hand_L"):GetBool(), GetConVar("ragdollmover_ik_hand_R"):GetBool()

	if ik1 && ik2 && ik3 && ik4 then
		RunConsoleCommand("ragdollmover_ik_hand_L", 0)
		RunConsoleCommand("ragdollmover_ik_hand_R", 0)
		RunConsoleCommand("ragdollmover_ik_leg_L", 0)
		RunConsoleCommand("ragdollmover_ik_leg_R", 0)
	else
		RunConsoleCommand("ragdollmover_ik_hand_L", 1)
		RunConsoleCommand("ragdollmover_ik_hand_R", 1)
		RunConsoleCommand("ragdollmover_ik_leg_L", 1)
		RunConsoleCommand("ragdollmover_ik_leg_R", 1)
	end
end

local function RGMResetAllBones()
	local pl = LocalPlayer()
	if not pl.rgm or not pl.rgm.Entity then return end

	net.Start("rgmResetAll")
	net.WriteEntity(pl.rgm.Entity)
	net.WriteUInt(0, 10)
	net.WriteBool(true)
	net.SendToServer()
end

local function AddHBar(self) -- There is no horizontal scrollbars in gmod, so I guess we'll override vertical one from GMod
	self.HBar = vgui.Create("DVScrollBar")

	self.HBar.btnUp.Paint = function(panel, w, h) derma.SkinHook("Paint", "ButtonLeft", panel, w, h) end
	self.HBar.btnDown.Paint = function(panel, w, h) derma.SkinHook("Paint", "ButtonRight", panel, w, h) end

	self.PanelWidth = 100
	self.LastWidth = 1

	self.HBar.SetScroll = function(self, scrll)
		if (not self.Enabled) then self.Scroll = 0 return end

		self.Scroll = math.Clamp( scrll, 0, self.CanvasSize )

		self:InvalidateLayout()

		local func = self:GetParent().OnHScroll
		if func then
			func(self:GetParent(), self:GetOffset())
		end
	end

	self.HBar.OnMousePressed = function(self)
		local x, y = self:CursorPos()

		local PageSize = self.BarSize

		if (x > self.btnGrip.x) then
			self:SetScroll(self:GetScroll() + PageSize)
		else
			self:SetScroll(self:GetScroll() - PageSize)
		end
	end

	self.HBar.OnCursorMoved = function(self, x, y)
		if (not self.Enabled) then return end
		if (not self.Dragging) then return end

		local x, y = self:ScreenToLocal(gui.MouseX(), 0)

		x = x - self.btnUp:GetWide()
		x = x - self.HoldPos

		local BtnHeight = self:GetTall()
		if (self:GetHideButtons()) then BtnHeight = 0 end

		local TrackSize = self:GetWide() - BtnHeight * 2 - self.btnGrip:GetWide()

		x = x / TrackSize

		self:SetScroll(x * self.CanvasSize)
	end

	self.HBar.Grip = function(self)
		if (!self.Enabled) then return end
		if (self.BarSize == 0) then return end

		self:MouseCapture(true)
		self.Dragging = true

		local x, y = self.btnGrip:ScreenToLocal(gui.MouseX(), 0)
		self.HoldPos = x

		self.btnGrip.Depressed = true
	end

	self.HBar.PerformLayout = function(self)
		local Tall = self:GetTall()
		local BtnHeight = Tall
		if (self:GetHideButtons()) then BtnHeight = 0 end
		local Scroll = self:GetScroll() / self.CanvasSize
		local BarSize = math.max(self:BarScale() * (self:GetWide() - (BtnHeight * 2)), 10)
		local Track = self:GetWide() - (BtnHeight * 2) - BarSize
		Track = Track + 1

		Scroll = Scroll * Track

		self.btnGrip:SetPos(BtnHeight + Scroll, 0)
		self.btnGrip:SetSize(BarSize, Tall)

		if (BtnHeight > 0) then
			self.btnUp:SetPos(0, 0)
			self.btnUp:SetSize(BtnHeight, Tall)

			self.btnDown:SetPos(self:GetWide() - BtnHeight, 0)
			self.btnDown:SetSize(BtnHeight, Tall)

			self.btnUp:SetVisible( true )
			self.btnDown:SetVisible( true )
		else
			self.btnUp:SetVisible( false )
			self.btnDown:SetVisible( false )
			self.btnDown:SetSize(BtnHeight, Tall)
			self.btnUp:SetSize(BtnHeight, Tall)
		end
	end

	self.OnVScroll = function(self, iOffset)
		local x = self.pnlCanvas:GetPos()
		self.pnlCanvas:SetPos(x, iOffset)
	end

	self.OnHScroll = function(self, iOffset)
		local _, y = self.pnlCanvas:GetPos()
		self.pnlCanvas:SetPos(iOffset, y)
	end

	self.PerformLayoutInternal = function(self)
		local HTall, VTall = self:GetTall(), self.pnlCanvas:GetTall()
		local HWide, VWide = self:GetWide(), self.PanelWidth
		local XPos, YPos = 0, 0

		self:Rebuild()

		self.VBar:SetUp(self:GetTall(), self.pnlCanvas:GetTall())
		self.HBar:SetUp(self:GetWide(), self.pnlCanvas:GetWide())
		YPos = self.VBar:GetOffset()
		XPos = self.HBar:GetOffset()

		if (self.VBar.Enabled) then VWide = VWide - self.VBar:GetWide() end
		if (self.HBar.Enabled) then HTall = HTall - self.HBar:GetTall() end

		self.pnlCanvas:SetPos(XPos, YPos)
		self.pnlCanvas:SetSize(VWide, HTall)

		self:Rebuild()

		if (HWide ~= self.LastWidth) then
			self.HBar:SetScroll(self.HBar:GetScroll())
		end

		if (VTall ~= self.pnlCanvas:GetTall()) then
			self.VBar:SetScroll(self.VBar:GetScroll())
		end

		self.LastWidth = HWide
	end

	self.PerformLayout = function(self)
		self:PerformLayoutInternal()
	end

	self.UpdateWidth = function(self, newwidth)
		self.PanelWidth = newwidth
		self:InvalidateLayout()
	end
end

local BonePanel, EntPanel, ConEntPanel
local Pos1, Pos2, Pos3, Rot1, Rot2, Rot3, Scale1, Scale2, Scale3, Entry1, Entry2, Entry3
local ManipSliderUpdating = false
local Gizmo1, Gizmo2, Gizmo3
local nodes, entnodes, conentnodes
local HoveredBone, HoveredEntBone, HoveredEnt
local Col4
local LockMode, LockTo = false, { id = nil, ent = nil }
local IsPropRagdoll, TreeEntities = false, {}

local function SetBoneNodes(bonepanel, sortedbones)

	nodes = {}

	local width = 0

	local BoneTypeSort = {
		{ Icon = "icon16/brick.png", ToolTip = "#tool.ragdollmover.physbone" },
		{ Icon = "icon16/connect.png", ToolTip = "#tool.ragdollmover.nonphysbone" },
		{ Icon = "icon16/error.png", ToolTip = "#tool.ragdollmover.proceduralbone" },
	}

	for i, entdata in ipairs(sortedbones) do
		local ent = entdata.ent
		nodes[ent] = { id = entdata.id, parent = entdata.parent }

		for k, v in ipairs(entdata) do
			local text1 = ent:GetBoneName(v.id)

			if nodes[ent].parent then
				nodes[ent][v.id] = nodes[nodes[ent].parent][0]:AddNode(text1)
			elseif v.parent then
				nodes[ent][v.id] = nodes[ent][v.parent]:AddNode(text1)
			else
				nodes[ent][v.id] = bonepanel:AddNode(text1)
			end

			nodes[ent][v.id].Type = v.Type
			nodes[ent][v.id]:SetExpanded(true)

			nodes[ent][v.id]:SetIcon(BoneTypeSort[v.Type].Icon)
			nodes[ent][v.id].Label:SetToolTip(BoneTypeSort[v.Type].ToolTip)

			nodes[ent][v.id].DoClick = function()

				if not LockMode then
					net.Start("rgmSelectBone")
						net.WriteEntity(ent)
						net.WriteUInt(v.id, 10)
					net.SendToServer()
				else
					if LockMode == 1 then
						net.Start("rgmLockToBone")
							net.WriteEntity(ent)
							net.WriteUInt(v.id, 10)
							net.WriteEntity(LockTo.ent)
							net.WriteUInt(LockTo.id, 10)
						net.SendToServer()

						if nodes[LockTo.ent][LockTo.id].poslock or nodes[LockTo.ent][LockTo.id].anglock then
							nodes[LockTo.ent][LockTo.id]:SetIcon("icon16/lock.png")
							nodes[LockTo.ent][LockTo.id].Label:SetToolTip("#tool.ragdollmover.lockedbone")
						else
							nodes[LockTo.ent][LockTo.id]:SetIcon(BoneTypeSort[nodes[LockTo.ent][LockTo.id].Type].Icon)
							nodes[LockTo.ent][LockTo.id].Label:SetToolTip(BoneTypeSort[nodes[LockTo.ent][LockTo.id].Type].ToolTip)
						end
					elseif LockMode == 2 then
						net.Start("rgmLockConstrained")
							net.WriteEntity(ent)
							net.WriteEntity(LockTo.id) -- In this case it isn't really "LockTo", more of "LockThis" but i was lazy so used same variables. Probably once I get to C++ stuff trying to do the same thing would be baaad
							net.WriteBool(true)
							net.WriteUInt(v.id, 8)
						net.SendToServer()

						conentnodes[LockTo.id]:SetIcon("icon16/brick_link.png")
						conentnodes[LockTo.id].Label:SetToolTip(false)
					end

					LockMode = false
					LockTo = { id = nil, ent = nil }
				end

			end

			nodes[ent][v.id].DoRightClick = function()
				local bonemenu = DermaMenu(false, bonepanel)

				local ResetMenu = bonemenu:AddSubMenu("#tool.ragdollmover.resetmenu")

				local option = ResetMenu:AddOption("#tool.ragdollmover.reset", function()
					if not IsValid(ent) then return end
					net.Start("rgmResetAll")
					net.WriteEntity(ent)
					net.WriteUInt(v.id, 10)
					net.WriteBool(false)
					net.SendToServer()
				end)
				option:SetIcon("icon16/connect.png")

				option = ResetMenu:AddOption("#tool.ragdollmover.resetpos", function()
					if not IsValid(ent) then return end
					net.Start("rgmResetPos")
					net.WriteEntity(ent)
					net.WriteBool(false)
					net.WriteUInt(v.id, 10) -- with SFM studiomdl, it seems like upper limit for bones is 512 (counting 0)
					net.SendToServer()
				end)
				option:SetIcon("icon16/connect.png")

				option = ResetMenu:AddOption("#tool.ragdollmover.resetrot", function()
					if not IsValid(ent) then return end
					net.Start("rgmResetAng")
					net.WriteEntity(ent)
					net.WriteBool(false)
					net.WriteUInt(v.id, 10)
					net.SendToServer()
				end)
				option:SetIcon("icon16/connect.png")

				option = ResetMenu:AddOption("#tool.ragdollmover.resetscale", function()
					if not IsValid(ent) then return end
					net.Start("rgmResetScale")
					net.WriteEntity(ent)
					net.WriteBool(false)
					net.WriteUInt(v.id, 10)
					net.SendToServer()
				end)
				option:SetIcon("icon16/connect.png")

				option = ResetMenu:AddOption("#tool.ragdollmover.resetchildren", function()
					if not IsValid(ent) then return end
					net.Start("rgmResetAll")
					net.WriteEntity(ent)
					net.WriteUInt(v.id, 10)
					net.WriteBool(true)
					net.SendToServer()
				end)
				option:SetIcon("icon16/bricks.png")

				option = ResetMenu:AddOption("#tool.ragdollmover.resetposchildren", function()
					if not IsValid(ent) then return end
					net.Start("rgmResetPos")
					net.WriteEntity(ent)
					net.WriteBool(true)
					net.WriteUInt(v.id, 10)
					net.SendToServer()
				end)
				option:SetIcon("icon16/bricks.png")

				option = ResetMenu:AddOption("#tool.ragdollmover.resetrotchildren", function()
					if not IsValid(ent) then return end
					net.Start("rgmResetAng")
					net.WriteEntity(ent)
					net.WriteBool(true)
					net.WriteUInt(v.id, 10)
					net.SendToServer()
				end)
				option:SetIcon("icon16/bricks.png")

				option = ResetMenu:AddOption("#tool.ragdollmover.resetscalechildren", function()
					if not IsValid(ent) then return end
					net.Start("rgmResetScale")
					net.WriteEntity(ent)
					net.WriteBool(true)
					net.WriteUInt(v.id, 10)
					net.SendToServer()
				end)
				option:SetIcon("icon16/bricks.png")

				local ScaleZeroMenu = bonemenu:AddSubMenu("#tool.ragdollmover.scalezero")

				option = ScaleZeroMenu:AddOption("#tool.ragdollmover.bone", function()
					if not IsValid(ent) then return end
					net.Start("rgmScaleZero")
					net.WriteEntity(ent)
					net.WriteBool(false)
					net.WriteUInt(v.id, 10)
					net.SendToServer()
				end)
				option:SetIcon("icon16/connect.png")

				option = ScaleZeroMenu:AddOption("#tool.ragdollmover.bonechildren", function()
					if not IsValid(ent) then return end
					net.Start("rgmScaleZero")
					net.WriteEntity(ent)
					net.WriteBool(true)
					net.WriteUInt(v.id, 10)
					net.SendToServer()
				end)
				option:SetIcon("icon16/bricks.png")

				bonemenu:AddSpacer()

				if nodes[ent][v.id].bonelock then

					option = bonemenu:AddOption("#tool.ragdollmover.unlockbone", function()
						if not IsValid(ent) then return end
						net.Start("rgmUnlockToBone")
							net.WriteEntity(ent)
							net.WriteUInt(v.id, 10)
						net.SendToServer()
					end)

					bonemenu:AddSpacer()
				elseif nodes[ent][v.id].Type == BONE_PHYSICAL and IsValid(ent) and ( ent:GetClass() == "prop_ragdoll" or IsPropRagdoll ) then

					option = bonemenu:AddOption(nodes[ent][v.id].poslock and "#tool.ragdollmover.unlockpos" or "#tool.ragdollmover.lockpos", function()
						if not IsValid(ent) then return end
						net.Start("rgmLockBone")
							net.WriteEntity(ent)
							net.WriteUInt(1, 2)
							net.WriteUInt(v.id, 10)
						net.SendToServer()
					end)
					option:SetIcon(nodes[ent][v.id].poslock and "icon16/lock.png" or "icon16/brick.png")

					option = bonemenu:AddOption(nodes[ent][v.id].anglock and "#tool.ragdollmover.unlockang" or "#tool.ragdollmover.lockang", function()
						if not IsValid(ent) then return end
						net.Start("rgmLockBone")
							net.WriteEntity(ent)
							net.WriteUInt(2, 2)
							net.WriteUInt(v.id, 10)
						net.SendToServer()
					end)
					option:SetIcon(nodes[ent][v.id].anglock and "icon16/lock.png" or "icon16/brick.png")

					option = bonemenu:AddOption("#tool.ragdollmover.lockbone", function()
						if not IsValid(ent) then return end

						if LockMode == 1 then
							nodes[LockTo.ent][LockTo.id]:SetIcon(BoneTypeSort[nodes[LockTo.ent][LockTo.id].Type].Icon)
							nodes[LockTo.ent][LockTo.id].Label:SetToolTip(BoneTypeSort[nodes[LockTo.ent][LockTo.id].Type].ToolTip)
						elseif LockMode == 2 then
							conentnodes[LockTo.id]:SetIcon("icon16/brick_link.png")
							conentnodes[LockTo.id].Label:SetToolTip(false)
						end

						LockMode = 1
						LockTo = { id = v.id, ent = ent }

						surface.PlaySound("buttons/button9.wav")
						nodes[ent][v.id]:SetIcon("icon16/brick_add.png")
						nodes[ent][v.id].Label:SetToolTip("#tool.ragdollmover.bonetolock")
					end)
					option:SetIcon("icon16/lock.png")

					bonemenu:AddSpacer()
				end

				bonemenu:AddOption("#tool.ragdollmover.putgizmopos", function()
					if not IsValid(ent) then return end

					local bone = v.id
					local pos = ent:GetBonePosition(bone)
					if pos == ent:GetPos() then
						local matrix = ent:GetBoneMatrix(bone)
						pos = matrix:GetTranslation()
					end

					net.Start("rgmSetGizmoToBone")
					net.WriteVector(pos)
					net.SendToServer()
				end)

				local x, y = bonepanel:LocalToScreen(5, 0)

				bonemenu:Open(x)
			end

			nodes[ent][v.id].Label.OnCursorEntered = function()
				HoveredBone = v.id
				HoveredEntBone = ent
			end

			nodes[ent][v.id].Label.OnCursorExited = function()
				HoveredBone = nil
				HoveredEntBone = nil
			end

			local XSize = nodes[ent][v.id].Label:GetTextSize()
			local currentwidth = XSize + ((v.depth + entdata.depth - 1) * 17)
			if currentwidth > width then
				width = currentwidth
			end
		end
	end

	bonepanel:UpdateWidth(width + 8 + 32 + 16)
end

local function RGMBuildBoneMenu(ents, selectedent, bonepanel)
	bonepanel:Clear()
	if not IsValid(selectedent) then return end
	local sortedbones = {}
	local count = 0

	for ent, data in pairs(ents) do
		if not IsValid(ent) then continue end

		if not data.parent then
			local entdata = { ent = ent, id = data.id, depth = 1 }
			table.insert(sortedbones, entdata)

			GetRecursiveEntities(ents, entdata.id, ent, sortedbones, entdata.depth)
		end
	end

	for id, entdata in ipairs(sortedbones) do
		local ent = entdata.ent
		local num = ent:GetBoneCount() - 1 -- first we find all rootbones and their children
		for v = 0, num do
			if ent:GetBoneName(v) == "__INVALIDBONE__" then continue end

			if ent:GetBoneParent(v) == -1 then
				local bone = { id = v, Type = BONE_NONPHYSICAL, depth = 1 }
				if ent:BoneHasFlag(v, 4) then -- BONE_ALWAYS_PROCEDURAL flag
					bone.Type = BONE_PROCEDURAL
				end

				table.insert(entdata, bone)
				GetRecursiveBones(ent, v, entdata, bone.depth)
			end
		end
		count = count + 1
	end

	SetBoneNodes(bonepanel, sortedbones)

	net.Start("rgmAskForPhysbones")
		net.WriteUInt(count, 13)
		for ent, _ in pairs(ents) do
			net.WriteEntity(ent)
		end
	net.SendToServer()

	for ent, _ in pairs(ents) do
		if ent:IsEffectActive(EF_BONEMERGE) then
			net.Start("rgmAskForParented")
				net.WriteUInt(count, 13)
				for ent, _ in pairs(ents) do
					net.WriteEntity(ent)
				end
			net.SendToServer()
			break
		end
	end
end

local function ShowOnlyPhysNodes(ent, bonepanel)
	bonepanel:Clear()
	if not IsValid(ent) then return end
	local count = 0

	for ent, data in pairs(TreeEntities) do
		count = count + 1
	end

	net.Start("rgmAskForNodeUpdatePhysics")
		net.WriteBool(true)
		net.WriteUInt(count, 13)

		for ent, _ in pairs(TreeEntities) do
			net.WriteEntity(ent)
		end
	net.SendToServer()
end

local function ShowOnlyNonPhysNodes(ent, bonepanel)
	bonepanel:Clear()
	if not IsValid(ent) then return end
	local count = 0

	for ent, data in pairs(TreeEntities) do
		count = count + 1
	end

	net.Start("rgmAskForNodeUpdatePhysics")
		net.WriteBool(false)
		net.WriteUInt(count, 13)

		for ent, _ in pairs(TreeEntities) do
			net.WriteEntity(ent)
		end
	net.SendToServer()
end

local function UpdateBoneNodes(bonepanel, physIDs, isphys)
	local sortedbones = {}
	local count = 0

	for ent, data in pairs(TreeEntities) do
		if not IsValid(ent) then continue end

		if not data.parent then
			local entdata = { ent = ent, id = data.id, depth = 1 }
			table.insert(sortedbones, entdata)

			GetRecursiveEntities(TreeEntities, entdata.id, ent, sortedbones, entdata.depth)
		end
	end

	for id, entdata in ipairs(sortedbones) do
		local ent = entdata.ent

		local num = ent:GetBoneCount() - 1
		for v = 0, num do
			if ent:GetBoneName(v) == "__INVALIDBONE__" then continue end

			if ent:GetBoneParent(v) == -1 then
				local bone = { id = v, Type = BONE_NONPHYSICAL, depth = 1 }
				if ent:BoneHasFlag(v, 4) then
					bone.Type = BONE_PROCEDURAL
				end
				if physIDs[ent][v] then
					bone.Type = BONE_PHYSICAL
				end

				table.insert(entdata, bone)
				GetRecursiveBonesExclusive(ent, v, v, entdata, physIDs[ent], isphys, bone.depth)
			end
		end
		count = count + 1
	end

	SetBoneNodes(bonepanel, sortedbones)

	if isphys then
		net.Start("rgmAskForPhysbones")
			net.WriteUInt(count, 13)
			for ent, _ in pairs(TreeEntities) do
				net.WriteEntity(ent)
			end
		net.SendToServer()
	end

	for ent, _ in pairs(TreeEntities) do
		if ent:IsEffectActive(EF_BONEMERGE) then
			net.Start("rgmAskForParented")
				net.WriteUInt(count, 13)
				for ent, _ in pairs(TreeEntities) do
					net.WriteEntity(ent)
				end
			net.SendToServer()
			break
		end
	end
end

local function RGMBuildEntMenu(ents, children, entpanel)
	entpanel:Clear()
	local width = 0

	entnodes = {}

	for parent, entdata in pairs(ents) do
		if not IsValid(parent) then continue end

		local LockSelection = GetConVar("ragdollmover_lockselected")

		entnodes[parent] = entpanel:AddNode(GetModelName(parent))
		entnodes[parent]:SetExpanded(true)

		entnodes[parent].DoClick = function()
			net.Start("rgmSelectEntity")
				net.WriteEntity(parent)
				net.WriteBool(LockSelection:GetBool())
			net.SendToServer()
		end

		entnodes[parent].Label.OnCursorEntered = function()
			HoveredEnt = parent
		end

		entnodes[parent].Label.OnCursorExited = function()
			HoveredEnt = nil
		end

		local XSize = entnodes[parent].Label:GetTextSize() + 17
		if XSize > width then
			width = XSize
		end

		local sortchildren = {depth = 1}

		local function RecursiveChildrenSort(ent, sorttable, depth)
			for k, v in ipairs(children[parent]) do
				if v:GetParent() ~= ent then continue end
				table.insert(sorttable, v)
				sorttable[v] = {}
				sorttable[v].depth = depth + 1
				RecursiveChildrenSort(v, sorttable[v], depth + 1)
			end
		end

		RecursiveChildrenSort(parent, sortchildren, sortchildren.depth)

		local function MakeChildrenList(parent, sorttable)
			local depth = sorttable.depth
			for k, v in ipairs(sorttable) do
				if not IsValid(v) or not isstring(v:GetModel()) then continue end
				entnodes[v] = entnodes[parent]:AddNode(GetModelName(v))
				entnodes[v]:SetExpanded(true)

				entnodes[v].DoClick = function()
					net.Start("rgmSelectEntity")
						net.WriteEntity(v)
						net.WriteBool(LockSelection:GetBool())
					net.SendToServer()
				end

				entnodes[v].Label.OnCursorEntered = function()
					HoveredEnt = v
				end

				entnodes[v].Label.OnCursorExited = function()
					HoveredEnt = nil
				end

				XSize = entnodes[v].Label:GetTextSize()
				local currentwidth = XSize + (depth * 17)

				if currentwidth > width then
					width = currentwidth
				end

				MakeChildrenList(v, sorttable[v])
			end
		end

		MakeChildrenList(parent, sortchildren)
	end

	entpanel:UpdateWidth(width + 8 + 32 + 16)
end

local function RGMBuildConstrainedEnts(parent, children, entpanel)
	entpanel:Clear()
	if not IsValid(parent) then return end

	conentnodes = {}

	conentnodes[parent] = entpanel:AddNode(GetModelName(parent))
	conentnodes[parent]:SetIcon("icon16/brick.png")
	conentnodes[parent]:SetExpanded(true)

	conentnodes[parent].Label.OnCursorEntered = function()
		HoveredEnt = parent
	end

	conentnodes[parent].Label.OnCursorExited = function()
		HoveredEnt = nil
	end

	for _, ent in ipairs(children) do
		conentnodes[ent] = conentnodes[parent]:AddNode(GetModelName(ent))
		conentnodes[ent]:SetIcon("icon16/brick_link.png")
		conentnodes[ent].Locked = false

		conentnodes[ent].DoClick = function()
			if conentnodes[ent].Locked then
				net.Start("rgmUnlockConstrained")
					net.WriteEntity(ent)
				net.SendToServer()
			else
				if parent:GetClass() ~= "prop_ragdoll" and not IsPropRagdoll then
					net.Start("rgmLockConstrained")
						net.WriteEntity(parent)
						net.WriteEntity(ent)
						net.WriteBool(false)
					net.SendToServer()
				else

					if LockMode == 1 then
						nodes[LockTo.ent][LockTo.id]:SetIcon(BoneTypeSort[nodes[LockTo.ent][LockTo.id].Type].Icon)
						nodes[LockTo.ent][LockTo.id].Label:SetToolTip(BoneTypeSort[nodes[LockTo.ent][LockTo.id].Type].ToolTip)
					elseif LockMode == 2 then
						conentnodes[LockTo.id]:SetIcon("icon16/brick_link.png")
						conentnodes[LockTo.id].Label:SetToolTip(false)
					end

					LockMode = 2
					LockTo = { id = ent, ent = ent }

					surface.PlaySound("buttons/button9.wav")
					conentnodes[ent]:SetIcon("icon16/brick_edit.png")
					conentnodes[ent].Label:SetToolTip("#tool.ragdollmover.entlock")
				end
			end
		end

		conentnodes[ent].Label.OnCursorEntered = function()
			HoveredEnt = ent
		end

		conentnodes[ent].Label.OnCursorExited = function()
			HoveredEnt = nil
		end
	end
end

local function RGMMakeBoneButtonPanel(cat, cpanel)
	local parentpanel = vgui.Create("Panel", cat)
	parentpanel:SetSize(100, 30)
	cat:AddItem(parentpanel)

	parentpanel.ShowAll = vgui.Create("DButton", parentpanel)
	parentpanel.ShowAll:Dock(FILL)
	parentpanel.ShowAll:SetZPos(0)
	parentpanel.ShowAll:SetText("#tool.ragdollmover.listshowall")
	parentpanel.ShowAll.DoClick = function()
		local ent = LocalPlayer().rgm.Entity
		if not IsValid(ent) or not IsValid(BonePanel) then return end
		RGMBuildBoneMenu(TreeEntities, ent, BonePanel)
	end

	parentpanel.ShowPhys = vgui.Create("DButton", parentpanel)
	parentpanel.ShowPhys:Dock(LEFT)
	parentpanel.ShowPhys:SetZPos(1)
	parentpanel.ShowPhys:SetText("#tool.ragdollmover.listshowphys")
	parentpanel.ShowPhys.DoClick = function()
		local ent = LocalPlayer().rgm.Entity
		if not IsValid(ent) or not IsValid(BonePanel) then return end
		ShowOnlyPhysNodes(ent, BonePanel)
	end

	parentpanel.ShowNonphys = vgui.Create("DButton", parentpanel)
	parentpanel.ShowNonphys:Dock(RIGHT)
	parentpanel.ShowNonphys:SetZPos(1)
	parentpanel.ShowNonphys:SetText("#tool.ragdollmover.listshownonphys")
	parentpanel.ShowNonphys.DoClick = function()
		local ent = LocalPlayer().rgm.Entity
		if not IsValid(ent) or not IsValid(BonePanel) then return end
		ShowOnlyNonPhysNodes(ent, BonePanel)
	end

	return parentpanel
end

local function rgmDoNotification(message)

	local MessageTable = {}

	for key, data in pairs(RGM_NOTIFY) do
		if not data.iserror then
			MessageTable[data.id] = function()
				notification.AddLegacy("#tool.ragdollmover.message" .. data.id, NOTIFY_GENERIC, 5)
				surface.PlaySound("buttons/button14.wav")
			end
		else
			MessageTable[data.id] = function()
				notification.AddLegacy("#tool.ragdollmover.message" .. data.id, NOTIFY_ERROR, 5)
				surface.PlaySound("buttons/button10.wav")
			end
		end
	end

	MessageTable[message]()
end

function TOOL.BuildCPanel(CPanel)

	local Col1 = CCol(CPanel,"#tool.ragdollmover.gizmopanel")
		CCheckBox(Col1,"#tool.ragdollmover.localpos","ragdollmover_localpos")
		CCheckBox(Col1,"#tool.ragdollmover.localang","ragdollmover_localang")
		CNumSlider(Col1,"#tool.ragdollmover.scale","ragdollmover_scale",1.0,50.0,2)
		CNumSlider(Col1,"#tool.ragdollmover.width","ragdollmover_width",0.1,1.0,2)
		CCheckBox(Col1,"#tool.ragdollmover.fulldisc","ragdollmover_fulldisc")

		local GizmoOffset = CCol(Col1, "#tool.ragdollmover.gizmooffsetpanel", true)
		CCheckBox(GizmoOffset,"#tool.ragdollmover.gizmolocaloffset","ragdollmover_localoffset")
		CCheckBox(GizmoOffset,"#tool.ragdollmover.gizmorelativerotate","ragdollmover_relativerotate")
		Gizmo1 = CGizmoSlider(GizmoOffset, "#tool.ragdollmover.xoffset", 1, -300, 300, 2)
		Gizmo2 = CGizmoSlider(GizmoOffset, "#tool.ragdollmover.yoffset", 2, -300, 300, 2)
		Gizmo3 = CGizmoSlider(GizmoOffset, "#tool.ragdollmover.zoffset", 3, -300, 300, 2)
		CButton(GizmoOffset, "#tool.ragdollmover.resetoffset", RGMResetGizmo)
		CButton(GizmoOffset, "#tool.ragdollmover.setoffset", RGMGizmoMode)

	local Col2 = CCol(CPanel,"#tool.ragdollmover.ikpanel")
		CCheckBox(Col2,"#tool.ragdollmover.ik3","ragdollmover_ik_hand_L")
		CCheckBox(Col2,"#tool.ragdollmover.ik4","ragdollmover_ik_hand_R")
		CCheckBox(Col2,"#tool.ragdollmover.ik1","ragdollmover_ik_leg_L")
		CCheckBox(Col2,"#tool.ragdollmover.ik2","ragdollmover_ik_leg_R")
		CButton(Col2, "#tool.ragdollmover.ikall", RGMSelectAllIK)
		CBAdditionalIKs(Col2, "#tool.ragdollmover.additional")

	local Col3 = CCol(CPanel,"#tool.ragdollmover.miscpanel")
		CCheckBox(Col3, "#tool.ragdollmover.lockselected","ragdollmover_lockselected")
		local CB = CCheckBox(Col3,"#tool.ragdollmover.unfreeze","ragdollmover_unfreeze")
		CB:SetToolTip("#tool.ragdollmover.unfreezetip")
		local DisFil = CCheckBox(Col3, "#tool.ragdollmover.disablefilter","ragdollmover_disablefilter")
		DisFil:SetToolTip("#tool.ragdollmover.disablefiltertip")
		CCheckBox(Col3, "#tool.ragdollmover.drawskeleton", "ragdollmover_drawskeleton")
		CNumSlider(Col3,"#tool.ragdollmover.updaterate","ragdollmover_updaterate",0.01,1.0,2)

	CBinder(CPanel)

	Col4 = CCol(CPanel, "#tool.ragdollmover.bonemanpanel")

		local ColManip = CCol(Col4, "#tool.ragdollmover.bonemanip", true)
			-- Position
			Entry1 = CManipEntry(ColManip, 1)
			Pos1 = CManipSlider(ColManip, "#tool.ragdollmover.pos1", 1, 1, -300, 300, 2, Entry1) --x
			Pos2 = CManipSlider(ColManip, "#tool.ragdollmover.pos2", 1, 2, -300, 300, 2, Entry1) --y
			Pos3 = CManipSlider(ColManip, "#tool.ragdollmover.pos3", 1, 3, -300, 300, 2, Entry1) --z
			Entry1:SetVisible(false)
			Pos1:SetVisible(false)
			Pos2:SetVisible(false)
			Pos3:SetVisible(false)
			Entry1.Sliders = {Pos1, Pos2, Pos3}
			-- Angles
			Entry2 = CManipEntry(ColManip, 2)
			Rot1 = CManipSlider(ColManip, "#tool.ragdollmover.rot1", 2, 1, -180, 180, 2, Entry2) --pitch
			Rot2 = CManipSlider(ColManip, "#tool.ragdollmover.rot2", 2, 2, -180, 180, 2, Entry2) --yaw
			Rot3 = CManipSlider(ColManip, "#tool.ragdollmover.rot3", 2, 3, -180, 180, 2, Entry2) --roll
			Entry2:SetVisible(false)
			Rot1:SetVisible(false)
			Rot2:SetVisible(false)
			Rot3:SetVisible(false)
			Entry2.Sliders = {Rot1, Rot2, Rot3}
			--Scale
			Entry3 = CManipEntry(ColManip, 3)
			Scale1 = CManipSlider(ColManip, "#tool.ragdollmover.scale1", 3, 1, -100, 100, 2, Entry3) --x
			Scale2 = CManipSlider(ColManip, "#tool.ragdollmover.scale2", 3, 2, -100, 100, 2, Entry3) --y
			Scale3 = CManipSlider(ColManip, "#tool.ragdollmover.scale3", 3, 3, -100, 100, 2, Entry3) --z
			Entry3.Sliders = {Scale1, Scale2, Scale3}

			CButton(ColManip, "#tool.ragdollmover.resetallbones", RGMResetAllBones)

		CCheckBox(Col4,"#tool.ragdollmover.scalechildren","ragdollmover_scalechildren")

		CCheckBox(Col4, "#tool.ragdollmover.snapenable", "ragdollmover_snapenable")
		CNumSlider(Col4, "#tool.ragdollmover.snapamount", "ragdollmover_snapamount", 1, 180, 0)

		local ColBones = CCol(Col4, "#tool.ragdollmover.bonelist")
			RGMMakeBoneButtonPanel(ColBones, CPanel)
			BonePanel = vgui.Create("DTree", ColBones)
			BonePanel:SetTall(600)
			AddHBar(BonePanel)
			ColBones:AddItem(BonePanel)
			ColBones:AddItem(BonePanel.HBar)

	local ColEnts = CCol(CPanel, "#tool.ragdollmover.entchildren")

		EntPanel = vgui.Create("DTree", ColEnts)
		EntPanel:SetTall(150)
		AddHBar(EntPanel)
		EntPanel:SetShowIcons(false)
		ColEnts:AddItem(EntPanel)
		ColEnts:AddItem(EntPanel.HBar)
	
	local ColConsEnts = CCol(CPanel, "#tool.ragdollmover.conents")

		ConEntPanel = vgui.Create("DTree", ColConsEnts)
		ConEntPanel:SetTall(150)
		ColConsEnts:AddItem(ConEntPanel)
		local ConstrainedHelp = vgui.Create("DLabel", ColConsEnts)
		ConstrainedHelp:SetWrap(true)
		ConstrainedHelp:SetAutoStretchVertical(true)
		ConstrainedHelp:SetText("#tool.ragdollmover.conentshelp")
		ConstrainedHelp:SetDark(true)
		ColConsEnts:AddItem(ConstrainedHelp)

end

local function UpdateManipulationSliders(boneid, ent)
	if not IsValid(Pos1) then return end
	local pos, rot, scale = ent:GetManipulateBonePosition(boneid), ent:GetManipulateBoneAngles(boneid), ent:GetManipulateBoneScale(boneid)
	rot:Normalize()

	ManipSliderUpdating = true

	Pos1:SetValue(pos[1])
	Pos2:SetValue(pos[2])
	Pos3:SetValue(pos[3])
	Entry1:SetValue(math.Round(pos[1], 2) .. " " .. math.Round(pos[2], 2) .. " " .. math.Round(pos[3], 2))

	Rot1:SetValue(rot[1])
	Rot2:SetValue(rot[2])
	Rot3:SetValue(rot[3])
	Entry2:SetValue(math.Round(rot[1], 2) .. " " .. math.Round(rot[2], 2) .. " " .. math.Round(rot[3], 2))

	Scale1:SetValue(scale[1])
	Scale2:SetValue(scale[2])
	Scale3:SetValue(scale[3])
	Entry3:SetValue(math.Round(scale[1], 2) .. " " .. math.Round(scale[2], 2) .. " " .. math.Round(scale[3], 2))

	ManipSliderUpdating = false

end

net.Receive("rgmUpdateSliders", function(len)
	pl = LocalPlayer()
	UpdateManipulationSliders(pl.rgm.Bone, pl.rgm.Entity)
end)

net.Receive("rgmUpdateLists", function(len)
	IsPropRagdoll = net.ReadBool()

	local ents, children = {}, {}

	if IsPropRagdoll then
		for i = 1, net.ReadUInt(13) do
			local ent = net.ReadEntity()
			local data = {}
			data.id = net.ReadUInt(13)

			if net.ReadBool() then
				data.parent = net.ReadUInt(13)
			end

			ents[ent] = data

			children[ent] = {}

			for i = 1, net.ReadUInt(13) do
				children[ent][i] = net.ReadEntity()
			end
		end
	end

	local selectedent = net.ReadEntity()
	if not ents[selectedent] then
		ents[selectedent] = {id = -1}
	end

	TreeEntities = ents

	local physchildren = {}
	children[selectedent] = {}

	for i = 1, net.ReadUInt(13) do
		children[selectedent][i] = net.ReadEntity()
	end

	for i = 1, net.ReadUInt(13) do
		physchildren[i] = net.ReadEntity()
	end

	if IsValid(BonePanel) then
		RGMBuildBoneMenu(ents, selectedent, BonePanel)
	end
	if IsValid(EntPanel) then
		RGMBuildEntMenu(ents, children, EntPanel)
	end
	if IsValid(ConEntPanel) then
		RGMBuildConstrainedEnts(selectedent, physchildren, ConEntPanel)
	end
end)

net.Receive("rgmUpdateGizmo", function(len)
	local vector = net.ReadVector()
	if not IsValid(Gizmo1) then return end
	Gizmo1:SetValue(vector.x)
	Gizmo2:SetValue(vector.y)
	Gizmo3:SetValue(vector.z)
end)

net.Receive("rgmUpdateEntInfo", function(len)
	local ent = net.ReadEntity()
	local physchildren = {}

	local ents = {}

	IsPropRagdoll =  false
	if TreeEntities[ent] then
		IsPropRagdoll = true
		ents = TreeEntities
	else
		ents[ent] = { id = -1 }
	end

	for i = 1, net.ReadUInt(13) do
		physchildren[i] = net.ReadEntity()
	end

	if IsValid(BonePanel) then
		RGMBuildBoneMenu(ents, ent, BonePanel)
	end
	if IsValid(ConEntPanel) then
		RGMBuildConstrainedEnts(ent, physchildren, ConEntPanel)
	end
end)

net.Receive("rgmAskForPhysbonesResponse", function(len)
	local entcount = net.ReadUInt(13)
	for j = 1, entcount do
		local ent = net.ReadEntity()

		local count = net.ReadUInt(8)
		for i = 0, count do
			local bone = net.ReadUInt(8)
			local poslock = net.ReadBool()
			local anglock = net.ReadBool()
			local bonelock = net.ReadBool()

			if bone then
				nodes[ent][bone].Type = BONE_PHYSICAL
				nodes[ent][bone].poslock = poslock
				nodes[ent][bone].anglock = anglock
				nodes[ent][bone].bonelock = bonelock

				if LockMode == 1 and bone == LockTo.id and ent == LockTo.ent then
					nodes[ent][bone]:SetIcon("icon16/brick_add.png")
					nodes[ent][bone].Label:SetToolTip("#tool.ragdollmover.bonetolock")
				elseif bonelock then
					nodes[ent][bone]:SetIcon("icon16/lock_go.png")
					nodes[ent][bone].Label:SetToolTip("#tool.ragdollmover.lockedbonetobone")
				elseif anglock or poslock then
					nodes[ent][bone]:SetIcon("icon16/lock.png")
					nodes[ent][bone].Label:SetToolTip("#tool.ragdollmover.lockedbone")
				else
					nodes[ent][bone]:SetIcon("icon16/brick.png")
					nodes[ent][bone].Label:SetToolTip("#tool.ragdollmover.physbone")
				end
			end
		end
	end
end)

net.Receive("rgmAskForParentedResponse", function(len)
	local entcount = net.ReadUInt(13)

	for i = 1, entcount do
		local ent = net.ReadEntity()
		local count = net.ReadUInt(10)

		for i = 1, count do
			local bone = net.ReadUInt(10)

			if nodes[ent][bone] then
				nodes[ent][bone].Type = BONE_PARENTED
				nodes[ent][bone]:SetIcon("icon16/stop.png")
				nodes[ent][bone].Label:SetToolTip("#tool.ragdollmover.parentedbone")
			end
		end
	end
end)

net.Receive("rgmLockBoneResponse", function(len)
	local ent = net.ReadEntity()
	local boneid = net.ReadUInt(10)
	local poslock = net.ReadBool()
	local anglock = net.ReadBool()

	nodes[ent][boneid].poslock = poslock
	nodes[ent][boneid].anglock = anglock

	if poslock or anglock then
		nodes[ent][boneid]:SetIcon("icon16/lock.png")
		nodes[ent][boneid].Label:SetToolTip("#tool.ragdollmover.lockedbone")
	else
		nodes[ent][boneid]:SetIcon("icon16/brick.png")
		nodes[ent][boneid].Label:SetToolTip("#tool.ragdollmover.physbone")
	end
end)

net.Receive("rgmLockToBoneResponse", function(len)
	local ent = net.ReadEntity()
	local lockbone = net.ReadUInt(10)

	if nodes[ent][lockbone] then
		nodes[ent][lockbone].bonelock = true
		nodes[ent][lockbone].poslock = false
		nodes[ent][lockbone].anglock = false
		nodes[ent][lockbone]:SetIcon("icon16/lock_go.png")
		nodes[ent][lockbone].Label:SetToolTip("#tool.ragdollmover.lockedbonetobone")

		rgmDoNotification(RGM_NOTIFY.BONELOCK_SUCCESS.id)
	end
end)

net.Receive("rgmUnlockToBoneResponse", function(len)
	local ent = net.ReadEntity()
	local unlockbone = net.ReadUInt(10)

	if nodes[ent][unlockbone] then
		nodes[ent][unlockbone].bonelock = false
		nodes[ent][unlockbone]:SetIcon("icon16/brick.png")
		nodes[ent][unlockbone].Label:SetToolTip("#tool.ragdollmover.physbone")
	end
end)

net.Receive("rgmLockConstrainedResponse", function(len)
	local lock = net.ReadBool()
	local lockent = net.ReadEntity()

	if conentnodes[lockent] then
		conentnodes[lockent].Locked = lock
		if lock then
			conentnodes[lockent]:SetIcon("icon16/lock.png")
			rgmDoNotification(RGM_NOTIFY.ENTLOCK_SUCCESS.id)
		else
			conentnodes[lockent]:SetIcon("icon16/brick_link.png")
		end
	end
end)

net.Receive("rgmSelectBoneResponse", function(len)
	local function SetVisiblePhysControls(bool)
		local inverted = not bool

		Pos1:SetVisible(inverted)
		Pos2:SetVisible(inverted)
		Pos3:SetVisible(inverted)
		Entry1:SetVisible(inverted)
		Rot1:SetVisible(inverted)
		Rot2:SetVisible(inverted)
		Rot3:SetVisible(inverted)
		Entry2:SetVisible(inverted)
	end

	local isphys = net.ReadBool()
	local ent = net.ReadEntity()
	local boneid = net.ReadUInt(10)

	if IsValid(ent) and boneid then
		UpdateManipulationSliders(boneid, ent)
	end

	if nodes then
		if isphys and nodes[ent] and nodes[ent][boneid] then
			SetVisiblePhysControls(true)
		else
			SetVisiblePhysControls(false)
		end
	end

	if IsValid(BonePanel) and nodes and nodes[ent] then
		BonePanel:SetSelectedItem(nodes[ent][boneid])

		Col4:InvalidateLayout()
	end
end)

net.Receive("rgmAskForNodeUpdatePhysicsResponse", function(len)
	local isphys = net.ReadBool()
	local entcount = net.ReadUInt(13)
	local physIDs, ents = {}

	for i = 1, entcount do
		local ent = net.ReadEntity()
		physIDs[ent] = {}

		local count = net.ReadUInt(8)
		if count ~= 0 then
			for i = 0, count - 1 do
				local id = net.ReadUInt(8)
				physIDs[ent][id] = true
			end
		end
	end


	if not IsValid(BonePanel) then return end
	UpdateBoneNodes(BonePanel, physIDs, isphys)
end)

net.Receive("rgmNotification", function(len)
	local message = net.ReadUInt(5)

	rgmDoNotification(message)
end)

local material = CreateMaterial("rgmGizmoMaterial", "UnlitGeneric", {
	["$basetexture"] = 	"color/white",
  	["$model"] = 		1,
 	["$alphatest"] = 	1,
 	["$vertexalpha"] = 	1,
 	["$vertexcolor"] = 	1,
 	["$ignorez"] = 		1,
	["$nocull"] = 		1,
})

local VECTOR_FRONT = Vector(1,0,0)

function TOOL:DrawHUD()

	local pl = LocalPlayer()
	if not pl.rgm then pl.rgm = {} end

	local ent = pl.rgm.Entity
	local bone = pl.rgm.Bone
	local axis = pl.rgm.Axis
	local moving = pl.rgm.Moving or false
	--We don't draw the axis if we don't have the axis entity or the target entity,
	--or if we're not allowed to draw it.
	if IsValid(ent) and IsValid(axis) and bone then
		local scale = self:GetClientNumber("scale",10)
		local width = self:GetClientNumber("width",0.5)
		local moveaxis = pl.rgm.MoveAxis
		if moving and IsValid(moveaxis) then
			cam.Start({type = "3D"})
			render.SetMaterial(material)

			moveaxis:DrawLines(true,scale,width)

			cam.End()
			if moveaxis:GetType() == 3 then
				local intersect = moveaxis:GetGrabPos(rgm.EyePosAng(pl))
				local fwd = (intersect-axis:GetPos())
				fwd:Normalize()
				axis:DrawDirectionLine(fwd,scale,false)
				local dirnorm = pl.rgm.DirNorm or VECTOR_FRONT
				axis:DrawDirectionLine(dirnorm,scale,true)
				axis:DrawAngleText(moveaxis, intersect, pl.rgm.StartAngle)
			end
		else
			cam.Start({type = "3D"})
			render.SetMaterial(material)

			axis:DrawLines(scale,width)
			cam.End()
		end
	end

	local tr = pl:GetEyeTrace()
	local aimedbone = IsValid(tr.Entity) and (tr.Entity:GetClass() == "prop_ragdoll" and pl.rgm.AimedBone or 0) or 0
	if IsValid(ent) and EntityFilter(ent) and self:GetClientNumber("drawskeleton") ~= 0 then
		rgm.DrawSkeleton(ent)
	end

	if IsValid(HoveredEntBone) and EntityFilter(HoveredEntBone) and HoveredBone then
		rgm.DrawBoneConnections(HoveredEntBone, HoveredBone)
		rgm.DrawBoneName(HoveredEntBone,HoveredBone)
	elseif IsValid(HoveredEnt) and EntityFilter(HoveredEnt) then
		rgm.DrawEntName(HoveredEnt)
	elseif IsValid(tr.Entity) and EntityFilter(tr.Entity) and (not bone or aimedbone ~= bone or tr.Entity ~= pl.rgm.Entity) and not moving then
		rgm.DrawBoneConnections(tr.Entity, aimedbone)
		rgm.DrawBoneName(tr.Entity,aimedbone)
	end

end

end
