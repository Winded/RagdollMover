
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm, isphys, startGrab, NPhysPos)
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos,pnorm)
	local pos, ang
	local pl = self:GetParent().Owner
	
	if isphys then
		local obj = ent:GetPhysicsObjectNum(bone)
		ang = obj:GetAngles()
		pos = LocalToWorld(offpos,Angle(0,0,0),intersect,self:GetAngles())
	else
		local localized, startmove, finalpos, boneang
		if ent:GetBoneParent(bone) ~= -1 then
			local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
			boneang = matrix:GetAngles();
		else
			if IsValid(pl.rgm.EffectBase) then
				boneang = pl.rgm.EffectBase:GetAngles()
			else
				boneang = Angle(0,0,0)
			end
		end
		
		localized = LocalToWorld(offpos,Angle(0,0,0),intersect,self:GetAngles())
		localized = WorldToLocal(localized, Angle(0,0,0), self:GetPos(), boneang)

		finalpos = NPhysPos + localized
		ang = ent:GetManipulateBoneAngles(bone)
		pos = finalpos
	end

	return pos,ang
end