
---
-- Skeletons contain all bones and constraints for a certain entity.
---

local SK = {};
SK.__index = SK;

-- Shortcut for getting an entity's skeleton
function SK.Get(entity)
	return table.First(RGM.Skeletons, function(item) return item.Entity == entity; end);
end

-- Create a skeleton for the given entity and broadcast the creation to all clients
function SK.New(entity)

	local sk = setmetatable({}, SK);
	sk.ID = math.random(1, 999999999);
	sk.Entity = entity;
	sk:Init();

	table.insert(RGM.Skeletons, sk);

	if SERVER then
		net.Start("RGMNewSkeleton");
		net.WriteTable(sk);
		net.Broadcast();
	end

	return sk;

end

function SK.NewClient()

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

	table.insert(RGM.Skeletons, sk);

end

-- Remove a skeleton and broadcast the removal to all clients
function SK.Remove(skeleton)

	table.RemoveByValue(RGM.Skeletons, skeleton);

	if SERVER then
		net.Start("RGMRemoveSkeleton");
		net.WriteInt(skeleton.ID, 32);
		net.Broadcast();
	end

end

function SK.RemoveClient()

	local id = net.ReadInt(32);
	local skeleton = table.First(RGM.Skeletons, function(item) return item.ID == id; end);

	if skeleton then
		table.RemoveByValue(RGM.Skeletons, skeleton);
	end

end

if SERVER then
	util.AddNetworkString("RGMNewSkeleton");
	util.AddNetworkString("RGMRemoveSkeleton");
else
	net.Receive("RGMNewSkeleton", SK.NewClient);
	net.Receive("RGMRemoveSkeleton", SK.RemoveClient);
end

-- Initialize skeleton; setup bone hierarchy and constraint table
function SK:Init()

	self.Bones = {};
	self.Constraints = {};

	if self.Entity:GetClass() ~= "prop_ragdoll" then
		local bone = BONE.New(self, RGM.BoneTypes.Root, 0);
		table.insert(self.Bones, bone);
		return;
	end

	for b = 0, self.Entity:GetPhysicsObjectCount() - 1 do
		local bone = BONE.New(self, RGM.BoneTypes.Physbone, b);
		table.insert(self.Bones, bone);
	end

	-- TODO: Non-phys bones

	for _, bone in pairs(self.Bones) do
		bone:SetupParent();
	end

	-- Finally, sort it so we can hierarchially loop through the bones with a simple for loop

	local bones = {};

	local addBone = function(bone)
		table.insert(bones, bone);
		local children = bone:GetChildren();
		for _, child in pairs(children) do
			addBone(child);
		end
	end;

	local firstBone = table.First(self.Bones, function(item) return not item.Parent; end);
	addBone(firstBone);

	self.Bones = bones;

end

function SK:Draw()

	if RGM.SelectedSkeleton ~= self then
		return;
	end

	for _, bone in pairs(self.Bones) do
		bone:Draw();
	end

end

RGM.Skeleton = SK;
RGM.Skeletons = {};