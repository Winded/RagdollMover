
include("shared.lua");

function ENT:Initialize()
	
	self:SharedInitialize();
	
end

---
-- Draw the gizmo
---
function ENT:Render()
	
	for id, axis in pairs(self:GetAxes()) do
		axis:Render();
	end
	
end