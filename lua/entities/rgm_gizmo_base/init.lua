
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
	
	-- Abstract

end