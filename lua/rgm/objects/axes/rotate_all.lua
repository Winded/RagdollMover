
local AXIS = setmetatable({}, RGM.AxisBase);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Rotate;
AXIS.Priority = 3;

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("RotateAll", gizmo, direction);
end

function AXIS:OnGrab()

	RGM.AxisBase.OnGrab(self);

	local eyePos, eyeAngles = RGM.GetEyePosAng(self.Player);
	local pos, angles = self:GetPos(), self:GetAngles();
	local intersect = RGM.IntersectRayWithPlane(pos, angles:Forward(), eyePos, eyeAngles:Forward());

	self.LastIntersect = intersect;

end

function AXIS:OnGrabUpdate()

	local data = self.Player.RGMData;
	local bone = RGM.GetSelectedBone(self.Player);
	local eyePos, eyeAngles = RGM.GetEyePosAng(self.Player);
	local pos, angles = self:GetPos(), self:GetAngles();
	local bPos, bAngles = bone:GetPos(), bone:GetAngles();

	local intersect = RGM.IntersectRayWithPlane(pos, angles:Forward(), eyePos, eyeAngles:Forward());
	local lastIntersect = self.LastIntersect;
	local pivotPoint = (lastIntersect + (intersect - lastIntersect) / 2) + eyeAngles:Forward() * (data.Scale / 2);
	local lastIntersectAngle = (lastIntersect - pivotPoint):Angle();
	local intersectAngle = (intersect - pivotPoint):Angle();

	local _, lLastIntersectAngle = WorldToLocal(bPos, lastIntersectAngle, bPos, bAngles);
	local _, lIntersectAngle = WorldToLocal(bPos, intersectAngle, bPos, bAngles);
	local angDiff = lIntersectAngle - lLastIntersectAngle;
	local newAngleNormal = bAngles:Forward();
	newAngleNormal:Rotate(angDiff);
	bone:SetAngles(newAngleNormal:Angle());

	self.LastIntersect = intersect;

end

function AXIS:GetColor()
	return Color(100, 100, 100, 255);
end

function AXIS:IsTraceHit(intersect)

	local player = self.Player;
	local pos, angles = self:GetPos(), self:GetAngles();

	local maxDistance = player.RGMData.Scale;

	local distance = intersect:Distance(pos);
	return distance <= maxDistance;

end

function AXIS:Draw(highlight)

	local color = self:GetColor();
	if highlight then
		color = Color(200, 200, 0);
	end

	local pos, angles = self:GetPos(), self:GetAngles();
	local scale = self.Player.RGMData.Scale;

	local screenPos = pos:ToScreen();
	if not screenPos.visible then
		return;
	end

	local width = scale;
	local height = scale;
	screenPos.x = screenPos.x - width / 2;
	screenPos.y = screenPos.y - height / 2;

	surface.SetDrawColor(color);
	surface.DrawRect(screenPos.x, screenPos.y, width, height);

end

RGM.AxisRotateAll = AXIS;