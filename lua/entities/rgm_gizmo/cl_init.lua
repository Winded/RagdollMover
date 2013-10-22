
include("shared.lua");

function ENT:Initialize()
	
	self.BaseClass.Initialize(self);
	
end

---
-- Draw the gizmo
---
function ENT:Render()
	
	for id, axis in pairs(self:GetAxes()) do
		axis:Render();
	end
	
end

---
-- Called from server to sync the axis table
---
function ENT.SyncAxes(len)

	local self = net.ReadEntity();
	
	self.m_Axes = net.ReadTable();

end
net.Receive("rgm_gizmo_sync", ENT.SyncAxes);