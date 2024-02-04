
ENT.Type = "anim"
ENT.Base = "rgm_axis_part"

function ENT:GetGrabPos(eyepos, eyeang, ppos)
	local pos = eyepos
	local norm = eyeang:Forward()
	local planepos = self:GetPos()
	if ppos then planepos = ppos*1 end
	local planenorm = self:WorldToLocalAngles(self:GetAngles():Up():Angle())
	planenorm = Angle(planenorm.p, self:WorldToLocalAngles((self:GetPos() - eyepos):Angle()).y, planenorm.r)
	planenorm = self:LocalToWorldAngles(planenorm):Forward()
	--local planenorm = self:GetAngles():Up()
	local intersect = rgm.IntersectRayWithPlane(planepos, planenorm, pos, norm)
	return intersect
end

function ENT:TestCollision(pl, scale)
	local eyepos, eyeang = rgm.EyePosAng(pl)
	local intersect = self:GetGrabPos(eyepos, eyeang)
	local localized = self:WorldToLocal(intersect)
	local distmin = Vector(0, -0.075 * scale, -0.075 * scale)
	local distmax = Vector(1 * scale, 0.075 * scale, 0.075 * scale)
	if localized.x >= distmin.x and localized.x <= distmax.x
	and localized.y >= distmin.y and localized.y <= distmax.y
	and localized.z >= distmin.z and localized.z <= distmax.z then
		return {axis = self, hitpos = intersect}
	end
	return false
end
