
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
include("shared.lua");

function ENT:Initialize()

	self.BaseClass.Initialize(self);

end

---
-- ...
---
function ENT:Update()

	-- Abstract

end