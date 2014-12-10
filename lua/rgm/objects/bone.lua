--[[
	Bones are arbitrary objects tied to real entities. They can either be tied to physical bones, manipulatable bones or the entity's root position.
	We use these to make position manipulation more structured and reliable.
	On client, bones are also used to render and trace for selection.
]]

if SERVER then
	util.AddNetworkString("RGMBuildBones");
	util.AddNetworkString("RGMRemoveBones");
end

RGM.BoneTypes = {
	Root = 1,
	Physbone = 2,
	Bone = 3	
};

local BONE = {};
BONE.__index = BONE;

function BONE.New(skeleton, type, boneIndex)

	local bone = setmetatable({}, BONE);
	bone.ID = math.random(1, 999999);
	bone.Skeleton = skeleton;
	bone.Entity = skeleton.Entity;

	bone.Type = type;
	bone.Index = boneIndex;

	bone.Parent = nil;

	bone._Position = self:GetRealPos();
	bone._Angles = self:GetRealAngles();
	bone._Scale = self:GetRealScale();

	bone.RememberedPos = Vector(0, 0, 0);
	bone.RememberedAngles = Angle(0, 0, 0);

	return bone;

end

-- Find the parent of this bone
function BONE:SetupParent()

	if self.Type == RGM.BoneTypes.Root then
		return;
	end

	if self.Type == RGM.BoneTypes.Physbone then

		local physParent = GetPhysBoneParent(self.Entity, self.Index);
		local phys = table.First(self.Skeleton.Bones, function(item)
			return item.Entity == self.Entity and item.Type == RGM.BoneTypes.Physbone and item.Index == physParent;
		end);
		if physParent >= 0 and phys then
			self.Parent = phys;
		end

	elseif self.Type == RGM.BoneTypes.Bone then

		-- TODO

	end

end

function BONE:GetChildren()
	if not self.Children then
		self.Children = table.Where(self.Skeleton.Bones, function(item) return item.Parent == self; end);
	end
	return self.Children;
end

function BONE:GetConstraints()
	if not self.Constraints then
		self.Constraints = table.Where(self.Skeleton.Constraints, function(item) return table.HasValue(item.Bones, self); end);
	end
	return self.Constraints;
end

---
-- Position, angle and scale methods
-- There are abstract version of these values stored in _Position, _Angle and _Scale, 
-- and these are applied to the actual object when CommitChanges is called.
---

function BONE:GetPosAng()
	return self:GetPos(), self:GetAngles();
end

function BONE:GetPos()
	return self._Position;
end

function BONE:GetAngles()
	return self._Angles;
end

function BONE:GetScale()
	return self._Scale;
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

function BONE:SetPosAng(position, angles)

	local myPos, myAng = self:GetPosAng();

	-- Store child relative positions
	local children = self:GetChildren();
	for _, child in pairs(children) do
		child:RememberOffset();
	end

	self._Position = position;
	self._Angles = angles;

	-- Restore child relative positions
	for _, child in pairs(children) do
		child:RestoreOffset();
	end

end

function BONE:SetPos(position)
	self:SetPosAng(position, self:GetAngles());
end

function BONE:SetAngles(angles)
	self:SetPosAng(self:GetPos(), angles);
end

function BONE:SetScale(scale)
	self._Scale = scale;
end

function BONE:GetRealPos()
	if self.Type == RGM.BoneTypes.Root then
		return self.Entity:GetPos();
	elseif self.Type == RGM.BoneTypes.Physbone then
		return self.Entity:GetPhysicsObjectNum(self.Index):GetPos();
	elseif self.Type == RGM.BoneTypes.Bone then
		local pos, ang = self.Entity:GetBonePosition(self.Index);
		return pos;
	end
end

function BONE:GetRealAngles()
	if self.Type == RGM.BoneTypes.Root then
		return self.Entity:GetAngles();
	elseif self.Type == RGM.BoneTypes.Physbone then
		return self.Entity:GetPhysicsObjectNum(self.Index):GetAngles();
	elseif self.Type == RGM.BoneTypes.Bone then
		local pos, ang = self.Entity:GetBonePosition(self.Index);
		return ang;
	end
end

function BONE:GetRealScale()
	if self.Type == RGM.BoneTypes.Root then
		return self.Entity:GetManipulateBoneScale(0);
	elseif self.Type == RGM.BoneTypes.Physbone then
		local bone = PhysBoneToBone(self.Entity, self.Index);
		return self.Entity:GetManipulateBoneScale(bone);
	elseif self.Type == RGM.BoneTypes.Bone then
		return self.Entity:GetManipulateBoneScale(self.Index);
	end
end

function BONE:SetRealPosAng(position, angles)
	if self.Type == RGM.BoneTypes.Root then

		self.Entity:SetPos(position);
		self.Entity:SetAngles(angles);

	elseif self.Type == RGM.BoneTypes.Physbone then

		local physObj = self.Entity:GetPhysicsObjectNum(self.Index);
		physObj:SetPos(position);
		physObj:SetAngles(angles);
		physObj:Wake();

	elseif self.Type == RGM.BoneTypes.Bone then

		local pPos, pAng = self.Parent:GetPosAng();
		local pos, ang = WorldToLocal(position, myAng, pPos, pAng);
		self.Entity:ManipulateBonePosition(self.Index, pos);

	end
end

function BONE:SetRealScale(scale)
	if self.Type == RGM.BoneTypes.Root then
		self.Entity:ManipulateBoneScale(0, scale);
	elseif self.Type == RGM.BoneTypes.Physbone then
		local bone = PhysBoneToBone(self.Entity, self.Index);
		self.Entity:ManipulateBoneScale(bone, scale);
	elseif self.Type == RGM.BoneTypes.Bone then
		self.Entity:ManipulateBoneScale(self.Index, scale);
	end
end

function BONE:CommitChanges()

	self:SetRealPosAng(self._Position, self._Angles);
	self:SetRealScale(self._Scale);

	self._Position = self:GetRealPos();
	self._Angles = self:GetRealAngles();
	self._Scale = self:GetRealScale();

end

function BONE:RememberOffset()

	local pos, ang = self:GetLocalPosAng();
	self.RememberedPos = pos;
	self.RememberedAngles = ang;

end

function BONE:RestoreOffset()

	if not self.Parent then
		return;
	end

	local pPos, pAng = self.Parent:GetPosAng();
	local pos, ang = LocalToWorld(self.RememberedPos, self.RememberedAngles, pPos, pAng);
	self:SetPosAng(pos, ang);

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