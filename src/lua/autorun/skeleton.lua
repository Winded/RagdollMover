
local SK = {}
SK.__index = SK;
local SKNODE = {};
SKNODE.__index = SKNODE;

---------------
-- SKELETON
---------------

-- A model bone
local NODE_TYPE_BONE = 1;
-- A physbone of a ragdoll
local NODE_TYPE_PHYSBONE = 2;
-- Simple GetPos() and GetAngles() of the entity
local NODE_TYPE_ORIGIN = 3;

function SK.Create(entity)
	
	local sk = {};
	setmetatable(sk, SK);
	sk:Initialize(entity);
	
	if entity:GetClassName() == "prop_ragdoll" then
		
		--TODO
		
	else
		sk:CreateNode(0, NODE_TYPE_ORIGIN, 0, entity:GetPos(), entity:GetAngles());
	end
	
end

function SK:Initialize(entity)
	self.m_Entity = entity;
	self.m_Nodes = {};
end

function SK:GetEntity()
	return self.m_Entity;
end

function SK:SetEntity(entity)
	self.m_Entity = entity;
end

function SK:CreateNode(id, parentId, type, boneId, pos, ang)
	local node = SKNODE.Create(self, id, type, boneId, pos, ang);
	table.insert(self.m_Nodes, node);
end

_G["Skeleton"] = SK;

---------------
-- SKELETON NODE
---------------

function SKNODE.Create(skeleton, id, type, boneId, pos, ang)
	
	local node = {};
	setmetatable(node, SKNODE);
	node:Initialize(skeleton, id, type, boneId, pos, ang);
	
	return node;
	
end

function SKNODE:Initialize(skeleton, id, type, boneId, pos, ang)
	
end

function SKNODE:GetPos()
	
end

_G["SkeletonNode"] = SKNODE;