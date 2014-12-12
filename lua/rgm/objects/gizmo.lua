---
-- Gizmo is the thingy that contains axes that are used to move/rotate/scale the target entity
-- Each player have their own gizmo
---

RGM.GizmoModes = {
	Move = 1,
	Rotate = 2,
	Scale = 3
};

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

}

local GIZMO = {};
GIZMO.__index = GIZMO;

function GIZMO.Create(player)

	local g = setmetatable({}, GIZMO);
	g.ID = math.random(1, 9999999);
	g.Player = player;
	g:Init();

	net.Start("RGMGizmoCreate");
	net.WriteTable(g);
	net.Send(player);

end

function GIZMO.CreateClient()

	local player = LocalPlayer();
	local g = setmetatable(net.ReadTable(), GIZMO);

	for _, axis in pairs(g.Axes) do
		setmetatable(axis, RGM.Axis);
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
		RGM.AxisRotateAll.Create(self),

		RGM.AxisScale.Create(self, RGM.AxisDirections.Up),
		RGM.AxisScale.Create(self, RGM.AxisDirections.Forward),
		RGM.AxisScale.Create(self, RGM.AxisDirections.Right),

		RGM.AxisScaleAll.Create(self)

	};
	self.ActiveAxes = {};

	self.Grabbed = false;
	self:SetMode(RGM.GizmoModes.Move);

end

function GIZMO:SetMode(mode)

	table.Empty(self.ActiveAxes);

	for _, axis in pairs(self.Axes) do
		if axis.Mode == mode then
			table.insert(self.ActiveAxes, axis);
		end
	end

	if SERVER then
		net.Start("RGMSetMode");
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

-- Return an axis if we hit one
function GIZMO:Trace(trace)

	-- TODO

end

function GIZMO:Draw()
	for _, axis in pairs(self.ActiveAxes) do
		axis:Draw();
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

include("axes/move.lua");
include("axes/move_side.lua");
include("axes/move_faced.lua");

include("axes/rotate.lua");
include("axes/rotate_faced.lua");
include("axes/rotate_all.lua");

include("axes/scale.lua");
include("axes/scale_all.lua");