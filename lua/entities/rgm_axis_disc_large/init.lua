include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

function ENT:Initialize()

	self.BaseClass.Initialize(self);

end

---
-- Set the scale of the axis. As an outer disk, this is always slightly larger than other disks.
---
function ENT:SetScale(scale)
	self:SetNWFloat("Scale", scale * 1.25);
end