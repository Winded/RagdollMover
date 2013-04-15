
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
	
	if entity:GetClassName() == "prop_ragdoll" then
		
		--Physical bones
		for i = 0, entity:GetPhysicsObjectCount() - 1 do
			local p = rgm.GetPhysBoneParent(entity, i);
			local phys = entity:GetPhysicsObjectNum(i);
			
			local pos, ang = phys:GetPos(), phys:GetAngles();
			
			local b = entity:TranslatePhysBoneToBone(i);
			local pb = entity:TranslatePhysBoneToBone(p);
			
			if p then
				local parentphys = entity:GetPhysicsObjectNum(p);
				local ppos, pang = parentphys:GetPos(), parentphys:GetAngles();
				local lpos, lang = WorldToLocal(pos, ang, ppos, pang);
				sk:CreateNode(b, pb, NodeType.Physbone, i, lpos, lang);
			else
				sk:CreateNode(b, -1, NodeType.Physbone, i, pos, ang);
			end
		end
		
		--TODO non-physical bones? fingers? toes?
		
	else
		--Create only root node when not a ragdoll.
		sk:CreateNode(0, -1, NodeType.Origin, 0, entity:GetPos(), entity:GetAngles());
	end
	
end

function SK:Initialize()
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

	if self.m_Nodes[id] ~= nil then
		error("Bone with id " .. id .. " already exists on skeleton of " .. self:GetEntity());
	end
	
	local node = SKNODE.Create(self, id, parentId, type, boneId, pos, ang);
	self.m_Nodes[id] = node;
	
	return node;
	
end

_G["Skeleton"] = SK;

---------------
-- SKELETON NODE
---------------

function SKNODE.Create(skeleton, id, parentId, type, boneId, pos, ang)
	
	local node = {};
	setmetatable(node, SKNODE);
	
	node.m_Id = id;
	node.m_ParentId = parentId;
	node.m_Type = type;
	node.m_BoneId = boneId;
	node.m_Pos = pos;
	node.m_Ang = ang;
	
	return node;
	
end

function SKNODE:Initialize()
	
end

function SKNODE:GetPos()
	
end

_G["SkeletonNode"] = SKNODE;