
include("shared.lua");

local YELLOW = Color(255, 255, 0, 255);

function ENT:Initialize()
	
	self:SharedInitialize();

	self.m_Lines = {};

end

---
-- Get if the axis should be drawn
---
function ENT:ShouldDraw()
	return self:GetNetworkedBool("ShouldDraw", false);
end

---
-- Get if the axis should be drawn in yellow
---
function ENT:ShouldDrawYellow()
	return self:GetNetworkedBool("ShouldDrawYellow", false);
end

function ENT:Render()
	
	local yellow = self:ShouldDrawYellow();
	
	local scale = self:GetScale();
	local color = self:GetColor();
	
	if yellow then color = YELLOW; end
	
	local ToScreen = {};
	
	for i, line in ipairs(self.m_Lines) do
		local pos1 = self:LocalToWorld(line.a * scale);
		local pos2 = self:LocalToWorld(line.b * scale);
		table.insert(ToScreen, {pos1:ToScreen(), pos2:ToScreen()});
	end
	
	for i,v in ipairs(ToScreen) do
		surface.SetDrawColor(color.r, color.g, color.b, color.a);
		surface.DrawLine(v[1].x, v[1].y, v[2].x, v[2].y);
	end
	
end