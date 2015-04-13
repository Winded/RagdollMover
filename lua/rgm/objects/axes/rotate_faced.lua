
local AXIS = setmetatable({}, RGM.AxisRotate);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Rotate;
AXIS.Priority = 2;

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("RotateFaced", gizmo, direction);
end

function AXIS:GetColor()
	return Color(150, 150, 150, 255);
end

function AXIS:GetSecondColor()
	return Color(200, 200, 200, 255);
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

function AXIS:DrawDisc(scale, color)

	local pos, angles = self:GetPos(), self:GetAngles();

	local screenLines = {};
	for _, line in pairs(self.DrawLines) do
		local sLine = {};
		local startPos = LocalToWorld(line.Start * scale, Angle(0, 0, 0), pos, angles);
		sLine.Start = startPos:ToScreen();
		local endPos = LocalToWorld(line.End * scale, Angle(0, 0, 0), pos, angles);
		sLine.End = endPos:ToScreen();
		table.insert(screenLines, sLine);
	end

	surface.SetDrawColor(color);
	for _, line in pairs(screenLines) do
		surface.DrawLine(line.Start.x, line.Start.y, line.End.x, line.End.y);
	end

end

function AXIS:Draw(highlight)

	local scale = self.Player.RGMData.Scale;
	local fullDiscs = self.Player.RGMData.FullDiscs;
	local color1 = self:GetColor();
	local color2 = self:GetSecondColor();
	if highlight then
		color1 = Color(255, 255, 0, 255);
	end

	self:DrawDisc(scale * 1.1, color1);
	if not fullDiscs then
		self:DrawDisc(scale, color2);
	end

end

RGM.AxisRotateFaced = AXIS;