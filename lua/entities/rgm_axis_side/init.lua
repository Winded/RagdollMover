
include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

function ENT:Initialize()

	self.BaseClass.Initialize(self);

end

function ENT:SetColor1(color)
	self:SetNWVector("Color1", Vector(color.r, color.g, color.b));
end

function ENT:SetColor2(color)
	self:SetNWVector("Color2", Vector(color.r, color.g, color.b));
end

function ENT:SetColors(color1, color2)
	self:SetColor1(color1);
	self:SetColor2(color2);
end

---
-- Updates the skeleton node position
---
function ENT:UpdatePosition()

	local intersect = self:GetIntersect(self:GetAngles():Forward());

	local offset = self:GetGrabOffset();
	local target = self:GetTarget();

	local localized = self:WorldToLocal(intersect);
	localized.x = localized.x - offset.x;
	localized.y = localized.y - offset.y;

	local pos = self:LocalToWorld(localized);

	target:SetPos(pos);

end