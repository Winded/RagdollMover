
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:SetPlayer(pl)
	self:SetNWEntity("Player", pl);
end

function ENT:SetScale(scale)
	self:SetNWFloat("Scale", 10);
end

function ENT:ProcessMovement(offpos, offang, eyepos, 
						eyeang, ent, bone, ppos, pnorm)
						
	local obj = ent:GetPhysicsObjectNum(bone)
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos)
	local localized = self:WorldToLocal(intersect)
	localized = Vector(localized.x,0,0)
	intersect = self:LocalToWorld(localized)
	local ang = obj:GetAngles()
	
	local pos,_a = LocalToWorld(Vector(offpos.x,0,0),Angle(0,0,0),intersect,self:GetAngles())
	return pos,ang
	
end

---
-- Updates the skeleton position
---
function ENT:Update()

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
	pos.y = 0;
	pos.z = 0;

	target:SetPos(pos);

end