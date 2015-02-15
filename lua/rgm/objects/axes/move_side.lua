
local AXIS = setmetatable({}, RGM.AxisBase);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Move;
AXIS.Priority = 2;

AXIS.DrawLines = {
	{Start = Vector(0.25, 0, 0), End = Vector(0.25, 0, 0.25)},
	{Start = Vector(0.25, 0, 0.25), End = Vector(0, 0, 0.25)}
};
AXIS.Bounds = {
	Min = Vector(0, -0.25, 0),
	Max = Vector(0.25, 0.25, 0.25)
};

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("MoveSide", gizmo, direction);
end

function AXIS:OnGrabUpdate()

	local player = self.Player;
	local eyePos, eyeAngles = RGM.GetEyePosAng(player);
	local bone = RGM.GetSelectedBone(player);
	local intersect = self:GetIntersect(eyePos, eyeAngles);
	local grabOffset = self.GrabOffset;
	local pos, angles = self:GetPos(), self:GetAngles();

	local localPos, _ = WorldToLocal(intersect, angles, pos, angles);
	localPos.x = localPos.x - grabOffset.x;
	localPos.y = 0;
	localPos.z = localPos.z - grabOffset.z;

	pos, angles = LocalToWorld(localPos, Angle(0, 0, 0), pos ,angles);
	bone:SetPos(pos);

end

function AXIS:GetAngleOffset()
	if self.Direction == RGM.AxisDirections.UpForward then
		return Vector(1, 0, 0):Angle();
	elseif self.Direction == RGM.AxisDirections.UpRight then
		return Vector(0, 1, 0):Angle();
	elseif self.Direction == RGM.AxisDirections.ForwardRight then
		return Angle(0, 0, -90);
	end
	return Angle(0, 0, 0);
end

function AXIS:GetIntersectNormal()
	return self:GetAngles():Right();
end

function AXIS:GetColors()

	local red = Color(255, 0, 0, 255);
	local green = Color(0, 255, 0, 255);
	local blue = Color(0, 0, 255, 255);

	if self.Direction == RGM.AxisDirections.UpForward then
		return red, blue;
	elseif self.Direction == RGM.AxisDirections.UpRight then
		return green, blue;
	elseif self.Direction == RGM.AxisDirections.ForwardRight then
		return red, green;
	end

end

function AXIS:Draw(highlight)

	local color1, color2 = self:GetColors();
	if highlight then
		color1 = Color(255, 255, 0, 255);
		color2 = Color(255, 255, 0, 255);
	end

	local pos, angles = self:GetPos(), self:GetAngles();
	local scale = RGM.GetSettings(self.Player).Scale or 10;

	local screenLines = {};
	for _, line in pairs(self.DrawLines) do
		local sLine = {};
		local startPos = LocalToWorld(line.Start * scale, Angle(0, 0, 0), pos, angles);
		sLine.Start = startPos:ToScreen();
		local endPos = LocalToWorld(line.End * scale, Angle(0, 0, 0), pos, angles);
		sLine.End = endPos:ToScreen();
		table.insert(screenLines, sLine);
	end

	local color = false;
	for _, line in pairs(screenLines) do

		if color then
			surface.SetDrawColor(color2);
		else
			surface.SetDrawColor(color1);
		end
		color = not color;

		surface.DrawLine(line.Start.x, line.Start.y, line.End.x, line.End.y);

	end

end

RGM.AxisMoveSide = AXIS;