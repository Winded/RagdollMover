
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
include("shared.lua");

function ENT:Initialize()

	self.BaseClass.Initialize(self);

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
-- Wrapper for setting position and angle
---
function ENT:SetPosAng(pos, ang)
	self:SetPos(pos);
	self:SetAngles(ang);
end

---
-- Called by rgm_manipulator when this node is grabbed
---
function ENT:OnGrab()
	self:SetNWBool("Grabbed", true);
end

---
-- Called by rgm_manipulator when this node is released
---
function ENT:OnRelease()
	self:SetNWBool("Grabbed", false);
end

---
-- Lock the target's position to the node's position
---
function ENT:Lock()
	
	-- Get the local position of this node relative to it's parent, and we have a solid lock position
	
	local ppos, pang = self:GetParent():GetPosAng();
	local pos, ang = self:GetPosAng();
	
	local lpos, lang = WorldToLocal(pos, ang, ppos, pang);
	self:SetNWVector("LockPos", lpos);
	self:SetNWAngle("LockAng", lang);
	
end

---
-- Unlock the target's position; node will follow target.
---
function ENT:Unlock()
	
	-- No action required for now
	
end

---
-- Update the node's target position to the node's position.
-- This does nothing if the skeleton is unlocked.
---
function ENT:Update()
	
	if not self:IsLocked() then return; end

	local type = self:GetType();
	local e = self:GetSkeleton():GetEntity();
	local pos, ang = self:GetPosAng();

	if type == RgmNodeType.Bone then

		-- TODO

	elseif type == RgmNodeType.Physbone then

		local b = e:GetPhysicsObjectNum(self:GetBoneID());
		if b == nil then return; end --Physbone not found, something's wrong
		
		b:SetPos(pos);
		b:SetAngles(ang);

	elseif type == RgmNodeType.Origin then

		e:SetPos(pos);
		e:SetAngles(ang);

	end

end