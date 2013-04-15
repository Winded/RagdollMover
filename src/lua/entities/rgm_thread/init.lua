
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
include("shared.lua");

function ENT:Initialize()

	self.BaseClass.Initialize(self);

	self.m_Player = NULL;
	
	self.m_DrawAxis = false;
	self.m_Grabbing = false;
	self.m_GrabOffset = Vector();

end

function ENT:Think()
	
end

---
-- Gets if the player's trace collides with any axes.
-- If it does, also returns axis entity reference and point of intersection.
---
function ENT:GetGrabData()



end

function ENT:Grab()

end