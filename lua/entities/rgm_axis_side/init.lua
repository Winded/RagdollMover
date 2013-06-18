
include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

function ENT:Initialize()

	self:SharedInitialize();

end

function ENT:SetColor1(color)
	self:SetNWVector("Color1", Vector(color.r, color.g, color.b));
end

function ENT:SetColor2(color)
	self:SetNWVector("Color2", Vector(color.r, color.g, color.b));
end

function ENT:ProcessMovement(offpos,offang,eyepos,eyeang,ent,bone,ppos,pnorm)
	local obj = ent:GetPhysicsObjectNum(bone)
	local intersect = self:GetGrabPos(eyepos,eyeang,ppos,pnorm)
	local ang = obj:GetAngles()
	local pos,_a = LocalToWorld(offpos,Angle(0,0,0),intersect,self:GetAngles())
	return pos,ang
end