
local C = {};
C.__index = C;

function C.Create(class, skeleton, targetNodes)
	
	local c = setmetatable({}, class);
	
	c.m_Skeleton = skeleton;
	c.m_Nodes = targetNodes;
	
	c:Initialize();
	
	return c;
	
end

function C:Initialize()
	
end

---
-- Get a table of positions and angles of each target node.
---
function C:GetPosAngs()
	
	local posangs = {};

	for _, node in pairs(self.m_Nodes) do
		local pos, ang = node:GetPosAng();
		table.insert(posangs, {pos = pos, ang = ang});
	end

	return posangs;
	
end

---
-- Called from skeleton when the skeleton is locked
---
function C:Lock()
	
	--Abstract

end

---
-- Called from skeleton when the skeleton is unlocked
---
function C:Unlock()
	
	--Abstract

end

---
-- Position the nodes, and thus the target entity, with the constraint logic.
---
function C:PositionTarget()
	
	--Abstract

end

_G["RgmConstraint"] = C;