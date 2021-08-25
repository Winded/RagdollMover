
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local function ConvertVector(vec, axistype)
	local rotationtable, result
	
	if axistype == 1 then
		result = Vector(-vec.x, vec.z, 0)
	elseif axistype == 2 then
		result = Vector(vec.x, vec.y, 0)
	elseif axistype == 3 then
		result = Vector(vec.y, vec.z, 0)
	else
		result = vec
	end

	return result
end

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm, isphys, startAngle, garbage, NPhysAngle) -- initially i had a table instead of separate things for initial bone pos and angle, but sync command can't handle tables and i thought implementing a way to handle those would be too much hassle
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos,pnorm)
	local localized = self:WorldToLocal(intersect)
	local _p, _a
	local pl = self:GetParent().Owner
	local axistable = {
		(self:GetParent():LocalToWorld(Vector(0,1,0)) - self:GetPos()):Angle(),
		(self:GetParent():LocalToWorld(Vector(0,0,1)) - self:GetPos()):Angle(),
		(self:GetParent():LocalToWorld(Vector(1,0,0)) - self:GetPos()):Angle(),
		(self:GetPos()-pl:EyePos()):Angle()
	}
	
	
	if isphys then
		localized = Vector(localized.y,localized.z,0):Angle()
		local pos = self:GetPos()
		local ang = self:LocalToWorldAngles(Angle(0,0,localized.y))
		_p,_a = LocalToWorld(Vector(0,0,0),offang,pos,ang)
		_p = pos
	else
		local rotateang, axisangle
		axisangle = axistable[self.axistype]
--[[	_a = ent:GetManipulateBoneAngles(bone)
		localized = WorldToLocal(localized, localized:Angle(), Vector(0, 0, 0), startAngle:Angle())
		localized = Vector(localized.x, localized.z, 0):Angle()
		rotateang = NPhysAngle[self.axistype] + localized.y -- putting it in another variable to avoid constant adding onto the angle variable
		_a[self.axistype] = rotateang]]
		
		local _, boneang = ent:GetBonePosition(bone)
		local startlocal = LocalToWorld(startAngle, startAngle:Angle(), Vector(0,0,0), axisangle) -- first we get our vectors into world coordinates, relative to the axis angles
		localized = LocalToWorld(localized, localized:Angle(), Vector(0,0,0), axisangle)
		localized = WorldToLocal(localized, localized:Angle(), Vector(0,0,0), boneang) -- then convert that vector to the angles of the bone
		startlocal = WorldToLocal(startlocal, startlocal:Angle(), Vector(0,0,0), boneang)

		localized = ConvertVector(localized, self.axistype)
		startlocal = ConvertVector(startlocal, self.axistype)
		
		localized = localized:Angle() - startlocal:Angle()

		if self.axistype == 4 then
			 rotateang = NPhysAngle + localized
			 _a = rotateang
		else
			_a = ent:GetManipulateBoneAngles(bone)
			rotateang = NPhysAngle[self.axistype] + localized.y
			_a[self.axistype] = rotateang
		end
		
		
		_p = ent:GetManipulateBonePosition(bone)
	end
	
	return _p,_a
end
