
ENT.Type = "anim"
ENT.Base = "rgm_axis_disc"

function ENT:TestCollision(pl,scale)
	-- return self.BaseClass.TestCollision(self,pl,scale,1.15,1.35)
	local eyepos,eyeang = rgm.EyePosAng(pl)
	local intersect = self:GetGrabPos(eyepos,eyeang)
	local distmin = 1.15*scale
	local distmax = 1.35*scale
	local dist = intersect:Distance(self:GetPos())
	if dist >= distmin and dist <= distmax then
		return {axis = self,hitpos = intersect}
	end
	return false
end
