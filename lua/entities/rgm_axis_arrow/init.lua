
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos, _, eyepos, eyeang, ent, bone, ppos, _, movetype, _, _, nphyspos)
	local intersect = self:GetGrabPos(eyepos, eyeang, ppos)
	local axis = self:GetParent()
	local parent = ent:GetParent()
	local arrowAng = axis:LocalToWorldAngles(self.DefAngle)
	local localized = WorldToLocal(intersect, angle_zero, axis:GetPos(), arrowAng)
	local offset = axis.Owner.rgm.GizmoOffset
	local entoffset = vector_origin
	if axis.localoffset then
		offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
		offset =  offset - axis:GetPos()
	end
	if ent.rgmPRoffset then
		entoffset = LocalToWorld(ent.rgmPRoffset, angle_zero, axis:GetPos(), axis.LocalAngles)
		entoffset = entoffset - axis:GetPos()
		offset = offset + entoffset
	end
	local pos, ang
	local _, selfangle = LocalToWorld(vector_origin, self.DefAngle, vector_origin, axis:GetAngles()) --self:GetAngles()

	if movetype == 1 then
		local obj = ent:GetPhysicsObjectNum(bone)
		localized = Vector(localized.x, 0, 0)
		intersect = LocalToWorld(localized, angle_zero, axis:GetPos(), arrowAng)
		ang = obj:GetAngles()
		pos = LocalToWorld(Vector(offpos.x, 0, 0), angle_zero, intersect - offset, selfangle)
	elseif movetype == 2 then
		local finalpos, boneang
		local pl = self:GetParent().Owner
		local advbones = nil
		if ent:GetClass() == "ent_advbonemerge" then
			advbones = ent.AdvBone_BoneInfo
		end

		if axis.EntAdvMerged then
			if parent.AttachedEntity then parent = parent.AttachedEntity end
			local funang
			if pl.rgm.GizmoParentID ~= -1 then
				local physobj = parent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
				_, funang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
			else
				_, funang = LocalToWorld(vector_origin, axis.GizmoAng, parent:GetPos(), parent:GetAngles())
			end

			local pbone = parent:LookupBone(advbones[bone].parent) -- may need to make an exception if the bone doesn't exist for some reason, but i think adv bonemerge would handle that already
			local matrix = parent:GetBoneMatrix(pbone)
			boneang = matrix:GetAngles()

			local _ , pang = parent:GetBonePosition(pbone)

			local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
			_, boneang = LocalToWorld(vector_origin, diff, vector_origin, funang)
		elseif ent:GetBoneParent(bone) ~= -1 then
			local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
			boneang = matrix:GetAngles()
			if not (ent:GetClass() == "prop_physics") then
				local _ , pang = ent:GetBonePosition(ent:GetBoneParent(bone))

				local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
				_, boneang = LocalToWorld(vector_origin, diff, vector_origin, axis.GizmoParent)
			end
		else
			if IsValid(ent) then
				boneang = ent:GetAngles()
			else
				boneang = angle_zero
			end
		end

		intersect = self:LocalToWorld(Vector(localized.x, 0, 0))
		localized = LocalToWorld(Vector(offpos.x, 0, 0), angle_zero, intersect, self:GetAngles())
		localized = WorldToLocal(localized, angle_zero, self:GetPos(), boneang)

		finalpos = nphyspos + localized
		ang = ent:GetManipulateBoneAngles(bone)
		pos = finalpos
	elseif movetype == 0 then
		localized = Vector(localized.x, 0, 0)
		intersect = self:LocalToWorld(localized)
		ang = ent:GetLocalAngles()
		pos = LocalToWorld(Vector(offpos.x, 0, 0), angle_zero, intersect - offset, selfangle)
		pos = parent:WorldToLocal(pos)
	end
	return pos, ang
end
