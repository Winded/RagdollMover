
local AXIS = setmetatable({}, RGM.AxisBase);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Move;
AXIS.Priority = 0;

AXIS.Bounds = {
	Min = Vector(-0.05, -0.05, -0.05),
	Max = Vector(0.05, 0.05, 0.05)
};

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("MoveFaced", gizmo, direction);
end

function AXIS:OnGrabUpdate()

	local player = self.Player;
	local eyePos, eyeAngles = RGM.GetEyePosAng(player);
	local bone = RGM.GetSelectedBone(player);
	local intersect = self:GetIntersect(eyePos, eyeAngles);
	local grabOffset = self.GrabOffset;
	local pos, angles = self:GetPos(), self:GetAngles();

	local localPos, _ = WorldToLocal(intersect, angles, pos, angles);
	localPos.x = 0;
	localPos.y = localPos.y - grabOffset.y;
	localPos.z = localPos.z - grabOffset.z;

	pos, angles = LocalToWorld(localPos, Angle(0, 0, 0), pos ,angles);
	bone:SetPos(pos);

end

function AXIS:GetAngles()
	return self.Player:EyeAngles();
end

function AXIS:GetColor()
	return Color(64, 64, 64);
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

RGM.AxisMoveFaced = AXIS;