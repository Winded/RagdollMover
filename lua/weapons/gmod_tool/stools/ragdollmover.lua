
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

TOOL.ClientConVar["ik_leg_L"] = 0
TOOL.ClientConVar["ik_leg_R"] = 0
TOOL.ClientConVar["ik_hand_L"] = 0
TOOL.ClientConVar["ik_hand_R"] = 0
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

	for i = 0, count - 1 do
		local b = ent:TranslatePhysBoneToBone(i)
		if bone == b then 
			phys = i
			pl.rgm.IsPhysBone = true
		end
	end

	if count == 1 then
		if (ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_effect") and bone == 0 then
			phys = 0
			pl.rgm.IsPhysBone = true
		end
	end
	---------------------------------------------------------
	local bonen = phys or bone

	pl.rgm.PhysBone = bonen
	if pl.rgm.IsPhysBone and not (ent:GetClass() == "prop_physics") then -- physics props only have 1 phys object which is tied to bone -1, and that bone doesn't really exist
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

	local count = 1

	for _, ent in pairs(conents) do
		if not IsValid(ent) or ent:IsWorld() or ent:IsConstraint() or not util.IsValidModel(ent:GetModel()) then continue end
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
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end

	local count = ent:GetPhysicsObjectCount() - 1
	if count ~= -1 then
		net.Start("rgmAskForPhysbonesResponse")
			net.WriteUInt(count, 8)
			for i = 0, count do
				local bone = ent:TranslatePhysBoneToBone(i)
				if bone == -1 then bone = 0 end
				net.WriteUInt(bone, 8)
				net.WriteBool(pl.rgmPosLocks[i] ~= nil)
				net.WriteBool(pl.rgmAngLocks[i] ~= nil)
				net.WriteBool(pl.rgmBoneLocks[i] ~= nil)
			end
		net.Send(pl)
	end
end)

net.Receive("rgmAskForNodeUpdatePhysics", function(len, pl)
	local isphys = net.ReadBool()
	local ent = net.ReadEntity()

	if not IsValid(ent) then return end

	local count = ent:GetPhysicsObjectCount() - 1
	if count ~= -1 then
		net.Start("rgmAskForNodeUpdatePhysicsResponse")
			net.WriteBool(isphys)
			net.WriteEntity(ent)

			net.WriteUInt(count, 8)
			for i = 0, count do
				local bone = ent:TranslatePhysBoneToBone(i)
				if bone == -1 then bone = 0 end
				net.WriteUInt(bone, 8)
			end
		net.Send(pl)
	end
end)

net.Receive("rgmAskForParented", function(len, pl)
	local ent = net.ReadEntity()
	if not IsValid(ent) or not IsValid(ent:GetParent()) then return end

	local parented = {}

	for i = 0, ent:GetBoneCount() - 1 do
		if ent:GetParent():LookupBone(ent:GetBoneName(i)) then
			table.insert(parented, i)
		end
	end

	if next(parented) then
		net.Start("rgmAskForParentedResponse")
			net.WriteUInt(#parented, 32)
			for k, id in ipairs(parented) do
				net.WriteUInt(id, 32)
			end
		net.Send(pl)
	end
end)

net.Receive("rgmSelectBone", function(len, pl)
	local ent = net.ReadEntity()
	local bone = net.ReadUInt(32)

	pl.rgm.BoneToResetTo = 0
	RGMGetBone(pl, ent, bone)
	pl:rgmSync()

	net.Start("rgmSelectBoneResponse")
		net.WriteBool(pl.rgm.IsPhysBone)
		net.WriteEntity(ent)
		net.WriteUInt(pl.rgm.Bone, 32)
	net.Send(pl)
end)

net.Receive("rgmLockBone", function(len, pl)
	local mode = net.ReadUInt(2)
	local ent = pl.rgm.Entity
	local bone = net.ReadUInt(8)

	if not IsValid(ent) or ent:TranslateBoneToPhysBone(bone) == -1 then return end
	if ent:GetClass() ~= "prop_ragdoll" then return end
	bone = rgm.BoneToPhysBone(ent,bone)

	if mode == 1 then
		if not pl.rgmPosLocks[bone] then
			pl.rgmPosLocks[bone] = ent:GetPhysicsObjectNum(bone)
		else
			pl.rgmPosLocks[bone] = nil
		end
	elseif mode == 2 then
		if not pl.rgmAngLocks[bone] then
			pl.rgmAngLocks[bone] = ent:GetPhysicsObjectNum(bone)
		else
			pl.rgmAngLocks[bone] = nil
		end
	end

	local poslock, anglock = IsValid(pl.rgmPosLocks[bone]), IsValid(pl.rgmAngLocks[bone])

	net.Start("rgmLockBoneResponse")
		net.WriteUInt(ent:TranslatePhysBoneToBone(bone), 32)
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

net.Receive("rgmLockToBone", function(len, pl)
	local lockedbone = net.ReadUInt(8)
	local lockorigin = net.ReadUInt(8)
	local ent = pl.rgm.Entity

	if not IsValid(ent) or not (ent:GetClass() == "prop_ragdoll") then return end

	local physcheck = not rgm.BoneToPhysBone(ent, lockedbone) or not rgm.BoneToPhysBone(ent, lockorigin)
	local samecheck = lockedbone == lockorigin

	if physcheck or samecheck then
		local err = samecheck and RGM_NOTIFY.BONELOCK_FAILED_SAME.id or RGM_NOTIFY.BONELOCK_FAILED_NOTPHYS.id

		net.Start("rgmNotification")
			net.WriteUInt(err, 5)
		net.Send(pl)
		return
	end

	if not RecursiveFindIfParent(ent, lockedbone, lockorigin) then
		local bone = rgm.BoneToPhysBone(ent,lockedbone)
		lockorigin = rgm.BoneToPhysBone(ent,lockorigin)

		pl.rgmBoneLocks[bone] = lockorigin
		pl.rgmPosLocks[bone] = nil
		pl.rgmAngLocks[bone] = nil

		net.Start("rgmLockToBoneResponse")
			net.WriteUInt(lockedbone, 8)
		net.Send(pl)
	else
		net.Start("rgmNotification")
			net.WriteUInt(RGM_NOTIFY.BONELOCK_FAILED.id, 5)
		net.Send(pl)
	end
end)

net.Receive("rgmUnlockToBone", function(len, pl)
	local unlockbone = net.ReadUInt(8)
	local ent = pl.rgm.Entity
	local bone = rgm.BoneToPhysBone(ent,unlockbone)

	pl.rgmBoneLocks[bone] = nil

	net.Start("rgmUnlockToBoneResponse")
		net.WriteUInt(unlockbone, 8)
	net.Send(pl)
end)

net.Receive("rgmLockConstrained", function(len, pl)
	local ent = pl.rgm.Entity
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
		if not rgm.BoneToPhysBone(ent, boneid) then
			net.Start("rgmNotification")
				net.WriteUInt(RGM_NOTIFY.ENTLOCK_FAILED_NONPHYS.id, 5)
			net.Send(pl)
			return
		end

		physbone = rgm.BoneToPhysBone(ent, boneid)
	end

	pl.rgmEntLocks[lockent] = physbone

	net.Start("rgmLockConstrainedResponse")
		net.WriteBool(true)
		net.WriteEntity(lockent)
	net.Send(pl)
end)

net.Receive("rgmUnlockConstrained", function(len, pl)
	local ent = pl.rgm.Entity
	local lockent = net.ReadEntity()

	if not IsValid(ent) or not IsValid(lockent) then return end

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
	pl.rgm.BoneToResetTo = 0
	pl.rgmPosLocks = {}
	pl.rgmAngLocks = {}
	pl.rgmBoneLocks = {}
	pl.rgmEntLocks = {}

	if not ent.rgmbonecached then -- also taken from locrotscale. some hacky way to cache the bones?
		local p = pl.rgmSwep:GetParent()
		pl.rgmSwep:FollowBone(ent, 0)
		pl.rgmSwep:SetParent(p)
		ent.rgmbonecached = true
	end

	RGMGetBone(pl, pl.rgm.Entity, 0)
	pl:rgmSync()

	local physchildren = rgmGetConstrainedEntities(pl.rgm.Entity)

	net.Start("rgmUpdateEntInfo")
		net.WriteEntity(ent)

		net.WriteUInt(#physchildren, 32)
		for _, ent in ipairs(physchildren) do
			net.WriteEntity(ent)
		end
	net.Send(pl)
end)

net.Receive("rgmResetGizmo", function(len, pl)
	if not pl.rgm then return end
	pl.rgm.GizmoOffset = Vector(0, 0, 0)

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
	if not pl.rgm or not IsValid(pl.rgm.Entity) then net.ReadUInt(8) net.ReadBool() return end
	local ent = pl.rgm.Entity
	local bone = net.ReadUInt(8)

	if net.ReadBool() then
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
	if not pl.rgm or not IsValid(pl.rgm.Entity) then net.ReadBool() net.ReadUInt(8) return end
	local ent = pl.rgm.Entity

	if net.ReadBool() then
		RecursiveBoneFunc(net.ReadUInt(8), ent, function(bone, param) ent:ManipulateBonePosition(bone, param) end, vector_origin)
	else
		ent:ManipulateBonePosition(net.ReadUInt(8), vector_origin)
	end

	net.Start("rgmUpdateSliders")
	net.Send(pl)
end)

net.Receive("rgmResetAng", function(len, pl)
	if not pl.rgm or not IsValid(pl.rgm.Entity) then net.ReadBool() net.ReadUInt(8) return end
	local ent = pl.rgm.Entity

	if net.ReadBool() then
		RecursiveBoneFunc(net.ReadUInt(8), ent, function(bone, param) ent:ManipulateBoneAngles(bone, param) end, angle_zero)
	else
		ent:ManipulateBoneAngles(net.ReadUInt(8), angle_zero)
	end

	net.Start("rgmUpdateSliders")
	net.Send(pl)
end)

net.Receive("rgmResetScale", function(len, pl)
	if not pl.rgm or not IsValid(pl.rgm.Entity) then net.ReadBool() net.ReadUInt(8) return end
	local ent = pl.rgm.Entity

	if net.ReadBool() then
		RecursiveBoneFunc(net.ReadUInt(8), ent, function(bone, param) ent:ManipulateBoneScale(bone, param) end, Vector(1, 1, 1))
	else
		ent:ManipulateBoneScale(net.ReadUInt(8), Vector(1, 1, 1))
	end

	net.Start("rgmUpdateSliders")
	net.Send(pl)
end)

net.Receive("rgmScaleZero", function(len, pl)
	if not pl.rgm or not IsValid(pl.rgm.Entity) then net.ReadBool() net.ReadUInt(8) return end
	local ent = pl.rgm.Entity

	if net.ReadBool() then
		RecursiveBoneFunc(net.ReadUInt(8), ent, function(bone, param) ent:ManipulateBoneScale(bone, param) end, vector_origin)
	else
		ent:ManipulateBoneScale(net.ReadUInt(8), vector_origin)
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
		net.WriteUInt(pl.rgm.Bone, 32)
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
			local offset = vector_origin

			if not IsValid(axis) or not IsValid(ent) then self:SetOperation(0) return true end
			offset = tr.HitPos

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


		local dirnorm = (collision.hitpos-axis:GetPos())
		dirnorm:Normalize()
		pl.rgm.DirNorm = dirnorm
		pl.rgm.MoveAxis = apart
		pl.rgm.KeyDown = true
		pl.rgm.Moving = true
		pl:rgmSync()
		return false

	elseif IsValid(tr.Entity) and EntityFilter(tr.Entity) then

		local entity
		entity = tr.Entity

		if entity ~= pl.rgm.Entity and self:GetClientBool("lockselected") then
			net.Start("rgmNotification")
				net.WriteUInt(RGM_NOTIFY.ENTSELECT_LOCKRESPONSE.id, 5)
			net.Send(pl)
			return false
		end

		pl.rgm.Entity = tr.Entity
		pl.rgm.ParentEntity = tr.Entity

		if not entity.rgmbonecached then -- also taken from locrotscale. some hacky way to cache the bones?
			pl.rgmSwep = self.SWEP
			local p = self.SWEP:GetParent()
			self.SWEP:FollowBone(entity, 0)
			self.SWEP:SetParent(p)
			entity.rgmbonecached = true
		end

		RGMGetBone(pl, entity, entity:TranslatePhysBoneToBone(tr.PhysicsBone))
		pl.rgm.BoneToResetTo = 0 -- used for quickswitching to root bone and back

		if ent ~= pl.rgm.ParentEntity then
			local children = rgmFindEntityChildren(pl.rgm.ParentEntity)
			local physchildren = rgmGetConstrainedEntities(pl.rgm.ParentEntity)

			net.Start("rgmUpdateLists")
				net.WriteEntity(pl.rgm.Entity)
				net.WriteUInt(#children, 32)
				for k, v in ipairs(children) do
					net.WriteEntity(v)
				end

				net.WriteUInt(#physchildren, 32)
				for _, ent in ipairs(physchildren) do
					net.WriteEntity(ent)
				end
			net.Send(pl)

			pl.rgmPosLocks = {}
			pl.rgmAngLocks = {}
			pl.rgmBoneLocks = {}
			pl.rgmEntLocks = {}
		end

		pl:rgmSync()

		net.Start("rgmSelectBoneResponse")
			net.WriteBool(pl.rgm.IsPhysBone)
			net.WriteEntity(pl.rgm.Entity)
			net.WriteUInt(pl.rgm.Bone, 32)
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
			local offset = vector_origin

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
		if axis.localizedpos ~= self:GetClientBool("localpos",true) then
			axis.localizedpos = self:GetClientBool("localpos",true)
		end
		if axis.localizedang ~= self:GetClientBool("localang",true) then
			axis.localizedang = self:GetClientBool("localang",true)
		end
		if axis.localizedoffset ~= self:GetClientBool("localoffset",true) then
			axis.localizedoffset = self:GetClientBool("localoffset",true)
		end
		if axis.relativerotate ~= self:GetClientBool("relativerotate",true) then
			axis.relativerotate = self:GetClientBool("relativerotate",true)
		end
		if axis.scalechildren ~= self:GetClientBool("scalechildren",true) then
			axis.scalechildren = self:GetClientBool("scalechildren",true)
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
						if ConstrainedAllowed:GetBool() then
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

		local physbonecount = ent:GetBoneCount() - 1
		if physbonecount == nil then return end

		if not scale then
			if IsValid(ent:GetParent()) and bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not (ent:GetClass() == "prop_ragdoll") then
				local pos, ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir,0)
				ent:SetLocalPos(pos)
				ent:SetLocalAngles(ang)
			elseif pl.rgm.IsPhysBone then

				local isik,iknum = rgm.IsIKBone(self,ent,bone)

				local pos,ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir, 1)

				local obj = ent:GetPhysicsObjectNum(bone)
				if not isik or iknum == 3 or (rotate and (iknum == 1 or iknum == 2)) then
					obj:EnableMotion(true)
					obj:Wake()
					obj:SetPos(pos)
					obj:SetAngles(ang)
					obj:EnableMotion(false)
					obj:Wake()
				elseif iknum == 2 then
					for k,v in pairs(ent.rgmIKChains) do
						if v.knee == bone then
							local intersect = apart:GetGrabPos(eyepos,eyeang)
							local obj1 = ent:GetPhysicsObjectNum(v.hip)
							local obj2 = ent:GetPhysicsObjectNum(v.foot)
							local kd = (intersect-(obj2:GetPos()+(obj1:GetPos()-obj2:GetPos())))
							kd:Normalize()
							ent.rgmIKChains[k].ikkneedir = kd*1
						end
					end
				end


				local postable = rgm.SetOffsets(self,ent,pl.rgmOffsetTable,{b = bone,p = obj:GetPos(),a = obj:GetAngles()}, pl.rgmAngLocks, pl.rgmPosLocks)

				local sbik,sbiknum = rgm.IsIKBone(self,ent,bone)
				if not sbik or sbiknum ~= 2 then
					postable[bone].dontset = true
				end
				for i=0,ent:GetPhysicsObjectCount()-1 do
					if postable[i] and not postable[i].dontset then
						local obj = ent:GetPhysicsObjectNum(i)
						local poslen = postable[i].pos:Length()
						local anglen = Vector(postable[i].ang.p,postable[i].ang.y,postable[i].ang.r):Length()

						--Temporary solution for INF and NaN decimals crashing the game (Even rounding doesnt fix it)
						if poslen > 2 and anglen > 2 then
							obj:EnableMotion(true)
							obj:Wake()
							obj:SetPos(postable[i].pos)
							obj:SetAngles(postable[i].ang)
							obj:EnableMotion(false)
							obj:Wake()
						end
					end

					if postable[i] and postable[i].locked and ConstrainedAllowed:GetBool() then
						for lockent, bones in pairs(postable[i].locked) do
							for j=0,lockent:GetPhysicsObjectCount()-1 do
								if bones[j] then
									local obj = lockent:GetPhysicsObjectNum(j)
									local poslen = bones[j].pos:Length()
									local anglen = Vector(bones[j].ang.p,bones[j].ang.y,bones[j].ang.r):Length()

									--Temporary solution for INF and NaN decimals crashing the game (Even rounding doesnt fix it)
									if poslen > 2 and anglen > 2 then
										obj:EnableMotion(true)
										obj:Wake()
										obj:SetPos(bones[j].pos)
										obj:SetAngles(bones[j].ang)
										obj:EnableMotion(false)
										obj:Wake()
									end

								end
							end
						end
					end
				end

				-- if not pl:GetNWBool("ragdollmover_keydown") then
			else
				local pos, ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir, 2, pl.rgm.StartAngle, pl.rgm.NPhysBonePos, pl.rgm.NPhysBoneAng) -- if a bone is not physics one, we pass over "start angle" thing

				ent:ManipulateBoneAngles(bone, ang)
				ent:ManipulateBonePosition(bone, pos)
			end
		else
			bone = pl.rgm.Bone
			local prevscale = ent:GetManipulateBoneScale(bone)
			local sc, ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir, 2, pl.rgm.StartAngle, pl.rgm.NPhysBonePos, pl.rgm.NPhysBoneAng, pl.rgm.NPhysBoneScale)

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
		elseif physcheck[v] then
			bone.Type = BONE_PHYSICAL
		end

		if (isphys and bone.Type == BONE_PHYSICAL) or (not isphys and bone.Type ~= BONE_PHYSICAL) then 
			newlastvalid = v
			table.insert(tab, bone)
		end

		GetRecursiveBonesExclusive(ent, v, newlastvalid, tab, physcheck, isphys, bone.depth)
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
local function CManipSlider(cpanel, text, mode, axis, min, max, dec)
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
		net.Start("rgmAdjustBone")
		net.WriteInt(mode, 3)
		net.WriteInt(axis, 3)
		net.WriteFloat(value)
		net.SendToServer()
	end

	cpanel:AddItem(slider)

	return slider
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
	parent:SetHeight(80)
	cpanel:AddItem(parent)

	local bindrot = vgui.Create("DBinder", parent)
	bindrot.Label = vgui.Create("DLabel", parent)
	bindrot:SetConVar("ragdollmover_rotatebutton")
	bindrot:SetSize(100, 50)
	bindrot:SetPos(25, 25)

	bindrot.Label:SetText("#tool.ragdollmover.bindrot")
	bindrot.Label:SetDark(true)
	bindrot.Label:SizeToContents()
	bindrot.Label:SetPos(25, 0)

	function bindrot:OnChange(keycode)
		net.Start("rgmSetToggleRot")
		net.WriteInt(keycode, 32)
		net.SendToServer()
	end

	local bindsc = vgui.Create("DBinder", parent)
	bindsc.Label = vgui.Create("DLabel", parent)
	bindsc:SetConVar("ragdollmover_scalebutton")
	bindsc:SetSize(100, 50)
	bindsc:SetPos(135, 25)

	bindsc.Label:SetText("#tool.ragdollmover.bindscale")
	bindsc.Label:SetDark(true)
	bindsc.Label:SizeToContents()
	bindsc.Label:SetPos(137, 0)

	function bindsc:OnChange(keycode)
		net.Start("rgmSetToggleScale")
		net.WriteInt(keycode, 32)
		net.SendToServer()
	end
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
	net.Start("rgmResetAll")
	net.WriteUInt(0, 8)
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
local Pos1, Pos2, Pos3, Rot1, Rot2, Rot3, Scale1, Scale2, Scale3
local Gizmo1, Gizmo2, Gizmo3
local nodes, entnodes, conentnodes
local HoveredBone, HoveredEnt
local Col4
local LockMode, LockTo = false, nil

local function SetBoneNodes(bonepanel, ent, sortedbones)

	nodes = {}

	local width = 0

	local BoneTypeSort = {
		{ Icon = "icon16/brick.png", ToolTip = "#tool.ragdollmover.physbone" },
		{ Icon = "icon16/connect.png", ToolTip = "#tool.ragdollmover.nonphysbone" },
		{ Icon = "icon16/error.png", ToolTip = "#tool.ragdollmover.proceduralbone" },
	}

	for k, v in ipairs(sortedbones) do
		local text1 = ent:GetBoneName(v.id)

		if not v.parent then
			nodes[v.id] = bonepanel:AddNode(text1)
		else
			nodes[v.id] = nodes[v.parent]:AddNode(text1)
		end

		nodes[v.id].Type = v.Type
		nodes[v.id]:SetExpanded(true)

		nodes[v.id]:SetIcon(BoneTypeSort[v.Type].Icon)
		nodes[v.id].Label:SetToolTip(BoneTypeSort[v.Type].ToolTip)

		nodes[v.id].DoClick = function()

			if not LockMode then
				net.Start("rgmSelectBone")
					net.WriteEntity(ent)
					net.WriteUInt(v.id, 32)
				net.SendToServer()
			else
				if LockMode == 1 then
					net.Start("rgmLockToBone")
						net.WriteUInt(v.id, 8)
						net.WriteUInt(LockTo, 8)
					net.SendToServer()

					if nodes[LockTo].poslock or nodes[LockTo].anglock then
						nodes[LockTo]:SetIcon("icon16/lock.png")
						nodes[LockTo].Label:SetToolTip("#tool.ragdollmover.lockedbone")
					else
						nodes[LockTo]:SetIcon(BoneTypeSort[v.Type].Icon)
						nodes[LockTo].Label:SetToolTip(BoneTypeSort[v.Type].ToolTip)
					end
				elseif LockMode == 2 then
					net.Start("rgmLockConstrained")
						net.WriteEntity(LockTo) -- In this case it isn't really "LockTo", more of "LockThis" but i was lazy so used same variables. Probably once I get to C++ stuff trying to do the same thing would be baaad
						net.WriteBool(true)
						net.WriteUInt(v.id, 8)
					net.SendToServer()

					conentnodes[LockTo]:SetIcon("icon16/brick_link.png")
					conentnodes[LockTo].Label:SetToolTip(false)
				end

				LockMode = false
				LockTo = nil
			end

		end

		nodes[v.id].DoRightClick = function()
			local pl = LocalPlayer()
			local bonemenu = DermaMenu(false, bonepanel)

			local ResetMenu = bonemenu:AddSubMenu("#tool.ragdollmover.resetmenu")

			option = ResetMenu:AddOption("#tool.ragdollmover.reset", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmResetAll")
				net.WriteUInt(v.id, 8)
				net.WriteBool(false)
				net.SendToServer()
			end)
			option:SetIcon("icon16/connect.png")

			local option = ResetMenu:AddOption("#tool.ragdollmover.resetpos", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmResetPos")
				net.WriteBool(false)
				net.WriteUInt(v.id, 8) -- with SFM studiomdl, it seems like upper limit for bones is 256 (counting 0)
				net.SendToServer()
			end)
			option:SetIcon("icon16/connect.png")

			option = ResetMenu:AddOption("#tool.ragdollmover.resetrot", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmResetAng")
				net.WriteBool(false)
				net.WriteUInt(v.id, 8)
				net.SendToServer()
			end)
			option:SetIcon("icon16/connect.png")

			option = ResetMenu:AddOption("#tool.ragdollmover.resetscale", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmResetScale")
				net.WriteBool(false)
				net.WriteUInt(v.id, 8)
				net.SendToServer()
			end)
			option:SetIcon("icon16/connect.png")

			option = ResetMenu:AddOption("#tool.ragdollmover.resetchildren", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmResetAll")
				net.WriteUInt(v.id, 8)
				net.WriteBool(true)
				net.SendToServer()
			end)
			option:SetIcon("icon16/bricks.png")

			option = ResetMenu:AddOption("#tool.ragdollmover.resetposchildren", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmResetPos")
				net.WriteBool(true)
				net.WriteUInt(v.id, 8)
				net.SendToServer()
			end)
			option:SetIcon("icon16/bricks.png")

			option = ResetMenu:AddOption("#tool.ragdollmover.resetrotchildren", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmResetAng")
				net.WriteBool(true)
				net.WriteUInt(v.id, 8)
				net.SendToServer()
			end)
			option:SetIcon("icon16/bricks.png")

			option = ResetMenu:AddOption("#tool.ragdollmover.resetscalechildren", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmResetScale")
				net.WriteBool(true)
				net.WriteUInt(v.id, 8)
				net.SendToServer()
			end)
			option:SetIcon("icon16/bricks.png")

			local ScaleZeroMenu = bonemenu:AddSubMenu("#tool.ragdollmover.scalezero")

			option = ScaleZeroMenu:AddOption("#tool.ragdollmover.bone", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmScaleZero")
				net.WriteBool(false)
				net.WriteUInt(v.id, 8)
				net.SendToServer()
			end)
			option:SetIcon("icon16/connect.png")

			option = ScaleZeroMenu:AddOption("#tool.ragdollmover.bonechildren", function()
				if not pl.rgm then return end
				if not IsValid(pl.rgm.Entity) then return end
				net.Start("rgmScaleZero")
				net.WriteBool(true)
				net.WriteUInt(v.id, 8)
				net.SendToServer()
			end)
			option:SetIcon("icon16/bricks.png")

			bonemenu:AddSpacer()

			if nodes[v.id].bonelock then

				option = bonemenu:AddOption("#tool.ragdollmover.unlockbone", function()
					if not pl.rgm then return end
					if not IsValid(pl.rgm.Entity) then return end
					net.Start("rgmUnlockToBone")
						net.WriteUInt(v.id, 8)
					net.SendToServer()
				end)

				bonemenu:AddSpacer()
			elseif nodes[v.id].Type == BONE_PHYSICAL and IsValid(pl.rgm.Entity) and pl.rgm.Entity:GetClass() == "prop_ragdoll" then

				option = bonemenu:AddOption(nodes[v.id].poslock and "#tool.ragdollmover.unlockpos" or "#tool.ragdollmover.lockpos", function()
					if not pl.rgm then return end
					if not IsValid(pl.rgm.Entity) then return end
					net.Start("rgmLockBone")
						net.WriteUInt(1, 2)
						net.WriteUInt(v.id, 8)
					net.SendToServer()
				end)
				option:SetIcon(nodes[v.id].poslock and "icon16/lock.png" or "icon16/brick.png")

				option = bonemenu:AddOption(nodes[v.id].anglock and "#tool.ragdollmover.unlockang" or "#tool.ragdollmover.lockang", function()
					if not pl.rgm then return end
					if not IsValid(pl.rgm.Entity) then return end
					net.Start("rgmLockBone")
						net.WriteUInt(2, 2)
						net.WriteUInt(v.id, 8)
					net.SendToServer()
				end)
				option:SetIcon(nodes[v.id].anglock and "icon16/lock.png" or "icon16/brick.png")

				option = bonemenu:AddOption("#tool.ragdollmover.lockbone", function()
					if not pl.rgm then return end
					if not IsValid(pl.rgm.Entity) then return end

					if LockMode == 1 then
						nodes[LockTo]:SetIcon(BoneTypeSort[nodes[LockTo].Type].Icon)
						nodes[LockTo].Label:SetToolTip(BoneTypeSort[nodes[LockTo].Type].ToolTip)
					end

					LockMode = 1
					LockTo = v.id

					surface.PlaySound("buttons/button9.wav")
					nodes[v.id]:SetIcon("icon16/brick_add.png")
					nodes[v.id].Label:SetToolTip("#tool.ragdollmover.bonetolock")
				end)
				option:SetIcon("icon16/lock.png")

				bonemenu:AddSpacer()
			end

			bonemenu:AddOption("#tool.ragdollmover.putgizmopos", function()
				local pl = LocalPlayer()
				if not pl.rgm or not IsValid(pl.rgm.Entity) then return end

				local ent = pl.rgm.Entity
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

		nodes[v.id].Label.OnCursorEntered = function()
			HoveredBone = v.id
		end

		nodes[v.id].Label.OnCursorExited = function()
			HoveredBone = nil
		end

		local XSize = nodes[v.id].Label:GetTextSize()
		local currentwidth = XSize + (v.depth * 17)
		if currentwidth > width then
			width = currentwidth
		end
	end

	bonepanel:UpdateWidth(width + 8 + 32 + 16)
end

local function RGMBuildBoneMenu(ent, bonepanel)
	bonepanel:Clear()
	if not IsValid(ent) then return end
	local sortedbones = {}

	local num = ent:GetBoneCount() - 1 -- first we find all rootbones and their children
	for v = 0, num do
		if ent:GetBoneName(v) == "__INVALIDBONE__" then continue end

		if ent:GetBoneParent(v) == -1 then
			local bone = { id = v, Type = BONE_NONPHYSICAL, depth = 1 }
			if ent:BoneHasFlag(v, 4) then -- BONE_ALWAYS_PROCEDURAL flag
				bone.Type = BONE_PROCEDURAL
			end

			table.insert(sortedbones, bone)
			GetRecursiveBones(ent, v, sortedbones, bone.depth)
		end
	end

	SetBoneNodes(bonepanel, ent, sortedbones)

	net.Start("rgmAskForPhysbones")
		net.WriteEntity(ent)
	net.SendToServer()

	if ent:IsEffectActive(EF_BONEMERGE) then
		net.Start("rgmAskForParented")
			net.WriteEntity(ent)
		net.SendToServer()
	end
end

local function ShowOnlyPhysNodes(ent, bonepanel)
	bonepanel:Clear()
	if not IsValid(ent) then return end

	net.Start("rgmAskForNodeUpdatePhysics")
		net.WriteBool(true)
		net.WriteEntity(ent)
	net.SendToServer()
end

local function ShowOnlyNonPhysNodes(ent, bonepanel)
	bonepanel:Clear()
	if not IsValid(ent) then return end

	net.Start("rgmAskForNodeUpdatePhysics")
		net.WriteBool(false)
		net.WriteEntity(ent)
	net.SendToServer()
end

local function UpdateBoneNodes(ent, bonepanel, physIDs, isphys)
	local sortedbones = {}

	local num = ent:GetBoneCount() - 1
	for v = 0, num do
		if ent:GetBoneName(v) == "__INVALIDBONE__" then continue end

		if ent:GetBoneParent(v) == -1 then
			local bone = { id = v, Type = BONE_NONPHYSICAL, depth = 1 }
			if ent:BoneHasFlag(v, 4) then
				bone.Type = BONE_PROCEDURAL
			elseif physIDs[v] then
				bone.Type = BONE_PHYSICAL
			end

			table.insert(sortedbones, bone)
			GetRecursiveBonesExclusive(ent, v, v, sortedbones, physIDs, isphys, bone.depth)
		end
	end

	SetBoneNodes(bonepanel, ent, sortedbones)

	if isphys then
		net.Start("rgmAskForPhysbones")
			net.WriteEntity(ent)
		net.SendToServer()
	end

	if ent:IsEffectActive(EF_BONEMERGE) then
		net.Start("rgmAskForParented")
			net.WriteEntity(ent)
		net.SendToServer()
	end
end

local function RGMBuildEntMenu(parent, children, entpanel)
	entpanel:Clear()
	if not IsValid(parent) then return end

	local LockSelection = GetConVar("ragdollmover_lockselected")
	local width

	entnodes = {}

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

	local XSize = entnodes[parent].Label:GetTextSize()
	width = XSize + 17

	local sortchildren = {depth = 1}

	local function RecursiveChildrenSort(parent, sorttable, depth)
		for k, v in ipairs(children) do
			if v:GetParent() ~= parent then continue end
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
				if parent:GetClass() ~= "prop_ragdoll" then
					net.Start("rgmLockConstrained")
						net.WriteEntity(ent)
						net.WriteBool(false)
					net.SendToServer()
				else

					if LockMode == 2 then
						conentnodes[LockTo]:SetIcon("icon16/brick_link.png")
						conentnodes[LockTo].Label:SetToolTip(false)
					end

					LockMode = 2
					LockTo = ent

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
		RGMBuildBoneMenu(ent, BonePanel)
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
			Pos1 = CManipSlider(ColManip, "#tool.ragdollmover.pos1", 1, 1, -300, 300, 2) --x
			Pos2 = CManipSlider(ColManip, "#tool.ragdollmover.pos2", 1, 2, -300, 300, 2) --y
			Pos3 = CManipSlider(ColManip, "#tool.ragdollmover.pos3", 1, 3, -300, 300, 2) --z
			Pos1:SetVisible(false)
			Pos2:SetVisible(false)
			Pos3:SetVisible(false)
			-- Angles
			Rot1 = CManipSlider(ColManip, "#tool.ragdollmover.rot1", 2, 1, -180, 180, 2) --pitch
			Rot2 = CManipSlider(ColManip, "#tool.ragdollmover.rot2", 2, 2, -180, 180, 2) --yaw
			Rot3 = CManipSlider(ColManip, "#tool.ragdollmover.rot3", 2, 3, -180, 180, 2) --roll
			Rot1:SetVisible(false)
			Rot2:SetVisible(false)
			Rot3:SetVisible(false)
			--Scale
			Scale1 = CManipSlider(ColManip, "#tool.ragdollmover.scale1", 3, 1, -100, 100, 2) --x
			Scale2 = CManipSlider(ColManip, "#tool.ragdollmover.scale2", 3, 2, -100, 100, 2) --y
			Scale3 = CManipSlider(ColManip, "#tool.ragdollmover.scale3", 3, 3, -100, 100, 2) --z

			CButton(ColManip, "#tool.ragdollmover.resetallbones", RGMResetAllBones)

		CCheckBox(Col4,"#tool.ragdollmover.scalechildren","ragdollmover_scalechildren")

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

	Pos1:SetValue(pos[1])
	Pos2:SetValue(pos[2])
	Pos3:SetValue(pos[3])

	Rot1:SetValue(rot[1])
	Rot2:SetValue(rot[2])
	Rot3:SetValue(rot[3])

	Scale1:SetValue(scale[1])
	Scale2:SetValue(scale[2])
	Scale3:SetValue(scale[3])

end

net.Receive("rgmUpdateSliders", function(len)
	pl = LocalPlayer()
	UpdateManipulationSliders(pl.rgm.Bone, pl.rgm.Entity)
end)

net.Receive("rgmUpdateLists", function(len)
	local ent = net.ReadEntity()
	local children, physchildren = {}, {}
	local pl = LocalPlayer()

	for i = 1, net.ReadUInt(32) do
		children[i] = net.ReadEntity()
	end

	for i = 1, net.ReadUInt(32) do
		physchildren[i] = net.ReadEntity()
	end

	if IsValid(BonePanel) then
		RGMBuildBoneMenu(ent, BonePanel)
	end
	if IsValid(EntPanel) then
		RGMBuildEntMenu(ent, children, EntPanel)
	end
	if IsValid(ConEntPanel) then
		RGMBuildConstrainedEnts(ent, physchildren, ConEntPanel)
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

	for i = 1, net.ReadUInt(32) do
		physchildren[i] = net.ReadEntity()
	end

	if IsValid(BonePanel) then
		RGMBuildBoneMenu(ent, BonePanel)
	end
	if IsValid(ConEntPanel) then
		RGMBuildConstrainedEnts(ent, physchildren, ConEntPanel)
	end
end)

net.Receive("rgmAskForPhysbonesResponse", function(len)
	local count = net.ReadUInt(8)
	for i = 0, count do
		local bone = net.ReadUInt(8)
		local poslock = net.ReadBool()
		local anglock = net.ReadBool()
		local bonelock = net.ReadBool()

		if bone then
			nodes[bone].Type = BONE_PHYSICAL
			nodes[bone].poslock = poslock
			nodes[bone].anglock = anglock
			nodes[bone].bonelock = bonelock

			if LockMode == 1 and bone == LockTo then
				nodes[bone]:SetIcon("icon16/brick_add.png")
				nodes[bone].Label:SetToolTip("#tool.ragdollmover.bonetolock")
			elseif bonelock then
				nodes[bone]:SetIcon("icon16/lock_go.png")
				nodes[bone].Label:SetToolTip("#tool.ragdollmover.lockedbonetobone")
			elseif anglock or poslock then
				nodes[bone]:SetIcon("icon16/lock.png")
				nodes[bone].Label:SetToolTip("#tool.ragdollmover.lockedbone")
			else
				nodes[bone]:SetIcon("icon16/brick.png")
				nodes[bone].Label:SetToolTip("#tool.ragdollmover.physbone")
			end
		end
	end
end)

net.Receive("rgmAskForParentedResponse", function(len)
	local count = net.ReadUInt(32)

	for i = 1, count do
		local bone = net.ReadUInt(32)

		if nodes[bone] then
			nodes[bone].Type = BONE_PARENTED
			nodes[bone]:SetIcon("icon16/stop.png")
			nodes[bone].Label:SetToolTip("#tool.ragdollmover.parentedbone")
		end
	end
end)

net.Receive("rgmLockBoneResponse", function(len)
	local boneid = net.ReadUInt(32)
	local poslock = net.ReadBool()
	local anglock = net.ReadBool()

	nodes[boneid].poslock = poslock
	nodes[boneid].anglock = anglock

	if poslock or anglock then
		nodes[boneid]:SetIcon("icon16/lock.png")
		nodes[boneid].Label:SetToolTip("#tool.ragdollmover.lockedbone")
	else
		nodes[boneid]:SetIcon("icon16/brick.png")
		nodes[boneid].Label:SetToolTip("#tool.ragdollmover.physbone")
	end
end)

net.Receive("rgmLockToBoneResponse", function(len)
	local lockbone = net.ReadUInt(8)

	if nodes[lockbone] then
		nodes[lockbone].bonelock = true
		nodes[lockbone].poslock = false
		nodes[lockbone].anglock = false
		nodes[lockbone]:SetIcon("icon16/lock_go.png")
		nodes[lockbone].Label:SetToolTip("#tool.ragdollmover.lockedbonetobone")

		rgmDoNotification(RGM_NOTIFY.BONELOCK_SUCCESS.id)
	end
end)

net.Receive("rgmUnlockToBoneResponse", function(len)
	local unlockbone = net.ReadUInt(8)

	if nodes[unlockbone] then
		nodes[unlockbone].bonelock = false
		nodes[unlockbone]:SetIcon("icon16/brick.png")
		nodes[unlockbone].Label:SetToolTip("#tool.ragdollmover.physbone")
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
		Rot1:SetVisible(inverted)
		Rot2:SetVisible(inverted)
		Rot3:SetVisible(inverted)
	end

	local isphys = net.ReadBool()
	local ent = net.ReadEntity()
	local boneid = net.ReadUInt(32)

	if IsValid(ent) and boneid then
		UpdateManipulationSliders(boneid, ent)
	end

	if nodes then
		if ent:GetClass() == "prop_ragdoll" and isphys and nodes[boneid] then
			SetVisiblePhysControls(true)
		else
			SetVisiblePhysControls(false)
		end
	end

	if IsValid(BonePanel) and nodes then
		BonePanel:SetSelectedItem(nodes[boneid])

		Col4:InvalidateLayout()
	end
end)

net.Receive("rgmAskForNodeUpdatePhysicsResponse", function(len)
	local isphys = net.ReadBool()
	local ent = net.ReadEntity()
	local physIDs = {}

	for i = 0, net.ReadUInt(8) do
		local id = net.ReadUInt(8)
		physIDs[id] = true
	end

	if not IsValid(ent) or not IsValid(BonePanel) then return end
	UpdateBoneNodes(ent, BonePanel, physIDs, isphys)
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
	if IsValid(ent) and EntityFilter(ent) and self:GetClientBool("drawskeleton") then
		rgm.DrawSkeleton(ent)
	end

	if IsValid(ent) and EntityFilter(ent) and HoveredBone then
		rgm.DrawBoneConnections(ent, HoveredBone)
		rgm.DrawBoneName(ent,HoveredBone)
	elseif IsValid(HoveredEnt) and EntityFilter(HoveredEnt) then
		rgm.DrawEntName(HoveredEnt)
	elseif IsValid(tr.Entity) and EntityFilter(tr.Entity) and (not bone or aimedbone ~= bone or tr.Entity ~= pl.rgm.Entity) and not moving then
		rgm.DrawBoneConnections(tr.Entity, aimedbone)
		rgm.DrawBoneName(tr.Entity,aimedbone)
	end

end

end
