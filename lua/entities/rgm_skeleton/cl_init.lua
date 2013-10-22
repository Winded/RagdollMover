include("shared.lua");

function ENT:Initialize()

	self.BaseClass.Initialize(self);

end

---
-- Called from the server to update clientside nodes and constraints.
-- The nodes table should be an array of new/updated nodes, with tables of their data.
-- The table contains only a 'deleted' boolean if the node was deleted.
---
function ENT.Sync(len)

	local self = net.ReadEntity();

	local nodes = net.ReadTable();

	self.m_Nodes = nodes;

end
net.Receive("rgm_skeleton_sync", ENT.Sync);

---
-- Render the skeleton
---
function ENT:Render()

	-- TODO

end