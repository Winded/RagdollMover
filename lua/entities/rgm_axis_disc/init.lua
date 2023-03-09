
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

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm, movetype, startAngle, garbage, NPhysAngle) -- initially i had a table instead of separate things for initial bone pos and angle, but sync command can't handle tables and i thought implementing a way to handle those would be too much hassle
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


	if movetype == 1 then
		local axis = self:GetParent()
		local offset = axis.Owner.rgm.GizmoOffset
		if axis.localizedoffset and not axis.relativerotate then
			offset = LocalToWorld(offset, Angle(0,0,0), axis:GetPos(), axis.LocalAngles)
			offset = offset - axis:GetPos()
		end

		localized = Vector(localized.y,localized.z,0):Angle()
		local pos = self:GetPos()
		local ang = self:LocalToWorldAngles(Angle(0,0,localized.y))
		if axis.relativerotate then
			offset = WorldToLocal(axis.BonePos, Angle(0, 0, 0), axis:GetPos(), axis.LocalAngles)
			_p,_a = LocalToWorld(Vector(0,0,0),offang,pos,ang)
			_p = LocalToWorld(offset, _a, pos, _a)
		else
			_p,_a = LocalToWorld(Vector(0,0,0),offang,pos,ang)
			_p = pos - offset
		end
	elseif movetype == 2 then
		local rotateang, axisangle
		axisangle = axistable[self.axistype]

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
	elseif movetype == 0 then
		local axis = self:GetParent()
		local offset = axis.Owner.rgm.GizmoOffset
		if axis.localizedoffset and not axis.relativerotate then
			offset = LocalToWorld(offset, Angle(0,0,0), axis:GetPos(), axis.LocalAngles)
			offset = offset - axis:GetPos()
		end

		localized = Vector(localized.y,localized.z,0):Angle()
		local pos = self:GetPos()
		local ang = self:LocalToWorldAngles(Angle(0,0,localized.y))
		if axis.relativerotate then
			offset = WorldToLocal(axis.BonePos, Angle(0, 0, 0), axis:GetPos(), axis.LocalAngles)
			_p,_a = LocalToWorld(Vector(0,0,0),offang,pos,ang)
			_p = LocalToWorld(offset, _a, pos, _a)
			_a = ent:GetParent():WorldToLocalAngles(_a)
			_p = ent:GetParent():WorldToLocal(_p)
		else
			_p,_a = LocalToWorld(Vector(0,0,0),offang,pos,ang)
			_p = pos - offset
			_a = ent:GetParent():WorldToLocalAngles(_a)
			_p = ent:GetParent():WorldToLocal(_p)
		end
	end

	return _p,_a
end
