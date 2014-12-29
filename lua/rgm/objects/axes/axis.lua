
RGM.AxisDirections = {

	Up = 1,
	Forward = 2,
	Right = 3,

	UpForward = 1,
	UpRight = 2,
	ForwardRight = 3,

	Pitch = 1,
	Yaw = 2,
	Roll = 3

};

local AXIS = {};
AXIS.__index = AXIS;

AXIS.Priority = 0;

AXIS.DrawLines = {};
AXIS.Bounds = {
	Min = Vector(-1, -1, -1),
	Max = Vector(1, 1, 1)
};

function AXIS.CreateBase(type, gizmo, direction)

	local axis = setmetatable({}, RGM["Axis" .. type]);
	axis.ID = math.random(1, 999999);
	axis.Type = type;
	axis.Player = gizmo.Player;
	axis.Direction = direction;

	return axis;

end

function AXIS:GetPos()

	local player = self.Player;
	if not player.RGMSelectedBone then
		return Vector(0, 0, 0);
	end

	return player.RGMSelectedBone:GetRealPos();

end

function AXIS:GetAngleOffset()
	if self.Direction == RGM.AxisDirections.Up then
		return Vector(0, 0, 1):Angle();
	elseif self.Direction == RGM.AxisDirections.Forward then
		return Vector(1, 0, 0):Angle();
	elseif self.Direction == RGM.AxisDirections.Right then
		return Vector(0, 1, 0):Angle();
	end
	return Angle(0, 0, 0);
end

function AXIS:GetAngles()

	local player = self.Player;
	if not player.RGMSelectedBone then
		return Angle(0, 0, 0);
	end

	local offset = self:GetAngleOffset();
	local localized = player.RGMSettings and player.RGMSettings.LocalAxis;

	if localized then
		local boneAngles = player.RGMSelectedBone:GetRealAngles();
		local pos, ang = LocalToWorld(Vector(0, 0, 0), offset, Vector(0, 0, 0), boneAngles);
		return ang;
	else
		return offset;
	end

end

function AXIS:GetBounds()
	return self.Bounds;
end

function AXIS:IsTraceHit(intersect)
	local pos, angles = self:GetPos(), self:GetAngles();
	local localPos, _ = WorldToLocal(intersect, angles, pos, angles);
	local scale = self.Player.RGMData.Scale;
	local bounds = self:GetBounds();
	return VectorWithin(localPos, bounds.Min * scale, bounds.Max * scale);
end

function AXIS:GetIntersectNormal()
	return self:GetAngles():Forward();
end

function AXIS:GetIntersect(eyePos, eyeAngles)

	local player = self.Player;
	local eyeNormal = eyeAngles:Forward();
	local planePoint = self:GetPos();
	local planeNormal = self:GetIntersectNormal();

	return RGM.IntersectRayWithPlane(planePoint, planeNormal, eyePos, eyeNormal);

end

-- When grabbed, get the offset
function AXIS:OnGrab()

	local player = self.Player;
	local eyePos, eyeAngles = RGM.GetEyePosAng(player);
	local intersect = self:GetIntersect(eyePos, eyeAngles);

	local pos, ang = WorldToLocal(intersect, self:GetAngles(), self:GetPos(), self:GetAngles());
	self.GrabOffset = pos;

end

function AXIS:OnRelease()
	-- Nothing to do at the moment
end

function AXIS:Trace(eyePos, eyeAngles)
	local intersect = self:GetIntersect(eyePos, eyeAngles);
	if self:IsTraceHit(intersect) then
		return {Position = intersect, Distance = intersect:Distance(eyePos)};
	else
		return nil;
	end
end

function AXIS:Draw(highlight)

	local color = self:GetColor();
	if highlight then
		color = Color(255, 255, 0, 255);
	end

	local pos, angles = self:GetPos(), self:GetAngles();
	local scale = self.Player.RGMData.Scale;

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

-- Functions that need to be overridden
function AXIS:OnGrabUpdate() end

RGM.AxisBase = AXIS;