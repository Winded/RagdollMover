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

local NodeType =
{
	-- A model bone
	Bone = 1,
	-- A physbone of a ragdoll
	Physbone = 2,
	-- Simple GetPos() and GetAngles() of the entity
	Origin = 3
};

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

