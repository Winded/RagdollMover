
local discMaterial = Material("widgets/disc.png", "nocull alphatest smooth mips");

local AXIS = setmetatable({}, RGM.AxisBase);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Rotate;
AXIS.Priority = 1;

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("Rotate", gizmo, direction);
end

function AXIS:OnGrabUpdate()
	-- TODO
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
		return Color(255, 0, 0, 255);
	elseif self.Direction == RGM.AxisDirections.Yaw then
		return Color(0, 255, 0, 255);
	elseif self.Direction == RGM.AxisDirections.Roll then
		return Color(0, 0, 255, 255);
	end
	return Color(0, 0, 0, 255);
end

function AXIS:IsTraceHit(intersect)

	local player = self.Player;
	local pos, angles = self:GetPos(), self:GetAngles();

	local scale = RGM.GetSettings(player).Scale or 10;
	local thickness = scale * 0.1;
	local minDistance, maxDistance = scale - thickness / 2, scale + thickness / 2;

	local distance = intersect:Distance(pos);
	return distance >= minDistance and distance <= maxDistance;

end

function AXIS:Draw(highlight)

	local color = self:GetColor();
	if highlight then
		color = Color(255, 255, 0, 255);
	end

	local player = self.Player;
	local pos, angles = self:GetPos(), self:GetAngles();
	local forward = angles:Forward();

	local scale = RGM.GetSettings(player).Scale or 10;
	local thickness = scale * 0.1;
	local size = scale + thickness / 2;

	render.SetMaterial(discMaterial);

	cam.IgnoreZ(true);
	render.DrawQuadEasy(pos, forward, size, size, color, 0);
	cam.IgnoreZ(false);

end

RGM.AxisRotate = AXIS;