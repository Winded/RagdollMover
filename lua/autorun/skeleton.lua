
local SK = {}
SK.__index = SK;
local SKNODE = {};
SKNODE.__index = SKNODE;

---------------
-- SKELETON
---------------

local NodeType =
{
	-- A model bone
	Bone = 1,
	-- A physbone of a ragdoll
	Physbone = 2,
	-- Simple GetPos() and GetAngles() of the entity
	Origin = 3
};

function SK.Create(entity)
	
	local sk = {};
	setmetatable(sk, SK);
	
	sk.m_Entity = entity;
	sk.m_Nodes = {};
	
	if entity:GetClass() == "prop_ragdoll" then
		
		--Physical bones
		for i = 0, entity:GetPhysicsObjectCount() - 1 do
			local p = rgm.GetPhysBoneParent(entity, i);
			
			local b = entity:TranslatePhysBoneToBone(i);
			local pb = entity:TranslatePhysBoneToBone(p);
			
			if p then
				sk:CreateNode(b, pb, NodeType.Physbone, i);
			else
				sk:CreateNode(b, -1, NodeType.Physbone, i);
			end
		end
		
		--TODO non-physical bones? fingers? toes?
		
	else
		--Create only root node when not a ragdoll.
		sk:CreateNode(0, -1, NodeType.Origin, 0);
	end
	
	sk:Initialize();
	
end

function SK:Initialize()
	self.m_Locked = false;
	self.m_Constraints = {};
end

function SK:GetEntity()
	return self.m_Entity;
end

function SK:SetEntity(entity)
	self.m_Entity = entity;
end

---
-- Create a new node for this skeleton. The node ID must be unique.
---
function SK:CreateNode(id, parentId, type, boneId)

	if self.m_Nodes[id] ~= nil then
		error("Bone with id " .. id .. " already exists on skeleton of " .. self:GetEntity());
	end
	if parentId > -1 and self.m_Nodes[parentId] == nil then
		error("Bone parent id " .. id .. " was not found on entity " .. self:GetEntity());
	end
	
	local parent = self.m_Nodes[parentId];
	
	local node = SKNODE.Create(self, id, parent, type, boneId, pos, ang);
	self.m_Nodes[id] = node;
	
	node:Initialize();
	
	return node;
	
end

---
-- Create and attach a constraint to this skeleton,
-- affecting the given nodes of this skeleton.
---
function SK:CreateConstraint(nodes)
	
	for k, v in pairs(nodes) do
		if not table.HasValue(self.m_Nodes, nodes) then
			error("CreateConstraint: Skeleton of entity " .. self:GetEntity()
				.. " does not contain given node");
		end
	end
	
	local c = RgmConstraint.Create(self, nodes);
	return c;
	
end

---
-- True if locked, false if unlocked
---
function SK:IsLocked()
	return self.m_Locked;
end

---
-- Lock the positions of the actual entity into the skeleton's positions.
---
function SK:Lock()
	
	for _, node in pairs(self.m_Nodes) do
		node:Lock();
	end
	
	self.m_Locked = true;
	
end

---
-- Unlock the positions of the actual entity; makes the skeleton follow the entity.
---
function SK:Unlock()
	
	for _, node in pairs(self.m_Nodes) do
		node:Unlock();
	end

	self.m_Locked = false;
	
end

---
-- Position the target entity to the skeleton's nodes.
-- This does nothing if the skeleton is unlocked.
---
function SK:PositionTarget()
	
	for _, node in pairs(self.m_Nodes) do
		node:PositionTarget();
	end

	if not self:IsLocked() then return; end

	for _, c in pairs(self.m_Constraints) do
		c:PositionTarget();
	end

end

_G["RgmSkeleton"] = SK;

---------------
-- SKELETON NODE
---------------

function SKNODE.Create(skeleton, id, parent, type, boneId)
	
	local node = {};
	setmetatable(node, SKNODE);
	
	node.m_Skeleton = skeleton;
	node.m_Id = id;
	node.m_Parent = parent;
	node.m_Type = type;
	node.m_BoneId = boneId;
	
	return node;
	
end

function SKNODE:Initialize()
	self.m_LockPos = Vector();
	self.m_LockAng = Angle();
end

---
-- Get the global position and angles of the node
---
function SKNODE:GetPosAng()
	
	if self:IsLocked() then
		local pos, ang = LocalToWorld(self.m_LockPos, self.m_LockAng, self:GetParent():GetPosAng());
	end

	local type = self:GetType();
	
	local e = self:GetSkeleton():GetEntity();
	
	if type == NodeType.Bone then
		
		local pos, ang = e:GetBonePosition(self.m_BoneId);
		--TODO null check
		
		return pos, ang;
		
	elseif type == NodeType.Physbone then
		
		local b = e:GetPhysicsObjectNum(self.m_BoneId);
		if b == nil then
			return nil; --Physbone not found, something's wrong
		end
		
		local pos, ang = b:GetPos(), b:GetAngles();
		return pos, ang;
		
	elseif type == NodeType.Origin then
		
		local pos, ang = e:GetPos(), e:GetAngles();
		return pos, ang;
		
	else
		return nil; --Invalid node type, something's wrong
	end
	
end

---
-- Get the node's parent node.
---
function SKNODE:GetParent()
	return self.m_Parent;
end

---
-- Get the node's skeleton
---
function SKNODE:GetSkeleton()
	return self.m_Skeleton;
end

function SKNODE:GetType()
	return self.m_Type;
end

function SKNODE:SetType(type)
	if not table.HasValue(NodeType, type) then
		error("Invalid type");
	end
	self.m_Type = type;
end

---
-- True if locked, false if unlocked
---
function SKNODE:IsLocked()
	return self:GetSkeleton():IsLocked();
end

---
-- Lock the target's position to the node's position
---
function SKNODE:Lock()
	
	-- Get the local position of this node relative to it's parent, and we have a solid lock position
	
	local ppos, pang = self:GetParent():GetPosAng();
	local pos, ang = self:GetPosAng();
	
	local lpos, lang = WorldToLocal(pos, ang, ppos, pang);
	self.m_LockPos = lpos;
	self.m_LockAng = lang;
	
end

---
-- Unlock the target's position; node will follow target.
---
function SKNODE:Unlock()
	
	-- No action required for now
	
end

_G["RgmSkeletonNode"] = SKNODE;