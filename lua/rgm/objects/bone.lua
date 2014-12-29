--[[
	Bones are arbitrary objects tied to real entities. They can either be tied to physical bones, manipulatable bones or the entity's root position.
	We use these to make position manipulation more structured and reliable.
	On client, bones are also used to render that fancy bone icon
]]

RGM.BoneTypes = {
	Root = 1,
	Physbone = 2,
	Bone = 3	
};

local boneMaterial = Material("widgets/bone.png", "unlitsmooth");
local boneMaterialSmall = Material("widgets/bone_small.png", "unlitsmooth");

local BONE = {};
BONE.__index = BONE;

function BONE.Create(entity, type, boneIndex)

	local bone = setmetatable({}, BONE);
	bone.ID = math.random(1, 999999);
	-- We store the owning entity to the bone instead of the skeleton, because that would cause stack overflow when serializing
	bone.Entity = entity;

	bone.Type = type;
	bone.Index = boneIndex;

	bone.Parent = nil;

	bone.Editing = false;
	bone._Position = bone:GetRealPos();
	bone._Angles = bone:GetRealAngles();
	bone._Scale = bone:GetRealScale();

	bone.RememberedPos = Vector(0, 0, 0);
	bone.RememberedAngles = Angle(0, 0, 0);

	return bone;

end

-- Find the parent of this bone
function BONE:SetupParent(bones)

	if self.Type == RGM.BoneTypes.Root then
		return;
	end

	if self.Type == RGM.BoneTypes.Physbone then

		local physParent = GetPhysBoneParent(self.Entity, self.Index);
		local phys = table.First(bones, function(item)
			return item.Entity == self.Entity and item.Type == RGM.BoneTypes.Physbone and item.Index == physParent;
		end);
		if physParent >= 0 and phys then
			self.Parent = phys;
		end

	elseif self.Type == RGM.BoneTypes.Bone then

		-- TODO

	end

end

function BONE:GetSkeleton()
	return self.Entity.RGMSkeleton;
end

function BONE:GetChildren()
	if not self.Children then
		local skeleton = self:GetSkeleton();
		self.Children = table.Where(skeleton.Bones, function(item) return item.Parent == self; end);
	end
	return self.Children;
end

-- Has the given player selected this bone?
function BONE:IsSelected(player)
	return player.RGMSelectedBone == self;
end

function BONE:GetPosAng()
	return self:GetPos(), self:GetAngles();
end

function BONE:GetPos()
	if self.Editing then
		return self._Position;
	else
		return self:GetRealPos();
	end
end

function BONE:GetAngles()
	if self.Editing then
		return self._Angles;
	else
		return self:GetRealAngles();
	end
end

function BONE:GetScale()
	if self.Editing then
		return self._Scale;
	else
		return self:GetRealScale();
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

function BONE:SetPosAng(position, angles)
	self:SetPos(position);
	self:SetAngles(angles);
end

function BONE:SetPos(position)
	if self.Editing then
		self._Position = position;
	else
		self:SetRealPosAng(position, self:GetAngles());
	end
end

function BONE:SetAngles(angles)
	if self.Editing then
		self._Angles = angles;
	else
		self:SetRealPosAng(self:GetPos(), angles);
	end
end

function BONE:SetScale(scale)
	if self.Editing then
		self._Scale = scale;
	else
		self:SetRealScale(scale);
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

function BONE:StartEditing()

	if self.Editing then
		return;
	end

	self._Position = self:GetRealPos();
	self._Angles = self:GetRealAngles();
	self._Scale = self:GetRealScale();
	self.Editing = true;

end

function BONE:StopEditing()

	self:ApplyEdits();
	self.Editing = false;

end

function BONE:ApplyEdits()

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

-- Draw the bone. Should be called between cam.Start3D and cam.End3D
function BONE:Draw()

	local startPos = self:GetRealPos();

	local children = self:GetChildren();

	local alpha = 255;
	if RGM.GetAimedBone() ~= self then
		alpha = 20;
	end

	if #children == 0 then
		local endPos = startPos + self:GetRealAngles():Forward() * 10;

		local length = startPos:Distance(endPos);
		local width = length * 0.2;

		if length > 10 then
			render.SetMaterial(boneMaterial);
		else
			render.SetMaterial(boneMaterialSmall);
		end

		cam.IgnoreZ(true);
		render.DrawBeam(startPos, endPos, width, 0, 1, Color(255, 255, 255, alpha * 0.5));
		cam.IgnoreZ(false);

		render.DrawBeam(startPos, endPos, width, 0, 1, Color(255, 255, 255, alpha));

		return;
	end

	for _, child in pairs(children) do
		local endPos = child:GetRealPos();

		local length = startPos:Distance(endPos);
		local width = length * 0.2;

		if length > 10 then
			render.SetMaterial(boneMaterial);
		else
			render.SetMaterial(boneMaterialSmall);
		end

		cam.IgnoreZ(true);
		render.DrawBeam(startPos, endPos, width, 0, 1, Color(255, 255, 255, alpha * 0.5));
		cam.IgnoreZ(false);

		render.DrawBeam(startPos, endPos, width, 0, 1, Color(255, 255, 255, alpha));
	end

end

RGM.Bone = BONE;