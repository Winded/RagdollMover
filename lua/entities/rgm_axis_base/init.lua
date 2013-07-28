
include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

function ENT:Initialize()

	self.BaseClass.Initialize(self);

	self:SetNetworkedBool("ShouldDraw", false);
	self:SetNetworkedBool("ShouldDrawYellow", false);

end

---
-- Updates the skeleton node position
---
function ENT:UpdatePosition()

	-- Abstract

end