
include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

function ENT:Initialize()

	self.BaseClass.Initialize(self);

end

---
-- Updates the skeleton node position
---
function ENT:UpdatePosition()

	local intersect = self:GetIntersect(self:GetAngles():Forward());

	local offset = self:GetGrabOffset();
	local target = self:GetTarget();

	local localized = self:WorldToLocal(intersect);

	local iAng = localized:Angle();
	local gAng = offset:Angle();
	local ang = iAng - gAng;

	target:SetAngles(ang);

end