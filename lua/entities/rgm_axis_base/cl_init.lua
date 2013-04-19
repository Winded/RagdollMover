
include("shared.lua");

local YELLOW = Color(255, 255, 0, 255);

function ENT:Render()
	
	local gdata = self:GetManipulator():GetGrabData();
	if gdata and gdata.axis ~= self then return; end --Don't render if an axis is grabbed that isn't this
	
	local grabbed = gdata and gdata.axis == self;
	
	local scale = self:GetScale();
	local color = self:GetColor();
	
	if grabbed then color = YELLOW; end
	
	local ToScreen = {};
	
	for i, line in ipairs(self.m_Lines) do
		local pos1 = self:LocalToWorld(line.a * scale);
		local pos2 = self:LocalToWorld(line.b * scale);
		table.insert(ToScreen, {pos1:ToScreen(), pos2:ToScreen()});
	end
	
	for i,v in ipairs(ToScreen) do
		surface.SetDrawColor(color.r, color.g, color.b, color.a);
		surface.DrawLine(v[1].x,v[1].y,v[2].x,v[2].y);
	end
	
end

function ENT:Draw()

	local isYellow = self:IsYellow();
	if not isYellow then return; end

	local linetable = self.m_Lines;
	
	local scale = self:GetScale();
	
	local color;
	if isYellow then
		color = YELLOW;
	else
		color = self:GetColor();
	end
	
	local ToScreen = {};
	
	for i,v in ipairs(linetable) do
		local pos1 = self:LocalToWorld(v[1] * scale);
		local pos2 = self:LocalToWorld(v[2] * scale);
		table.insert(ToScreen, {pos1:ToScreen(), pos2:ToScreen()});
	end
	
	for i,v in ipairs(ToScreen) do
		surface.SetDrawColor(color.r, color.g, color.b, color.a);
		surface.DrawLine(v[1].x,v[1].y,v[2].x,v[2].y);
	end
	
end

