
local arrowMaterial = Material("widgets/arrow.png", "nocull alphatest smooth mips");

local AXIS = setmetatable({}, RGM.AxisBase);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Move;
AXIS.Priority = 1;

AXIS.DrawLines = {
	{Start = Vector(0, 0, 0), End = Vector(1, 0, 0)},
	{Start = Vector(1, 0, 0), End = Vector(0.9, 0.1, 0)},
	{Start = Vector(1, 0, 0), End = Vector(0.9, -0.1, 0)}
};
AXIS.Bounds = {
	Min = Vector(0, -0.1, 0),
	Max = Vector(1, 0.1, 0)
};

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("Move", gizmo, direction);
end

function AXIS:OnGrabUpdate()
	-- TODO
end

function AXIS:GetIntersect(eyePos, eyeAngles)

	local player = self.Player;
	local eyeNormal = eyeAngles:Forward();
	local planePoint = self:GetPos();
	local planeNormal = self:GetAngles():Up();

	return RGM.IntersectRayWithPlane(planePoint, planeNormal, eyePos, eyeNormal);

end

function AXIS:GetColor()
	if self.Direction == RGM.AxisDirections.Up then
		return Color(0, 0, 255, 255);
	elseif self.Direction == RGM.AxisDirections.Forward then
		return Color(255, 0, 0, 255);
	elseif self.Direction == RGM.AxisDirections.Right then
		return Color(0, 255, 0, 255);
	end
	return Color(0, 0, 0, 255);
end

RGM.AxisMove = AXIS;