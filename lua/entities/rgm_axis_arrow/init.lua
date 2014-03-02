
include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

local base = getmetatable(ENT);

function ENT:Initialize()

	base.Initialize(self);

end

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

	local intersect = self:GetIntersect(self:GetAngles():Up());

	local offset = self:GetGrabOffset();
	local target = self:GetTarget();

	local pos = self:WorldToLocal(intersect);
	pos.x = pos.x - offset.x;

	pos = self:LocalToWorld(pos);

	target:SetPos(pos);

end