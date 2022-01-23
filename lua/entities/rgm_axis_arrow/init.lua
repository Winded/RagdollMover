
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm, isphys, StartGrab, NPhysPos)
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos)
	local localized = self:WorldToLocal(intersect)
	local pos, ang

	if isphys then
		local _a
		local obj = ent:GetPhysicsObjectNum(bone)
		localized = Vector(localized.x,0,0)
		intersect = self:LocalToWorld(localized)
		ang = obj:GetAngles()
		pos,_a = LocalToWorld(Vector(offpos.x,0,0),Angle(0,0,0),intersect,self:GetAngles())
	else
		pos = ent:GetManipulateBonePosition(bone)
		localized = Vector(localized.x - StartGrab.x,0,0)
		local posadd = NPhysPos[self.axistype] + localized.x
		ang = ent:GetManipulateBoneAngles(bone)
		pos[self.axistype] = posadd
	end
	return pos,ang
end