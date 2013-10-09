
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

	self.BaseClass.SharedInitialize(self);

end

function ENT:GetID()
	return self:GetNWInt("Id", 0)
end

function ENT:GetSkeleton()
	return self:GetNWEntity("Skeleton", NULL);
end

function ENT:GetEntity()
	return self:GetSkeleton():GetEntity();
end

function ENT:GetParent()
	return self:GetNWEntity("Parent", NULL);
end

function ENT:GetType()
	return self:GetNWInt("Type", RgmNodeType.Bone);
end

---
-- Get the target bone ID of the node.
-- If this returns -1 then either it isn't synced on client or something is wrong.
---
function ENT:GetBoneID()
	self:SetNWInt("BoneID", -1);
end

---
-- True if locked, false if unlocked
---
function ENT:IsLocked()
	return self:GetSkeleton():IsLocked();
end

---
-- Returns true if the node is grabbed
---
function ENT:IsGrabbed()
	return self:GetNWBool("Grabbed", false);
end

---
-- Wrapper for getting position and angle
---
function ENT:GetPosAng()
	return self:GetPos(), self:GetAngles();
end