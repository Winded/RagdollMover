include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

---
-- Set the scale of the axis. As an outer disk, this is always slightly larger than other disks.
---
function ENT:SetScale(scale)
	self.BaseClass.SetScale(self, scale * 1.25);
end