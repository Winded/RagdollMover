
ENT.Type = "anim"
ENT.Base = "rgm_axis_part"

function ENT:TestCollision(pl,scale,minmult,maxmult)
	local eyepos,eyeang = rgm.EyePosAng(pl)
	local intersect = self:GetGrabPos(eyepos,eyeang)
	local distmin, distmax
	if not minmult or not maxmult then
		distmin = 0.9*scale
		distmax = 1.1*scale
	else
		distmin = minmult*scale
		distmax = maxmult*scale
	end
	local dist = intersect:Distance(self:GetPos())
	if dist >= distmin and dist <= distmax then
		return {axis = self,hitpos = intersect}
	end
	return false
end
