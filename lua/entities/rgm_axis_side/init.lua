
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

	local offset = self:GetGrabOffset();

	local pl = self:GetPlayer();
	local eyepos, eyeang = rgm.EyePosAng(pl);

	local target = self:GetTarget();

	local planepos = self:GetPos();
	local planenorm = self:GetAngles():Forward();
	local linepos, lineang = eyepos, eyeang:Forward();

	local intersect = rgm.IntersectRayWithPlane(planepos, planenorm, linepos, lineang);

	local localized = self:WorldToLocal(intersect);
	localized.x = localized.x - offset.x;
	localized.y = localized.y - offset.y;

	local pos = self:LocalToWorld(localized);

	target:SetPos(pos);

end