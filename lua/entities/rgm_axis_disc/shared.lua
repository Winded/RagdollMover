
ENT.Type = "anim"
ENT.Base = "rgm_axis_part"

local function MakeLines()
	local RTable = {}
	local ang = Angle(0,0,11.25)
	local startpos = Vector(0, 0, 1)
	for i=1,32 do
		local pos1 = startpos*1
		local pos2 = startpos*1
		pos1:Rotate(ang*(i-1))
		pos2:Rotate(ang*(i))
		RTable[i] = {pos1, pos2}
	end
	return RTable
end
local discLines = MakeLines();

function ENT:Initialize()
	self.BaseClass.Initialize(self);
	
	self:SetLines(discLines);
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
		local lpos, lang = WorldToLocal(intersect, self:GetAngles(), self:GetPos(), self:GetAngles());
		return rgm.Trace(true, self:GetManipulator(), self:GetGizmo(), self, intersect, lpos);
	end
	
	return rgm.Trace(false);
	
end