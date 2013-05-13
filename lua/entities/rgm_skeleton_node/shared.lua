
ENT.Type = "anim";
ENT.Base = "rgm_base_entity";

_G["RgmNodeType"] =
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

end

function ENT:GetSkeleton()
	return self:GetNWEntity("Skeleton", NULL);
end

function ENT:GetParent()
	return self:GetNWEntity("Parent", NULL);
end

function ENT:GetType()
	return self:GetNWInt("Type", RgmNodeType.Bone);
end