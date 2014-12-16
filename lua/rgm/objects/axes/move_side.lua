
local AXIS = setmetatable({}, RGM.AxisBase);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Move;
AXIS.Priority = 2;

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("MoveSide", gizmo, direction);
end

function AXIS:OnGrabUpdate()
	-- TODO
end

function AXIS:GetColors()
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

RGM.AxisMoveSide = AXIS;