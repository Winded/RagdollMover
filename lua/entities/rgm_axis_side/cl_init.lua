
include("shared.lua");

local sideLines = {
	{ a = Vector(0,0.25,0), b = Vector(0,0.25,0.25) },
	{ a = Vector(0,0,0.25), b = Vector(0,0.25,0.25) },
};

function ENT:Initialize()

	self.BaseClass.Initialize(self);

	self.m_Lines = sideLines;

end

function ENT:Render()
	
	local yellow = self:ShouldDrawYellow();
	
	local scale = self:GetScale();
	
	local color1 = self:GetColor1();
	local color2 = self:GetColor2();
	if yellow then
		color1 = YELLOW;
		color2 = YELLOW;
	end

	local ToScreen = {};

	local line1, line2 = self.m_Lines[1], self.m_Lines[2];

	local pos1, pos2 = self:LocalToWorld(line1.a * scale), self:LocalToWorld(line1.b * scale);
	pos1, pos2 = pos1:ToScreen(), pos2:ToScreen();
	surface.SetDrawColor(color1.r, color1.g, color1.b, color1.a);
	surface.DrawLine(pos1.x, pos1.y, pos2.x, pos2.y);

	pos1, pos2 = self:LocalToWorld(line2.a * scale), self:LocalToWorld(line2.b * scale);
	pos1, pos2 = pos1:ToScreen(), pos2:ToScreen();
	surface.SetDrawColor(color2.r, color2.g, color2.b, color2.a);
	surface.DrawLine(pos1.x, pos1.y, pos2.x, pos2.y);

end