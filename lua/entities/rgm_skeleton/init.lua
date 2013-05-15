AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
include("shared.lua");

function ENT:Initialize()

	self:InitializeShared();

end

function ENT:SetEntity(ent)
	self:SetNWEntity("Entity", ent);
end

function ENT:BuildNodes()

	local ent = self:GetEntity();
	
	if ent:GetClassName() == "prop_ragdoll" then
		
		--Physical bones
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local p = rgm.GetPhysBoneParent(ent, i);
			
			local b = ent:TranslatePhysBoneToBone(i);
			local pb = ent:TranslatePhysBoneToBone(p);
			
			if p then
				self:CreateNode(b, pb, NodeType.Physbone, i);
			else
				self:CreateNode(b, -1, NodeType.Physbone, i);
			end
		end
		
		--TODO non-physical bones? fingers? toes?
		
	else
		--Create only root node when not a ragdoll.
		self:CreateNode(0, -1, NodeType.Origin, 0);
	end

	self:SendMessage("Sync", self.m_Nodes, {});

end

---
-- Create a new node for this skeleton. The node ID must be unique.
---
function ENT:CreateNode(id, parentId, type, boneId)

	if self.m_Nodes[id] ~= nil then
		error("Bone with id " .. id .. " already exists on skeleton of " .. self:GetEntity());
	end
	if parentId > -1 and self.m_Nodes[parentId] == nil then
		error("Bone parent id " .. id .. " was not found on entity " .. self:GetEntity());
	end
	
	local parent = self.m_Nodes[parentId];
	
	local node = ents.Create("rgm_skeleton_node");
	node:Spawn();
	node:Setup(self, id, parent, type, boneId);
	self.m_Nodes[id] = node;
	
	return node;
	
end

---
-- Create and attach a constraint to this skeleton,
-- affecting the given nodes of this skeleton.
---
function ENT:CreateConstraint(nodes)

	for _, node in pairs(nodes) do
		if not table.HasValue(self.m_Nodes, node) then
			error("CreateConstraint: Skeleton of entity " .. self:GetEntity()
				.. " does not contain given node");
		end
	end

	local c = ents.Create("rgm_constraint");
	c:Spawn();
	c:Setup(nodes);

	table.insert(self.m_Constraints, c);

	self:SendMessage("Sync", self.m_Nodes, self.m_Constraints);

end

---
-- Lock the positions of the actual entity into the skeleton's positions.
---
function ENT:Lock()
	
	for _, node in pairs(self.m_Nodes) do
		node:Lock();
	end
	
	self:SetNWBool("Locked", true);
	
end

---
-- Unlock the positions of the actual entity; makes the skeleton follow the entity.
---
function ENT:Unlock()
	
	for _, node in pairs(self.m_Nodes) do
		node:Unlock();
	end
	
	self:SetNWBool("Locked", false);
	
end

---
-- Restore node positions from previously stored data
---
function ENT:Restore()

	if not self.m_RestoreData then return false; end

	for i, node in pairs(self.m_Nodes) do

		local data = self.m_RestoreData[i];

		node:SetPosAng(data.pos, data.ang);

	end

	return true;

end

---
-- Store node positions and angles for later restoration
---
function ENT:SetRestorePoint()
	
	self.m_RestoreData = {};

	for i, node in pairs(self.m_Nodes) do

		local pos, ang = node:GetPosAng();

		self.m_RestoreData[i] = { pos = pos, ang = ang };

	end

end

---
-- Position the target entity to the skeleton's nodes.
-- This does nothing if the skeleton is unlocked.
---
function ENT:PositionTarget()
	
	for _, node in pairs(self.m_Nodes) do
		node:PositionTarget();
	end

	if not self:IsLocked() then return; end

	for _, c in pairs(self.m_Constraints) do
		c:PositionTarget();
	end

end