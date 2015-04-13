
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
	-- Flip y-z plane to x-y, turn the vector to angle and convert it's yaw to roll, and reduce the angle offset
	local rAngles = Angle(0, 0, Vector(grabOffset.y, grabOffset.z, 0):Angle().y) - grabAngleOffset;
	local _, newGizmoAngles = LocalToWorld(Vector(0, 0, 0), rAngles, pos, angles);

	-- Finally, add the bone offset to our new gizmo angle
	local _, newAngles = LocalToWorld(self.BoneOffset, self.BoneAngleOffset, pos, newGizmoAngles);

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

-- Mostly the same as Axis.Draw but with the ability to ignore lines behind the gizmo position
function AXIS:Draw(highlight)

	local color = self:GetColor();
	if highlight then
		color = Color(255, 255, 0, 255);
	end

	local pos, angles = self:GetPos(), self:GetAngles();
	local eyePos = self.Player:EyePos();
	local scale = self.Player.RGMData.Scale;
	local fullDiscs = self.Player.RGMData.FullDiscs;

	local screenLines = {};
	for _, line in pairs(self.DrawLines) do
		local sLine = {};
		local startPos = LocalToWorld(line.Start * scale, Angle(0, 0, 0), pos, angles);
		local endPos = LocalToWorld(line.End * scale, Angle(0, 0, 0), pos, angles);
		if fullDiscs or highlight or (startPos:Distance(eyePos) <= pos:Distance(eyePos) and endPos:Distance(eyePos) <= pos:Distance(eyePos)) then
			sLine.Start = startPos:ToScreen();
			sLine.End = endPos:ToScreen();
			table.insert(screenLines, sLine);
		end
	end

	surface.SetDrawColor(color);
	for _, line in pairs(screenLines) do
		surface.DrawLine(line.Start.x, line.Start.y, line.End.x, line.End.y);
	end

end

RGM.AxisRotate = AXIS;