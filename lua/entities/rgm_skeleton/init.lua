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

	self:SendMessage("NodeUpdate", self.m_Nodes);

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