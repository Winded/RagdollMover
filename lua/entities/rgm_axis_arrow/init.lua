
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm, movetype, StartGrab, NPhysPos)
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos)
	local localized = self:WorldToLocal(intersect)
	local axis = self:GetParent()
	local offset = axis.Owner.rgm.GizmoOffset
	if axis.localizedoffset then
		offset = LocalToWorld(offset, Angle(0, 0, 0), axis:GetPos(), axis.LocalAngles)
		offset =  offset - axis:GetPos()
	end
	local pos, ang

	if movetype == 1 then
		local obj = ent:GetPhysicsObjectNum(bone)
		localized = Vector(localized.x,0,0)
		intersect = self:LocalToWorld(localized)
		ang = obj:GetAngles()
		pos = LocalToWorld(Vector(offpos.x,0,0),Angle(0,0,0),intersect - offset,self:GetAngles())
	elseif movetype == 2 then
		pos = ent:GetManipulateBonePosition(bone)
		localized = Vector(localized.x - StartGrab.x,0,0)
		local posadd = NPhysPos[self.axistype] + localized.x
		ang = ent:GetManipulateBoneAngles(bone)
		pos[self.axistype] = posadd
	elseif movetype == 0 then
		localized = Vector(localized.x,0,0)
		intersect = self:LocalToWorld(localized)
		ang = ent:GetLocalAngles()
		pos = LocalToWorld(Vector(offpos.x,0,0),Angle(0,0,0),intersect - offset, self:GetAngles())
		pos = ent:GetParent():WorldToLocal(pos)
	end
	return pos,ang
end
