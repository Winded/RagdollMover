--[[---------------

RGM Skeleton
An entity that manipulates the actual entity to be manipulated.
This entity works as a simplified interface to work with;
when a skeleton's nodes are moved, the nodes move the actual bones
of the entity, and does so without the manipulator having to know
what kind of bone it is manipulating; bone, physbone, or origin.

-----------------]]

ENT.Type = "anim";
ENT.Base = "rgm_base_entity";

function ENT:SharedInitialize()

	self.BaseClass.Initialize(self);

	self.m_AllowedFuncs = {"NodeUpdate"};

	self.m_Nodes = {};

end

function ENT:GetEntity()
	return self:GetNWEntity("Entity", NULL);
end

function ENT:GetNodes()
	return self.m_Nodes;
end

function ENT:GetConstraints()
	return self.m_Constraints;
end

function ENT:GetNodeFor(type, bone)

	local ent = self:GetEntity();

	for i, node in ipairs(self.m_Nodes) do

		if node:GetType() == type and node:GetBone() == bone then
			return node;
		end

	end

	return NULL;

end

function ENT:GetNodeForBone(bone)

	return self:GetNodeFor(RgmNodeType.Bone, bone);

end

function ENT:GetNodeForPhysBone(bone)

	return self:GetNodeFor(RgmNodeType.Physbone, bone);

end

function ENT:GetRootNode()

	return self.m_Nodes[1];

end