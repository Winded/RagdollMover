
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:SetPlayer(pl)
	self:SetNWEntity("Player", pl);
end

function ENT:SetScale(scale)
	self:SetNWFloat("Scale", 10);
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
	local planenorm = self:GetAngles():Up();
	local linepos, lineang = eyepos, eyeang:Forward();

	local intersect = rgm.IntersectRayWithPlane(planepos, planenorm, linepos, lineang);

	local pos = self:WorldToLocal(intersect);
	pos.x = pos.x - offset.x;

	pos = self:LocalToWorld(pos);

	target:SetPos(pos);

end