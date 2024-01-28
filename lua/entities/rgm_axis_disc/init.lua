
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local VECTOR_FRONT, VECTOR_SIDE = Vector(1, 0, 0), Vector(0, 1, 0)

local function ConvertVector(vec, axistype)
	local result

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

function ENT:ProcessMovement(_, offang, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, snapamount, startangle, _, nphysangle) -- initially i had a table instead of separate things for initial bone pos and angle, but sync command can't handle tables and i thought implementing a way to handle those would be too much hassle
	local intersect = self:GetGrabPos(eyepos, eyeang, ppos, pnorm)
	local localized = self:WorldToLocal(intersect)
	local _p, _a
	local pl = self:GetParent().Owner
	local axistable = {
		(self:GetParent():LocalToWorld(VECTOR_SIDE) - self:GetPos()):Angle(),
		(self:GetParent():LocalToWorld(vector_up) - self:GetPos()):Angle(),
		(self:GetParent():LocalToWorld(VECTOR_FRONT) - self:GetPos()):Angle(),
		(self:GetPos() - pl:EyePos()):Angle()
	}

	local mfmod = math.fmod
	local axis = self:GetParent()

	if movetype == 1 then
		local offset = axis.Owner.rgm.GizmoOffset
		local entoffset = vector_origin
		if axis.localoffset and not axis.relativerotate then
			offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
			offset = offset - axis:GetPos()
		end
		if ent.rgmPRoffset then
			entoffset = LocalToWorld(ent.rgmPRoffset, angle_zero, axis:GetPos(), axis.LocalAngles)
			entoffset = entoffset - axis:GetPos()
			offset = offset + entoffset
		end

		localized = Vector(localized.y, localized.z, 0):Angle()
		startangle = Vector(startangle.y, startangle.z, 0):Angle()

		local rotationangle = localized.y
		if snapamount ~= 0 then
			local localAng = mfmod(localized.y, 360)
			if localAng > 181 then localAng = localAng - 360 end
			if localAng < -181 then localAng = localAng + 360 end

			local localStart = mfmod(startangle.y, 360)
			if localStart > 181 then localStart = localStart - 360 end
			if localStart < -181 then localStart = localStart + 360 end

			local diff = mfmod(localStart - localAng, 360)
			if diff > 181 then diff = diff - 360 end
			if diff < -181 then diff = diff + 360 end

			local mathfunc = nil
			if diff >= 0 then
				mathfunc = math.floor
			else
				mathfunc = math.ceil
			end

			rotationangle = startangle.y - (mathfunc(diff / snapamount) * snapamount)
		end

		local pos = self:GetPos()
		local ang = self:LocalToWorldAngles(Angle(0, 0, rotationangle))
		if axis.relativerotate then
			offset = WorldToLocal(axis.BonePos, angle_zero, axis:GetPos(), axis.LocalAngles)
			_p, _a = LocalToWorld(vector_origin, offang, pos, ang)
			_p = LocalToWorld(offset, _a, pos, _a)
		else
			_p, _a = LocalToWorld(vector_origin, offang, pos, ang)
			_p = pos - offset
		end
	elseif movetype == 2 then
		local rotateang, axisangle
		axisangle = axistable[self.axistype]

		local _, boneang = ent:GetBonePosition(bone)
		if ent:GetClass() == "prop_physics" then
			local manang = ent:GetManipulateBoneAngles(bone)
			manang:Normalize()

			_, boneang = LocalToWorld(vector_origin, Angle(0, 0, -manang[3]), vector_origin, boneang)
			_, boneang = LocalToWorld(vector_origin, Angle(-manang[1], 0, 0), vector_origin, boneang)
			_, boneang = LocalToWorld(vector_origin, Angle(0, -manang[2], 0), vector_origin, boneang)
		else
			if ent:GetBoneParent(bone) ~= -1 then
				local _ , pang = ent:GetBonePosition(ent:GetBoneParent(bone))

				local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
				_, boneang = LocalToWorld(vector_origin, diff, vector_origin, axis.GizmoParent)
			end
		end
		local startlocal = LocalToWorld(startangle, startangle:Angle(), vector_origin, axisangle) -- first we get our vectors into world coordinates, relative to the axis angles
		localized = LocalToWorld(localized, localized:Angle(), vector_origin, axisangle)
		localized = WorldToLocal(localized, localized:Angle(), vector_origin, boneang) -- then convert that vector to the angles of the bone
		startlocal = WorldToLocal(startlocal, startlocal:Angle(), vector_origin, boneang)

		localized = ConvertVector(localized, self.axistype)
		startlocal = ConvertVector(startlocal, self.axistype)

		localized = localized:Angle() - startlocal:Angle()

		local rotationangle = localized.y
		if snapamount ~= 0 then
			local localAng = mfmod(localized.y, 360)
			if localAng > 181 then localAng = localAng - 360 end
			if localAng < -181 then localAng = localAng + 360 end

			local mathfunc = math.floor
			if localAng < 0 then mathfunc = math.ceil end

			rotationangle = mathfunc(localAng / snapamount) * snapamount
		end

		if self.axistype == 4 then
			rotateang = nphysangle + localized
			_a = rotateang
		else
			_a = ent:GetManipulateBoneAngles(bone)
			rotateang = nphysangle[self.axistype] + rotationangle
			_a[self.axistype] = rotateang
		end

		if axis.relativerotate then
			local pos = axis:GetPos()
			local offset

			local worldang
			_p, worldang = LocalToWorld(vector_origin, _a, pos, boneang)
			if axis.localoffset then
				offset = -pl.rgm.GizmoOffset
				_p = LocalToWorld(offset, axis.LocalAngles, _p, worldang)
			else
				local _, oldang = LocalToWorld(vector_origin, nphysangle, vector_origin, axis.LocalAngles)
				offset = WorldToLocal(axis.BonePos, angle_zero, axis:GetPos(), oldang)
				_p = LocalToWorld(offset, angle_zero, _p, worldang)
			end
			_p = WorldToLocal(_p, angle_zero, axis.BonePos, axis.GizmoParent)
			local nonphyspos = WorldToLocal(axis.BonePos, angle_zero, axis.NMBonePos, axis.GizmoParent)
			_p = _p + nonphyspos
		else
			_p = ent:GetManipulateBonePosition(bone)
		end

	elseif movetype == 0 then
		local offset = axis.Owner.rgm.GizmoOffset
		local entoffset = vector_origin
		if axis.localoffset and not axis.relativerotate then
			offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
			offset = offset - axis:GetPos()
		end
		if ent.rgmPRoffset then
			entoffset = LocalToWorld(ent.rgmPRoffset, angle_zero, axis:GetPos(), axis.LocalAngles)
			entoffset = entoffset - axis:GetPos()
			offset = offset + entoffset
		end

		localized = Vector(localized.y, localized.z, 0):Angle()
		startangle = Vector(startangle.y, startangle.z, 0):Angle()

		local rotationangle = localized.y
		if snapamount ~= 0 then
			local localAng = mfmod(localized.y, 360)
			if localAng > 181 then localAng = localAng - 360 end
			if localAng < -181 then localAng = localAng + 360 end

			local localStart = mfmod(startangle.y, 360)
			if localStart > 181 then localStart = localStart - 360 end
			if localStart < -181 then localStart = localStart + 360 end

			local diff = mfmod(localStart - localAng, 360)
			if diff > 181 then diff = diff - 360 end
			if diff < -181 then diff = diff + 360 end

			local mathfunc = nil
			if diff >= 0 then
				mathfunc = math.floor
			else
				mathfunc = math.ceil
			end

			rotationangle = startangle.y - (mathfunc(diff / snapamount) * snapamount)
		end

		local pos = self:GetPos()
		local ang = self:LocalToWorldAngles(Angle(0, 0, rotationangle))
		if axis.relativerotate then
			offset = WorldToLocal(axis.BonePos, angle_zero, axis:GetPos(), axis.LocalAngles)
			_p, _a = LocalToWorld(vector_origin, offang, pos, ang)
			_p = LocalToWorld(offset, _a, pos, _a)
			_a = ent:GetParent():WorldToLocalAngles(_a)
			_p = ent:GetParent():WorldToLocal(_p)
		else
			_p, _a = LocalToWorld(vector_origin, offang, pos, ang)
			_p = pos - offset
			_a = ent:GetParent():WorldToLocalAngles(_a)
			_p = ent:GetParent():WorldToLocal(_p)
		end
	end

	return _p, _a
end
