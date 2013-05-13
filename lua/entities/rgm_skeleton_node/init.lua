
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
include("shared.lua");

function ENT:Initialize()

	self:SharedInitialize();

end

function ENT:Setup(skeleton, id, parent, type, boneId)

	self:SetNWInt("Id", id);
	self:SetSkeleton(skeleton);
	self:SetParent(parent);
	self:SetType(type);
	self:SetBoneID(boneId);

end

function ENT:SetSkeleton(skeleton)
	self:SetNWEntity("Skeleton", skeleton);
end

function ENT:SetParent(parent)
	self:SetNWEntity("Parent", parent);
end

function ENT:SetType(type)
	self:SetNWInt("Type", type);
end