
---
-- A crucial constraint for posing - Inverse Kinematics
---

local IK = setmetatable({}, RGM.Constraint);
IK.__index = IK;

function IK:Init()

	if #self.Bones ~= 3 then
		error("RGM IKConstraint - Constraint requires exactly 3 bones!");
	end

	self.HipBone = self.Bones[1];
	self.KneeBone = self.Bones[2];
	self.FootBone = self.Bones[3];

end

-- Get the directional angle from bone1 to bone2
local function GetDirectionAngles(bone1, bone2)
	return (bone2:GetPos() - bone1:GetPos()):Angle();
end

-- Used to get the angles of bone1 relative to directional angles
local function GetRelativeAngles(bone1, bone2)
	local dirAngle = GetDirectionAngles(bone1, bone2);
	local _, relativeAngle = WorldToLocal(bone1:GetPos(), bone1:GetAngles(), bone1:GetPos(), dirAngle);
	return relativeAngle;
end

-- Restore the actual angles from the current directional angle
local function GetAnglesFromDir(bone1, bone2, relativeAngle)
	local dirAngle = GetDirectionAngles(bone1, bone2);
	local _, angles = LocalToWorld(Vector(0, 0, 0), relativeAngle, bone1:GetPos(), dirAngle);
	return angles;
end

-- Get knee direction from the middle position between hip and foot
local function GetKneeDir(hipBone, kneeBone, footBone)
	local dirOrigin = LerpVector(0.5, hipBone:GetPos(), footBone:GetPos());
	local dir = (kneeBone:GetPos() - dirOrigin):GetNormalized();
	return dir;
end

function IK:OnGrab(selectedBone)

	local data = {};

	data.HipOffsetAngles = GetRelativeAngles(self.HipBone, self.KneeBone);
	data.HipKneeDistance = self.HipBone:GetPos():Distance(self.KneeBone:GetPos());

	data.KneeOffsetAngles = GetRelativeAngles(self.KneeBone, self.FootBone);
	data.KneeDirection = GetKneeDir(self.HipBone, self.KneeBone, self.FootBone);
	data.KneeFootDistance = self.KneeBone:GetPos():Distance(self.FootBone:GetPos());

	data.FootPosition, data.FootAngles = self.FootBone:GetPosAng();

	self.KneeData = data;

end

function IK:OnMoveUpdate(selectedBone)

	local data = self.KneeData;
		
	local hipPos = self.HipBone:GetPos();

	if selectedBone ~= self.FootBone then
		self.FootBone:SetPosAng(data.FootPosition, data.FootAngles);
	end

	local kneePos = RGM.FindKnee(hipPos, data.FootPosition, data.HipKneeDistance, data.KneeFootDistance, data.KneeDirection);
	if selectedBone == self.KneeBone then
		local kneeDir = GetKneeDir(self.HipBone, self.KneeBone, self.FootBone);
		kneePos = RGM.FindKnee(hipPos, data.FootPosition, data.HipKneeDistance, data.KneeFootDistance, kneeDir);
	end

	self.KneeBone:SetPos(kneePos);
	local kneeAngles = GetAnglesFromDir(self.KneeBone, self.FootBone, data.KneeOffsetAngles);
	self.KneeBone:SetAngles(kneeAngles);

	if selectedBone ~= self.HipBone then
		local hipAngles = GetAnglesFromDir(self.HipBone, self.KneeBone, data.HipOffsetAngles);
		self.HipBone:SetAngles(hipAngles);
	end

end

RGM.IKConstraint = IK;