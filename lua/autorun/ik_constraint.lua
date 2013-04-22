
local IK = {};
setmetatable(IK, RgmConstraint);
IK.__index = IK;
IK.base = RgmConstraint;

function IK:Initialize()
	
	self.base.Initialize(self);
	
	self.m_Hip = self.m_Nodes[1];
	self.m_Foot = self.m_Nodes[2];
	
	--Get all bones between hip and foot
	self.m_Knees = {};
	local curnode = self.m_Foot;
	while true do
		curnode = curnode:GetParent();
		if curnode == self.m_Hip then
			break;
		end
		
		table.insert(self.m_Knees, curnode);
	end
	
end

function IK:GetHip()
	return self.m_Hip;
end

function IK:GetFoot()
	return self.m_Foot;
end

---
-- Position the nodes, and thus the target entity, with the constraint logic.
---
function IK:PositionTarget()

	-- TODO

end

_G["RgmIKConstraint"] = IK;