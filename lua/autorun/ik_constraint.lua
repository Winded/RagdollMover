
local IK = {};
setmetatable(IK, RgmConstraint);
IK.__index = IK;
IK.base = RgmConstraint;

function IK.Create(skeleton, targetNodes)
	return RgmConstraint.Create(RgmIKConstraint, skeleton, targetNodes);
end

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
-- Called from skeleton when the skeleton is locked
---
function IK:Lock()
	
	-- Store knee offsets

	self.m_KneeOffsets = {};

	local lastnode = self:GetFoot();
	for idx, node in ipairs(self.m_Knees) do
		
		local offset = {};
		offset.node = node;

		local pos, ang = node:GetPosAng();
		local lnpos, lnang = lastnode:GetPosAng();

		local dirang = (lnpos - pos):Angle();
		local opos, oang = WorldToLocal(pos, ang, pos, dirang);
		offset.angoffset = oang;

		table.insert(self.m_KneeOffsets, offset);

		lastnode = node;

	end

	-- TODO position offset

end

---
-- Called from skeleton when the skeleton is unlocked
---
function IK:Unlock()
	
	self.m_KneeOffsets = nil;

end

---
-- Position the nodes, and thus the target entity, with the constraint logic.
---
function IK:PositionTarget()

	-- TODO

end

---
--	Key function for IK chains: finding the knee position (in case of arms, it's elbow position)
--	Once again, a math function, which I didn't fully make myself, and cannot explain much.
--	Only that the arguments in order are: hip position, ankle position, thigh length, shin length, knee vector direction.
--	
--	Got the math from this thread:
--	http://forum.unity3d.com/threads/40431-IK-Chain
---
local function FindKnee(pHip, pAnkle, fThigh, fShin, vKneeDir)
	local vB = pAnkle - pHip;
    local LB = vB:Length();
    local aa = (LB * LB + fThigh * fThigh - fShin * fShin) / 2 / LB;
    local bb = math.sqrt(fThigh * fThigh - aa * aa);
    local vF = vB:Cross(vKneeDir:Cross(vB));
	vB:Normalize();
	vF:Normalize();
    return pHip + (aa * vB) + (bb * vF);
end

_G["RgmIKConstraint"] = IK;