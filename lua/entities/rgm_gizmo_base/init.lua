
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
include("shared.lua");

function ENT:Initialize()
	
	self:SharedInitialize();
	
end

---
-- Updates the skeleton position
---
function ENT:Update()
	
	local axis = self:GetGrabAxis();
	if not IsValid(axis) then return; end

	axis:Update();

end