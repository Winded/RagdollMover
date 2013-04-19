
ENT.Type = "anim"
ENT.Base = "rgm_axis_part"

local sideLines = {
	{Vector(0,0.25,0), Vector(0,0.25,0.25)},
	{Vector(0,0,0.25) ,Vector(0,0.25,0.25)},
};

function ENT:Initialize()
	self.BaseClass.Initialize(self);
	
	--TODO
end

function ENT:GetColor1()
	local c = self:GetNWVector("Color1", Vector(0, 0, 0));
	return Color(c.x, c.y, c.z, 255);
end

function ENT:GetColor2()
	local c = self:GetNWVector("Color2", Vector(0, 0, 0));
	return Color(c.x, c.y, c.z, 255);
end

function ENT:TestCollision()
	local eyepos,eyeang = rgm.EyePosAng(self:GetPlayer())
	local intersect = self:GetGrabPos(eyepos,eyeang)
	local localized = self:WorldToLocal(intersect)
	
	local scale = self:GetScale();
	local distmin1 = Vector(-0.15*scale,scale*0.2,0);
	local distmax1 = Vector(0.15*scale,scale*0.3,scale*0.25);
	local distmin2 = Vector(-0.15*scale,0,scale*0.2);
	local distmax2 = Vector(0.15*scale,scale*0.25,scale*0.3);
	
	if (localized.x >= distmin1.x and localized.x <= distmax1.x
	and localized.y >= distmin1.y and localized.y <= distmax1.y
	and localized.z >= distmin1.z and localized.z <= distmax1.z)
	or (localized.x >= distmin2.x and localized.x <= distmax2.x
	and localized.y >= distmin2.y and localized.y <= distmax2.y
	and localized.z >= distmin2.z and localized.z <= distmax2.z) then
		return {axis = self,hitpos = intersect};
	end
	return false
end