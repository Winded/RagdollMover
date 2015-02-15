
local discMaterial = Material("widgets/disc.png", "nocull alphatest smooth mips");

local AXIS = setmetatable({}, RGM.AxisBase);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Rotate;
AXIS.Priority = 1;

-- Build a disc from lines
AXIS.DrawLines = {};
local lineCount = 32;
local rotateAngle = Angle(0, 0, 360 / lineCount);
local startNormal = Vector(0, 0, 1);
for i = 1, lineCount do
	local startPos = startNormal * 1;
	local endPos = startNormal * 1;
	startPos:Rotate(rotateAngle * (i - 1));
	endPos:Rotate(rotateAngle * i);
	table.insert(AXIS.DrawLines, {Start = startPos, End = endPos});
end

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("Rotate", gizmo, direction);
end

function AXIS:OnGrabUpdate()

	local player = self.Player;
	local eyePos, eyeAngles = RGM.GetEyePosAng(player);
	local bone = RGM.GetSelectedBone(player);
	local intersect = self:GetIntersect(eyePos, eyeAngles);
	local pos, angles = self:GetPos(), self:GetAngles();
	local grabAngleOffset = self.GrabAngleOffset;

	local grabOffset, _ = WorldToLocal(intersect, angles, pos, angles);

	bone:SetAngles(newAngles);

end

function AXIS:GetAngleOffset()
	if self.Direction == RGM.AxisDirections.Pitch then
		return Vector(0, 1, 0):Angle();
	elseif self.Direction == RGM.AxisDirections.Yaw then
		return Vector(0, 0, 1):Angle();
	elseif self.Direction == RGM.AxisDirections.Roll then
		return Vector(1, 0, 0):Angle();
	end
	return Angle(0, 0, 0);
end

function AXIS:GetColor()
	if self.Direction == RGM.AxisDirections.Pitch then
		return Color(255, 0, 0);
	elseif self.Direction == RGM.AxisDirections.Yaw then
		return Color(0, 255, 0);
	elseif self.Direction == RGM.AxisDirections.Roll then
		return Color(0, 0, 255);
	end
	return Color(0, 0, 0);
end

function AXIS:IsTraceHit(intersect)

	local player = self.Player;
	local pos, angles = self:GetPos(), self:GetAngles();

	local scale = player.RGMData.Scale;
	local thickness = scale * 0.1;
	local minDistance, maxDistance = scale - thickness / 2, scale + thickness / 2;

	local distance = intersect:Distance(pos);
	return distance >= minDistance and distance <= maxDistance;

end

RGM.AxisRotate = AXIS;