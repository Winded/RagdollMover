---
-- Gizmo is the thingy that contains axes that are used to move/rotate/scale the target entity
-- Each player have their own gizmo
---

RGM.GizmoModes = {
	Move = 1,
	Rotate = 2,
	Scale = 3
};

local GIZMO = {};
GIZMO.__index = GIZMO;

function GIZMO.Create(player)

	local g = setmetatable({}, GIZMO);
	g.ID = math.random(1, 9999999);
	g.Player = player;
	g:Init();

	player.RGMGizmo = g;

	net.Start("RGMGizmoCreate");
	net.WriteTable(g);
	net.Send(player);

	g:SetMode(RGM.GizmoModes.Move);

end

function GIZMO.CreateClient()

	local player = LocalPlayer();
	local g = setmetatable(net.ReadTable(), GIZMO);

	for _, axis in pairs(g.Axes) do
		setmetatable(axis, RGM["Axis" .. axis.Type]);
	end

	player.RGMGizmo = g;

end

function GIZMO:Init()

	-- Axes setup

	self.Axes = {

		RGM.AxisMove.Create(self, RGM.AxisDirections.Up),
		RGM.AxisMove.Create(self, RGM.AxisDirections.Forward),
		RGM.AxisMove.Create(self, RGM.AxisDirections.Right),

		RGM.AxisMoveSide.Create(self, RGM.AxisDirections.UpForward),
		RGM.AxisMoveSide.Create(self, RGM.AxisDirections.UpRight),
		RGM.AxisMoveSide.Create(self, RGM.AxisDirections.ForwardRight),

		RGM.AxisMoveFaced.Create(self),

		RGM.AxisRotate.Create(self, RGM.AxisDirections.Pitch),
		RGM.AxisRotate.Create(self, RGM.AxisDirections.Yaw),
		RGM.AxisRotate.Create(self, RGM.AxisDirections.Roll),

		RGM.AxisRotateFaced.Create(self),
		--RGM.AxisRotateAll.Create(self),

		RGM.AxisScale.Create(self, RGM.AxisDirections.Up),
		RGM.AxisScale.Create(self, RGM.AxisDirections.Forward),
		RGM.AxisScale.Create(self, RGM.AxisDirections.Right),

		RGM.AxisScaleAll.Create(self)

	};
	self.ActiveAxes = {};

	self.Grabbed = false;

end

function GIZMO:SetMode(mode)

	table.Empty(self.ActiveAxes);

	for _, axis in pairs(self.Axes) do
		if axis.Mode == mode then
			table.insert(self.ActiveAxes, axis);
		end
	end

	self.Mode = mode;

	if SERVER then
		net.Start("RGMGizmoSetMode");
		net.WriteInt(mode, 32);
		net.Send(self.Player);
	end

end

function GIZMO:SetModeClient()

	local player = LocalPlayer();
	local gizmo = player.RGMGizmo;
	local mode = net.ReadInt(32);

	gizmo:SetMode(mode);

end

function GIZMO:NextMode()
	local mode = self.Mode + 1;
	if mode > table.Count(RGM.GizmoModes) then
		mode = RGM.GizmoModes.Move;
	end
	self:SetMode(mode);
end

-- Return an axis if we hit one
function GIZMO:Trace(eyePos, eyeAngles)

	if not RGM.GetSelectedBone(self.Player) then
		return nil;
	end

	local lowestPriority = 999999;
	local lowestDistance = 999999;
	local closestAxis = nil;

	for _, axis in pairs(self.ActiveAxes) do
		local t = axis:Trace(eyePos, eyeAngles);
		if t then
			if axis.Priority < lowestPriority then
				lowestPriority = axis.Priority;
				closestAxis = axis;
			elseif t.Distance < lowestDistance then
				lowestDistance = t.Distance;
				closestAxis = axis;
			end
		end
	end

	return closestAxis;

end

function GIZMO:Draw()

	local trace = RGM.Trace(self.Player);

	for _, axis in pairs(self.ActiveAxes) do
		axis:Draw(trace.Axis == axis);
	end

end

RGM.Gizmo = GIZMO;

if SERVER then
	util.AddNetworkString("RGMGizmoCreate");
	util.AddNetworkString("RGMGizmoSetMode");
else
	net.Receive("RGMGizmoCreate", GIZMO.CreateClient);
	net.Receive("RGMGizmoSetMode", GIZMO.SetModeClient);
end

include("axes/axis.lua");

include("axes/move.lua");
include("axes/move_side.lua");
include("axes/move_faced.lua");

include("axes/rotate.lua");
include("axes/rotate_faced.lua");
include("axes/rotate_all.lua");

include("axes/scale.lua");
include("axes/scale_all.lua");