
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
	Min = Vector(0, -0.1, -0.1),
	Max = Vector(1, 0.1, 0.1)
};

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("Move", gizmo, direction);
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
	localPos.z = 0;

	pos, angles = LocalToWorld(localPos, Angle(0, 0, 0), pos ,angles);
	bone:SetPos(pos);

end

function AXIS:GetIntersectNormal()
	return self:GetAngles():Up();
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