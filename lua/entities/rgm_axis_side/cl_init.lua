
include("shared.lua")

function ENT:DrawLines(yellow)
	local ToScreen = {}
	local linetable = self.m_Lines or {};
	
	local scale = self:GetScale();
	
	local color1, color2;
	if yellow then
		color1 = YELLOW;
		color2 = YELLOW;
	else
		color1 = self:GetColor1();
		color2 = self:GetColor2();
	end
	
	for i,v in ipairs(linetable) do
		local pos1 = self:LocalToWorld(v[1] * scale);
		local pos2 = self:LocalToWorld(v[2] * scale);
		table.insert(ToScreen, {pos1:ToScreen(), pos2:ToScreen()});
	end
	
	for i,v in ipairs(ToScreen) do
		if i ~= 2 then
			surface.SetDrawColor(color1.r, color1.g, color1.b, color1.a);
		else
			surface.SetDrawColor(color2.r, color2.g, color2.b, color2.a);
		end
		
		surface.DrawLine(v[1].x,v[1].y,v[2].x,v[2].y);
	end
end