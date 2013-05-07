
include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

local TYPE_ARROW = 1;
local TYPE_ARROWSIDE = 2;
local TYPE_DISC = 3;

local RED = Color(255, 0, 0, 255);
local GREEN = Color(0, 255, 0, 255);
local BLUE = Color(0, 0, 255, 255);
local GREY = Color(175,175,175,255);

local function MakeGizmo(self, name)
	
	local gizmo = ents.Create(name);
	gizmo:SetParent(self);
	gizmo:Spawn();
	gizmo:SetLocalPos(Vector(0, 0, 0));
	gizmo:SetLocalAngles(Angle(0, 0, 0));
	
end

local function MakeAxis(self, name, type, color, angle)

	local axis = ents.Create(name);
	axis:SetParent(self);
	axis:Spawn();
	axis:SetNWInt("Type", type);
	axis:SetColor(color);
	axis:SetLocalPos(Vector(0,0,0));
	axis:SetLocalAngles(angle);
	axis:SetScale(self:GetScale());
	
	return axis;
		
end

local function MakeSide(self, color1, color2, angle)
	local axis = MakeAxis(self, "rgm_axis_side", TYPE_ARROWSIDE, GREY, angle);
	axis:SetColor1(color1);
	axis:SetColor2(color2);
	
	return axis;
end

function ENT:Initialize()

	self:InitializeShared();
	
	self.MoveGizmo = MakeGizmo("rgm_gizmo_move");
	self.RotateGizmo = MakeGizmo("rgm_gizmo_rotate");
	self.ScaleGizmo = MakeGizmo("rgm_gizmo_scale");
	
	self.m_Gizmos = 
	{
		self.MoveGizmo,
		self.RotateGizmo,
		self.ScaleGizmo,
	};
	
	self:SendMessage("SetupGizmos", self.MoveGizmo, self.RotateGizmo, self.ScaleGizmo);
	
end

function ENT:Enable()
	self:SetNWBool("Enabled", true);
end

function ENT:Disable()
	self:SetNWBool("Enabled", false);
end

function ENT:SetPlayer(player)
	self:SetNWEntity("Player", player);
end

function ENT:SetTarget(target)
	self:SetNWEntity("Target", target);
end

function ENT:SetMode(mode)
	self:SetNWInt("Mode", mode);
end

---
-- Attempt to grab an axis from the player's eye trace.
-- If no axis is traced, returns false,
-- If an axis is traced, creates grab data for this axis and returns true.
---
function ENT:Grab()
	
	local trace = self:GetTrace();
	if not trace.success then return false; end
	
	local gdata = rgm.GrabData(trace.axis, trace.axisOffset);
	self.m_GrabData = gdata;
	
	return true;
	
end

---
-- If an axis is grabbed, it is released. This removes rgm grab data.
---
function ENT:Release()
	self.m_GrabData = nil;
end

---
-- If grabbed, updates the skeleton position.
-- If not grabbed, doesn't really do anything
---
function ENT:Update()

	if not self:IsGrabbed() then return; end

	local gizmo = self:GetActiveGizmo();
	if not IsValid(gizmo) then return; end --Shouldn't happen

	gizmo:Update();

end

---
-- "Quiet" functionality to keep the manipulator on the target skeleton node.
---
function ENT:Think()

	-- TODO

end