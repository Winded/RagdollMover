
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm,movetype,_,startGrab,NPhysPos,_,_,tracepos)
	local intersect = tracepos
	if not intersect then
		intersect = self:GetGrabPos(eyepos,eyeang,ppos,pnorm)
	end

	local axis = self:GetParent()
	local offset = axis.Owner.rgm.GizmoOffset
	if axis.localizedoffset then
		offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
		offset =  offset - axis:GetPos()
	end
	local pos, ang
	local pl = self:GetParent().Owner

	if movetype == 1 then
		local obj = ent:GetPhysicsObjectNum(bone)
		ang = obj:GetAngles()
		pos = LocalToWorld(offpos,angle_zero,intersect - offset,self:GetAngles())
	elseif movetype == 2 then
		local localized, startmove, finalpos, boneang
		if ent:GetBoneParent(bone) ~= -1 then
			local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
			boneang = matrix:GetAngles()
		else
			if IsValid(ent) then
				boneang = ent:GetAngles()
			else
				boneang = angle_zero
			end
		end

		localized = LocalToWorld(offpos,angle_zero,intersect,self:GetAngles())
		localized = WorldToLocal(localized, angle_zero, self:GetPos(), boneang)

		finalpos = NPhysPos + localized
		ang = ent:GetManipulateBoneAngles(bone)
		pos = finalpos
	elseif movetype == 0 then
		ang = ent:GetLocalAngles()
		pos = LocalToWorld(offpos,angle_zero,intersect - offset,self:GetAngles())
		pos = ent:GetParent():WorldToLocal(pos)
	end

	return pos,ang
end
