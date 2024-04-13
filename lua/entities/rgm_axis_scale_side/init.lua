
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos, offang, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, _, startgrab, _, _, nphysscale)
	local intersect = self:GetGrabPos(eyepos, eyeang, ppos, pnorm)
	local pos, ang
	local pl = self:GetParent().Owner
	local axis = self:GetParent()

	local localized, finalpos, boneang
	if axis.EntAdvMerged then
		local parent = ent:GetParent()
		if parent.AttachedEntity then parent = parent.AttachedEntity end
		local funang
		if pl.rgm.GizmoParentID ~= -1 then
			local physobj = parent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
			_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
		else
			_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, parent:GetPos(), parent:GetAngles())
		end
		if axis.EntAdvMerged then
			_, boneang = LocalToWorld(vector_origin, ent:GetManipulateBoneAngles(bone), vector_origin, boneang)
		end
	elseif ent:GetBoneCount() ~= 0 then
		if axis.GizmoAng then
			if pl.rgm.GizmoParentID ~= -1 then
				local physobj = ent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
				_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
			else
				_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, ent:GetPos(), ent:GetAngles())
			end
		else
			local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
			boneang = matrix:GetAngles()
		end
	else
		if IsValid(ent) then
			boneang = ent:GetAngles()
		else
			boneang = angle_zero
		end
	end

	localized = LocalToWorld(offpos, angle_zero, intersect, self:GetAngles())
	localized = WorldToLocal(localized, angle_zero, self:GetPos(), boneang)

	finalpos = nphysscale + localized
	ang = ent:GetManipulateBoneAngles(bone)
	pos = finalpos

	return pos, ang
end
