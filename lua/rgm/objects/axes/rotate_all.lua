
local AXIS = setmetatable({}, RGM.AxisBase);
AXIS.__index = AXIS;

AXIS.Mode = RGM.GizmoModes.Rotate;
AXIS.Priority = 3;

function AXIS.Create(gizmo, direction)
	return AXIS.CreateBase("RotateAll", gizmo, direction);
end

function AXIS:OnGrabUpdate()
	-- TODO
end

function AXIS:GetColor()
	-- TODO
end

function AXIS:GetBounds()

	-- TODO

end

function AXIS:IsTraceHit(intersect)
	-- TODO
end

function AXIS:Draw(highlight)

	if not highlight then
		return;
	end

	-- TODO

end

RGM.AxisRotateAll = AXIS;