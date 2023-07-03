
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm, movetype, garbage, startGrab, garbage, garbage, NPhysScale)
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos,pnorm)
	local pos, ang
	local pl = self:GetParent().Owner

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

	finalpos = NPhysScale + localized
	ang = ent:GetManipulateBoneAngles(bone)
	pos = finalpos

	return pos,ang
end
