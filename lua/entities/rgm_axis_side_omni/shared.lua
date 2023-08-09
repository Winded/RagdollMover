
ENT.Type = "anim"
ENT.Base = "rgm_axis_side"

function ENT:TestCollision(pl,scale)
	local Type = self:GetNWInt("type",1)
	local eyepos,eyeang = rgm.EyePosAng(pl)
	local intersect = self:GetGrabPos(eyepos,eyeang)
	local localized = self:WorldToLocal(intersect)
	local distmin1 = Vector(-0.075*scale, scale*(-0.08), scale*(-0.08))
	local distmax1 = Vector(0.075*scale, scale*0.08, scale*0.08)
	if (localized.x >= distmin1.x and localized.x <= distmax1.x
	and localized.y >= distmin1.y and localized.y <= distmax1.y
	and localized.z >= distmin1.z and localized.z <= distmax1.z) then
		return {axis = self,hitpos = intersect}
	end
	return false
end
