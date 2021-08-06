
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm, isphys, startAngle, garbage, NPhysAngle) -- initially i had a table instead of separate things for initial bone pos and angle, but sync command can't handle tables and i thought implementing a way to handle those would be too much hassle
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos,pnorm)
	local localized = self:WorldToLocal(intersect)
	local _p, _a
	
	if isphys then
		localized = Vector(localized.y,localized.z,0):Angle()
		local pos = self:GetPos()
		local ang = self:LocalToWorldAngles(Angle(0,0,localized.y))
		_p,_a = LocalToWorld(Vector(0,0,0),offang,pos,ang)
		_p = pos
	else
		_a = ent:GetManipulateBoneAngles(bone)
		localized = WorldToLocal(localized, localized:Angle(), Vector(0, 0, 0), startAngle:Angle())
		localized = Vector(localized.x, localized.z, 0):Angle()
		local rotateang = NPhysAngle[self.axistype] + localized.y -- putting it in another variable to avoid constant adding onto the angle variable
		_a[self.axistype] = rotateang
		_p = ent:GetManipulateBonePosition(bone)
	end
	
	return _p,_a
end