
include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

local base = getmetatable(ENT);

function ENT:Initialize()

	base.Initialize(self);

	self:SetNetworkedBool("ShouldDraw", false);
	self:SetNetworkedBool("ShouldDrawYellow", false);

end

---
-- Set the scale of the axis
---
function ENT:SetScale(scale)
	self:SetNWFloat("Scale", scale);
end

---
-- Called when the axis is grabbed.
---
function ENT:OnGrab()

	-- Abstract

end

---
-- Called when the axis is released.
---
function ENT:OnRelease()

	-- Abstract

end

---
-- Gets called every frame.
---
function ENT:Update()

	-- Abstract

end

---
-- Updates the skeleton node position
---
function ENT:UpdatePosition()

	-- Abstract

end