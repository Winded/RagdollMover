
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm, isphys, startGrab, NPhysPos)
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos,pnorm)
	local pos, ang
	
	if isphys then
		local obj = ent:GetPhysicsObjectNum(bone)
		ang = obj:GetAngles()
		pos = LocalToWorld(offpos,Angle(0,0,0),intersect,self:GetAngles())
	else
		ang = ent:GetManipulateBoneAngles(bone)
		pos = ent:GetManipulateBonePosition(bone)
	end

	return pos,ang
end