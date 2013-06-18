
ENT.Type = "anim";
ENT.Base = "rgm_axis_part";

function ENT:SharedInitialize()

	self.BaseClass.Initialize(self);

end

---
-- Test player's eye trace against the axis, and returns rgm.Trace
---
function ENT:GetTrace()
	
	local eyepos, eyeang = rgm.EyePosAng(self:GetGizmo():GetManipulator():GetPlayer());
	
	local intersect = rgm.IntersectRayWithPlane(self:GetPos(), self:GetAngles():Forward(), eyepos, eyeang:Forward());
	
	local distmin = 0.9 * self:GetScale();
	local distmax = 1.1 * self:GetScale();
	local dist = intersect:Distance(self:GetPos());
	
	if dist >= distmin and dist <= distmax then
		local lpos = self:WorldToLocal(intersect);
		return rgm.Trace(true, self:GetManipulator(), self:GetGizmo(), self, intersect, lpos);
	end
	
	return rgm.Trace(false);
	
end