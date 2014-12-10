
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

---
--	Key function for IK chains: finding the knee position (in case of arms, it's elbow position)
--	Arguments in order are: hip position, ankle position, thigh length, shin length, knee vector direction.
--	
--	Got the math from this thread:
--	http://forum.unity3d.com/threads/40431-IK-Chain
---
local function FindKnee(pHip, pAnkle, fThigh, fShin, vKneeDir)
	local vB = pAnkle - pHip;
	local LB = vB:Length();
	local aa = (LB * LB + fThigh * fThigh - fShin * fShin) / 2 / LB;
	local bb = math.sqrt(fThigh * fThigh - aa * aa);
	local vF = vB:Cross(vKneeDir:Cross(vB));
	vB:Normalize();
	vF:Normalize();
	return pHip + (aa * vB) + (bb * vF);
end

-- Get the directional angle from bone1 to bone2
local function GetDirectionAngles(bone1, bone2)
	return (bone2:GetPos() - bone1:GetPos()):Angle();
end

-- Used to get the angles of bone1 relative to directional angles
local function GetRelativeAngles(bone1, bone2)
	local dirAngle = GetDirectionAngles(bone1, bone2);
	local _, relativeAngle = WorldToLocal(bone1:GetPosAng(), bone1:GetPos(), dirAngle);
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

function IK:BeforeChange(selectedBone)

	local data = {};

	data.HipOffsetAngles = GetRelativeAngles(self.HipBone, bone);
	data.HipKneeDistance = self.HipBone:GetPos():Distance(bone:GetPos());

	data.KneeOffsetAngles = GetRelativeAngles(bone, self.FootBone);
	data.KneeDirection = GetKneeDir(self.HipBone, bone, self.FootBone);
	data.KneeFootDistance = bone:GetPos():Distance(self.FootBone:GetPos());

	data.FootPosition, data.FootAngles = self.FootBone:GetPosAng();

	self.KneeData = data;

end

function IK:AfterChange(selectedBone)

	local data = self.KneeData;
		
	local hipPos = self.HipBone:GetPos();
	local kneePos = FindKnee(hipPos, data.FootPosition, data.HipKneeDistance, data.KneeFootDistance, data.KneeDirection);

	-- Directly manipulate bone variables to skip the default chain reaction
	local angles = GetAnglesFromDir(self.HipBone, self.KneeBone, data.HipOffsetAngles);
	self.HipBone._Angles = angles;

	self.KneeBone._Position = kneePos;
	angles = GetAnglesFromDir(self.KneeBone, self.FootBone, data.KneeFootDistance);
	self.KneeBone._Angles = angles;

	if selectedBone ~= self.FootBone then
		self.FootBone:SetPosAng(data.FootPosition, data.FootAngles);
	end

	self.KneeData = nil;

end

RGM.IKConstraint = IK;