
local AXIS = setmetatable({}, RGM.AxisRotate);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Rotate;
AXIS.Priority = 2;

-- Build a disc from lines
AXIS.DrawLines = {};
local lineCount = 32;
local rotateAngle = Angle(0, 0, 360 / lineCount);
local startNormal = Vector(0, 0, 1.1);
for i = 1, lineCount do
	local startPos = startNormal * 1;
	local endPos = startNormal * 1;
	startPos:Rotate(rotateAngle * (i - 1));
	endPos:Rotate(rotateAngle * i);
	table.insert(AXIS.DrawLines, {Start = startPos, End = endPos});
end

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("RotateFaced", gizmo, direction);
end

function AXIS:GetColor()
	return Color(150, 150, 150, 255);
end

function AXIS:GetAngles()
	return self.Player:EyeAngles();
end

function AXIS:IsTraceHit(intersect)

	local player = self.Player;
	local pos, angles = self:GetPos(), self:GetAngles();

	local scale = player.RGMData.Scale * 1.1;
	local thickness = scale * 0.1;
	local minDistance, maxDistance = scale - thickness / 2, scale + thickness / 2;

	local distance = intersect:Distance(pos);
	return distance >= minDistance and distance <= maxDistance;

end

RGM.AxisRotateFaced = AXIS;