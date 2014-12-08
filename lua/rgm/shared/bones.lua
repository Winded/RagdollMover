--[[
	Bones are arbitrary objects tied to real entities. They can either be tied to physical bones, manipulatable bones or the entity's root position.
	We use these to make position manipulation more structured and reliable.
	On client, bones are also used to render and trace for selection.
]]

if SERVER then
	util.AddNetworkString("RGMBonesBuilt");
end

RGM.Types = {
	Root = 1,
	Physbone = 2,
	Bone = 3	
};

local BONE = {};
BONE.__index = BONE;

-- Construct bone hierarchy for the given entity
function BONE.BuildBones(entity)

	local builtBones = {};

	if entity:GetClass() ~= "prop_ragdoll" then
		local bone = BONE.New(entity, RGM.Types.Root, 0);
		table.insert(builtBones, bone);
		table.insert(RGM.Bones, bone);
		return builtBones;
	end

	for b = 0, entity:GetPhysicsObjectCount() - 1 do
		local bone = BONE.New(entity, RGM.Types.Physbone, b);
		table.insert(builtBones, bone);
		table.insert(RGM.Bones, bone);
	end

	-- TODO: Non-phys bones

	for _, bone in pairs(builtBones) do
		bone:SetupParent();
	end

	if SERVER then
		net.Start("RGMBuildBones");
		net.WriteEntity(entity);
		net.WriteTable(builtBones);
		net.Send(player.GetAll());
	end

	return builtBones;

end

function BONE.BuildBonesClient()

	if SERVER then
		return;
	end

	local entity = net.ReadEntity();
	local bones =	net.ReadTable();

	local existingBones = table.Where(RGM.Bones, function(item) return item.Entity == entity; end);
	for _, bone in pairs(existingBones) do
		table.RemoveByValue(RGM.Bones, bone);
	end

	for _, b in pairs(bones) do
		local bone = setmetatable(b, BONE);
		table.insert(RGM.Bones, bone);
	end

	-- Setup relations
	for _, bone in pairs(bones) do
		if bone.Parent then
			bone.Parent = table.First(RGM.Bones, function(item) return item.ID == bone.Parent.ID; end);
		end
	end

end

-- Remove bones of an entity (used when entity is removed)
function BONE.RemoveBones(entity)

	local bones = table.Where(RGM.Bones, function(item) return item.Entity == entity; end);
	if #bones == 0 then
		return;
	end

	for _, bone in pairs(bones) do
		table.RemoveByValue(RGM.Bones, bone);
	end

	net.Start("RGMRemoveBones");
	net.WriteEntity(entity);
	net.Send(player.GetAll());

end

function BONE.RemoveBonesClient()
	local entity = net.ReadEntity();
	local bones = table.Where(RGM.Bones, function(item) return item.Entity == entity; end);
	for _, bone in pairs(bones) do
		table.RemoveByValue(RGM.Bones, bone);
	end
end

if CLIENT then
	net.Receive("RGMBuildBones", RGM.BuildBonesClient);
	net.Receive("RGMRemoveBones", RGM.RemoveBonesClient);
end

function BONE.New(entity, type, boneIndex)
	local bone = setmetatable({}, BONE);
	bone.ID = math.random(1, 999999);
	bone.Entity = entity;
	bone.Type = type;
	bone.Index = boneIndex;
	bone.Parent = nil;
	return bone;
end

-- Find the parent of this bone
function BONE:SetupParent()

	if self.Type == RGM.Types.Root then
		return;
	end

	if self.Type == RGM.Types.Physbone then

		local physParent = GetPhysBoneParent(self.Entity, self.Index);
		local phys = table.First(RGM.Bones, function(item)
			return item.Entity == self.Entity and item.Type == RGM.Types.Physbone and item.Index == physParent;
		end);
		if physParent >= 0 and phys then
			self.Parent = phys;
		end

	elseif self.Type == RGM.Types.Bone then

		-- TODO

	end

end

function BONE:GetPos()
	if self.Type == RGM.Types.Root then
		return self.Entity:GetPos();
	elseif self.Type == RGM.Types.Physbone then
		return self.Entity:GetPhysicsObjectNum(self.Index):GetPos();
	elseif self.Type == RGM.Types.Bone then
		local pos, ang = self.Entity:GetBonePosition(self.Index);
		return pos;
	end
end

function BONE:GetAngles()
	if self.Type == RGM.Types.Root then
		return self.Entity:GetAngles();
	elseif self.Type == RGM.Types.Physbone then
		return self.Entity:GetPhysicsObjectNum(self.Index):GetAngles();
	elseif self.Type == RGM.Types.Bone then
		local pos, ang = self.Entity:GetBonePosition(self.Index);
		return ang;
	end
end

function BONE:GetLocalPosAng()

	if not self.Parent then
		return Vector(0, 0, 0), Angle(0, 0, 0);
	end

	local pPos = self.Parent:GetPos();
	local pAng = self.Parent:GetAngles();
	local gPos = self:GetPos();
	local gAng = self:GetAngles();

	local pos, ang = WorldToLocal(gPos, gAng, pPos, pAng);
	return pos, ang;

end

function BONE:GetLocalPos()
	local pos, ang = self:GetLocalPosAng();
	return pos;
end

function BONE:GetLocalAngles()
	local pos, ang = self:GetLocalPosAng();
	return ang;
end

function BONE:GetChildren()
	if not self.Children then
		self.Children = table.Where(RGM.Bones, function(item) return item.Parent == self; end);
	end
	return self.Children;
end

function BONE:SetPosAng(position, angles)

	local myPos, myAng = self:GetPosAng();

	-- Store child relative positions
	local children = self:GetChildren();
	local childPositions = {};
	for _, child in pairs(children) do
		local pos, ang = WorldToLocal(child:GetPos(), child:GetAngles(), myPos, myAng);
		table.insert(childPositions, {Bone = child, Pos = pos, Angles = ang});
	end

	if self.Type == RGM.Types.Root then
		self.Entity:SetPos(position);
		self.Entity:SetAngles(angles);
	elseif self.Type == RGM.Types.Physbone then
		local physObj = self.Entity:GetPhysicsObjectNum(self.Index);
		physObj:SetPos(position);
		physObj:SetAngles(angles);
	elseif self.Type == RGM.Types.Bone then
		local pPos, pAng = self.Parent:GetPosAng();
		local pos, ang = WorldToLocal(position, myAng, pPos, pAng);
		self.Entity:ManipulateBonePosition(self.Index, pos);
	end

	myPos, myAng = self:GetPosAng();

	-- Restore child relative positions
	for _, cp in pairs(childPositions) do
		local pos, ang = LocalToWorld(cp.Pos, cp.Angles, myPos, myAng);
		cp.Bone:SetPosAng(pos, ang);
	end

end

function BONE:SetPos(position)
	self:SetPosAng(position, self:GetAngles());
end

function BONE:SetAngles(angles)
	self:SetPosAng(self:GetPos(), angles);
end

-- Draw stuff (on client)
function BONE:Draw()

	if not self.Parent then
		return;
	end

	local pos1 = self:GetPos():ToScreen();
	local pos2 = self.Parent:GetPos():ToScreen();
	if not pos1.visible and not pos2.visible then
		return;
	end

	surface.SetDrawColor(255, 0, 255);
	surface.DrawLine(pos1.x, pos1.y, pos2.x, pos2.y);

end

RGM.Bone = BONE;
RGM.Bones = {};