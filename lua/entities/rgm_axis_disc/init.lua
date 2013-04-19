
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm)
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos,pnorm)
	local localized = self:WorldToLocal(intersect)
	localized = Vector(localized.y,localized.z,0):Angle()
	local pos = self:GetPos()
	local ang = self:LocalToWorldAngles(Angle(0,0,localized.y))
	local _p,_a = LocalToWorld(Vector(0,0,0),offang,pos,ang)
	return pos,_a
end