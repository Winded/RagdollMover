
local AXIS = setmetatable({}, RGM.AxisBase);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Move;
AXIS.Priority = 0;

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("MoveFaced", gizmo, direction);
end

function AXIS:OnGrabUpdate()
	-- TODO
end

function AXIS:GetAngles()
	return self.Player:EyeAngles();
end

function AXIS:GetColor()
	-- TODO
end

function AXIS:GetBounds()

	-- TODO

end

function AXIS:IsTraceHit(intersect)
	-- local bounds = self:GetBounds();
	-- return intersect >= bounds.min and intersect <= bounds.max;
end

function AXIS:Draw(highlight)

	-- TODO

end

RGM.AxisMoveFaced = AXIS;