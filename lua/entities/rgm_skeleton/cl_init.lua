include("shared.lua");

function ENT:Initialize()

	self:InitializeShared();

end

---
-- Called from the server to update clientside nodes.
-- The nodes table should be an array of new/updated nodes, with tables of their data.
-- The table contains only a 'deleted' boolean if the node was deleted.
---
function ENT:NodeUpdate(nodes)

	for i, node in ipairs(nodes) do
		
		if node.deleted then
			table.remove(self.m_Nodes, i);
			continue;
		end

		local n = self.m_Nodes[i];

		if not n then
			n = {};
		end

		for k, v in pairs(node) do
			n[k] = v;
		end

		self.m_Nodes[i] = n;

	end

end

---
-- Render the skeleton
---
function ENT:Render()

	-- TODO

end