
---
-- Skeletons holds all the bones and constraints of a ragdoll together.
-- It is also called by axis update to refresh bone positions.
---

local SK = {};
SK.__index = SK;

-- Return whether we can make a skeleton for the given entity
function SK.CanCreate(entity)
	-- TODO: Is prop_dynamic?
	return IsValid(entity) and (entity:IsRagdoll() or IsValid(entity:GetPhysicsObject()));
end

-- Create a skeleton for the given entity and broadcast the creation to all clients
function SK.Create(entity)

	local sk = setmetatable({}, SK);
	sk.ID = math.random(1, 999999999);
	sk.Entity = entity;
	sk:Init();

	entity.RGMSkeleton = sk;

	if SERVER then
		net.Start("RGMCreateSkeleton");
		net.WriteTable(sk);
		net.Broadcast();
	end

	return sk;

end

function SK.CreateClient()

	local sk = setmetatable(net.ReadTable(), SK);

	for _, bone in pairs(sk.Bones) do
		setmetatable(bone, RGM.Bone);
	end

	-- Setup relations
	for _, bone in pairs(sk.Bones) do
		if bone.Parent then
			bone.Parent = table.First(sk.Bones, function(item) return item.ID == bone.Parent.ID; end);
		end
	end

	sk.Entity.RGMSkeleton = sk;

end

-- Remove a skeleton and broadcast the removal to all clients
function SK.Remove(skeleton)

	if IsValid(skeleton.Entity) then
		skeleton.Entity.RGMSkeleton = nil;
	end

	if SERVER then
		net.Start("RGMRemoveSkeleton");
		net.WriteEntity(skeleton.Entity);
		net.Broadcast();
	end

end

function SK.RemoveClient()

	local entity = net.ReadEntity();

	if IsValid(entity) and entity.RGMSkeleton then
		entity.RGMSkeleton = nil;
	end

end

-- Initialize skeleton; setup bone hierarchy and constraint table
function SK:Init()

	self.Bones = {};
	self.Constraints = {};
	self.ConstrainedBones = {};

	if not self.Entity:IsRagdoll() then
		local bone = RGM.Bone.Create(self.Entity, RGM.BoneTypes.Root, 0);
		table.insert(self.Bones, bone);
		return;
	end

	for b = 0, self.Entity:GetPhysicsObjectCount() - 1 do
		local bone = RGM.Bone.Create(self.Entity, RGM.BoneTypes.Physbone, b);
		table.insert(self.Bones, bone);
	end

	-- TODO: Non-phys bones

	for _, bone in pairs(self.Bones) do
		bone:SetupParent(self.Bones);
	end

	-- Finally, sort it so we can hierarchially loop through the bones with a simple for loop

	local bones = {};

	addBone = function(bone)
		table.insert(bones, bone);
		local children = table.Where(self.Bones, function(item) return item.Parent == bone; end);
		for _, child in pairs(children) do
			addBone(child);
		end
	end;

	local firstBone = table.First(self.Bones, function(item) return not item.Parent; end);
	addBone(firstBone);
	addBone = nil;

	self.Bones = bones;

end

-- Has the given player selected this skeleton?
function SK:IsSelected(player)
	return IsValid(player.RGMSelectedEntity) and player.RGMSelectedEntity.RGMSkeleton == self;
end

function SK:AddConstraint(constraint)
	table.insert(self.Constraints, constraint);
	for _, bone in pairs(constraint.Bones) do
		table.insert(self.ConstrainedBones, bone);
	end
end

function SK:RemoveConstraint(constraint)
	table.RemoveByValue(self.Constraints, constraint);
	for _, bone in pairs(constraint.Bones) do
		table.RemoveByValue(self.ConstrainedBones, bone);
	end
end

-- Used to keep bones up to date when not grabbed
function SK:Refresh()
	for _, bone in pairs(self.Bones) do
		bone:Refresh();
	end
	net.Start("RGMRefreshSkeleton");
	net.WriteEntity(self.Entity);
	net.Broadcast();
end

function SK.RefreshClient()
	local entity = net.ReadEntity();
	if not entity.RGMSkeleton then
		return;
	end
	for _, bone in pairs(entity.RGMSkeleton.Bones) do
		bone:Refresh();
	end
end

function SK:OnGrab(selectedBone)

	for _, bone in pairs(self.Bones) do
		bone:RememberOffset();
	end

	for _, constraint in pairs(self.Constraints) do
		constraint:OnGrab(selectedBone);
	end

end

-- Refresh bone offsets, let constraints do their thing, and commit the new positions to the entity.
function SK:OnMoveUpdate(selectedBone)

	for _, bone in pairs(self.Bones) do
		if bone ~= selectedBone and not table.HasValue(self.ConstrainedBones, bone) then
			bone:RestoreOffset();
		end
	end

	for _, constraint in pairs(self.Constraints) do
		constraint:OnMoveUpdate(selectedBone);
	end

	for _, bone in pairs(self.Bones) do
		bone:CommitChanges();
	end

end

function SK:OnRelease(selectedBone)
	self:Refresh();
end

-- Inspect the given trace, and return a bone that was hit, or nil if we didn't hit one
function SK:Trace(trace)

	if not IsValid(trace.Entity) or trace.Entity ~= self.Entity then
		return nil;
	end

	local physBone = trace.PhysicsBone;
	local bone = table.First(self.Bones, function(item) return item.Type == RGM.BoneTypes.Physbone and item.Index == physBone; end);
	if bone then
		return bone;
	end

	return nil;

end

function SK:Draw()

	if not IsValid(RGM.AimedEntity) or RGM.AimedEntity ~= self.Entity then
		return;
	end

	cam.Start3D(EyePos(), EyeAngles());

	for _, bone in pairs(self.Bones) do
		bone:Draw();
	end

	cam.End3D();

end

if SERVER then
	util.AddNetworkString("RGMCreateSkeleton");
	util.AddNetworkString("RGMRemoveSkeleton");
	util.AddNetworkString("RGMRefreshSkeleton");
else
	net.Receive("RGMCreateSkeleton", SK.CreateClient);
	net.Receive("RGMRemoveSkeleton", SK.RemoveClient);
	net.Receive("RGMRefreshSkeleton", SK.RefreshClient);

end

RGM.Skeleton = SK;