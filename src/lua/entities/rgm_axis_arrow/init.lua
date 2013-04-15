
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