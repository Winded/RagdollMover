
local C = {};
C.__index = C;

function C.Create(skeleton, targetNodes)
	
	local c = setmetatable({}, C);
	
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
	
	--Abstract, inherited constraints should override.
	
end

_G["RgmConstraint"] = C;