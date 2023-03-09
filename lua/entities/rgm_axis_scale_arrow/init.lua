
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm, movetype, StartGrab, garbage, garbage, NPhysScale)
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos)
	local localized = self:WorldToLocal(intersect)
	local pos, ang

	pos = ent:GetManipulateBoneScale(bone)
	localized = Vector(localized.x - StartGrab.x,0,0)
	local posadd = NPhysScale[self.axistype] + localized.x
	ang = ent:GetManipulateBoneAngles(bone)
	pos[self.axistype] = posadd
	return pos,ang
end
