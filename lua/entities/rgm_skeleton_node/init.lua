
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

---
-- Set the target bone ID of the node
---
function ENT:SetBoneID(id)
	self:SetNWInt("BoneID", id);
end

---
-- Lock the target's position to the node's position
---
function ENT:Lock()
	
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
function ENT:Unlock()
	
	-- No action required for now
	
end

---
-- Position the node's target to the node's position.
-- This does nothing if the skeleton is unlocked.
---
function ENT:PositionTarget()
	
	local type = self:GetType();
	local e = self:GetSkeleton():GetEntity();
	local pos, ang = self:GetPosAng();

	if type == RgmNodeType.Bone then

		-- TODO

	elseif type == RgmNodeType.Physbone then

		local b = e:GetPhysicsObjectNum(self:GetBoneID());
		if b == nil then
			return; --Physbone not found, something's wrong
		end
		
		b:SetPos(pos);
		b:SetAngles(ang);

	elseif type == RgmNodeType.Origin then

		e:SetPos(pos);
		e:SetAngles(ang);

	end

end