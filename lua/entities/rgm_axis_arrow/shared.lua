
ENT.Type = "anim"
ENT.Base = "rgm_axis_base"

function ENT:SharedInitialize()
	
	self.BaseClass.Initialize(self);

end

---
-- Test player's eye trace against the axis, and returns rgm.Trace
---
function ENT:GetTrace()

	local eyepos, eyeang = rgm.EyePosAng(self:GetGizmo():GetManipulator():GetPlayer());
	local intersect = rgm.IntersectRayWithPlane(self:GetPos(), self:GetAngles():Up(), eyepos, eyeang:Forward());
	local scale = self:GetScale();

	local localized = self:WorldToLocal(intersect);
	if localized.x <= scale and localized.y <= 0.1 * scale then
		return rgm.Trace(true, self:GetManipulator(), self:GetGizmo(), self, intersect, localized);
	end
	
	return rgm.Trace(false);

end