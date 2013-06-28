
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

function ENT:Initialize()

	self:InitializeShared();
	
	self.m_MoveGizmo = self:MakeGizmo("rgm_gizmo_move");
	self.m_RotateGizmo = self:MakeGizmo("rgm_gizmo_rotate");
	self.m_ScaleGizmo = self:MakeGizmo("rgm_gizmo_scale");
	
	self.m_Gizmos = 
	{
		self.m_MoveGizmo,
		self.m_RotateGizmo,
		self.m_ScaleGizmo,
	};
	
	self:SendMessage("SetupGizmos", self.MoveGizmo, self.RotateGizmo, self.ScaleGizmo);
	
end

function ENT:MakeGizmo(name)
	
	local gizmo = ents.Create(name);
	gizmo:SetParent(self);
	gizmo:Spawn();
	gizmo:SetLocalPos(Vector(0, 0, 0));
	gizmo:SetLocalAngles(Angle(0, 0, 0));
	
end

---
-- Enable the manipulator. (See IsEnabled)
---
function ENT:Enable()
	self:SetNWBool("Enabled", true);
end

---
-- Disable the manipulator. (See IsEnabled)
---
function ENT:Disable()
	self:SetNWBool("Enabled", false);
end

function ENT:SetPlayer(player)
	self:SetNWEntity("Player", player);
end

---
-- Set the target skeleton node of the manipulator
---
function ENT:SetTarget(target)

	if target:GetClassName() ~= "rgm_skeleton_node" then
		error("rgm_manipulator SetTarget - target not of type rgm_skeleton_node");
	end

	self:SetNWEntity("Target", target);
	return true;

end
---
-- Clear the target of the manipulator. This will release the node if it is grabbed.
---
function ENT:ClearTarget()
	
	if self:IsGrabbed() then
		self:Release();
	end

	self:SetNWEntity("Target", NULL);

end

function ENT:SetMode(mode)
	self:SetNWInt("Mode", mode);
end

---
-- Set the manipulator's alignment. This is the relative rotation of the gizmo.
-- Should be 1 or 2, meaning world or local.
---
function ENT:SetAlignment(align)
	self:SetNWInt("Alignment", align);
end

---
-- Attempt to grab an axis from the player's eye trace.
-- If no axis is traced, returns false,
-- If an axis is traced, creates grab data for this axis and returns true.
---
function ENT:Grab()
	
	if not self:IsEnabled() then return false; end

	local trace = self:GetTrace();
	if not trace.success then return false; end
	
	local gdata = rgm.GrabData(trace.axis, trace.axisOffset);

	self:SetNWEntity("GrabData_Axis", gdata.axis);
	self:SetNWVector("GrabData_AxisOffset", gdata.axisOffset);
	self:SetNWBool("Grabbed", true);

	-- Call callbacks
	self:GetTarget():GetSkeleton():OnGrab();
	self:GetTarget():OnGrab();
	
	return true;
	
end

---
-- If an axis is grabbed, it is released. This removes rgm grab data.
---
function ENT:Release()

	if not self:IsEnabled() then return false; end

	self:SetNWEntity("GrabData_Axis", NULL);
	self:SetNWVector("GrabData_AxisOffset", Vector());
	self:SetNWBool("Grabbed", false);

	-- Call callbacks
	self:GetTarget():GetSkeleton():OnRelease();
	self:GetTarget():OnRelease();

	return true;

end

---
-- Keeps the manipulator positioned on the target skeleton node.
-- If grabbed, updates the skeleton position.
---
function ENT:Update()

	if not self:IsEnabled() then return; end

	local t = self:GetTarget();
	if not IsValid(t) then return; end

	self:SetPos(t:GetPos());
	if self:GetAlignment() == self.ALIGNMENT_LOCAL then
		self:SetAngles(t:GetAngles());
	else
		self:SetAngles(Angle(0, 0, 0));
	end

	if not self:IsGrabbed() then return; end

	local gizmo = self:GetActiveGizmo();
	if not IsValid(gizmo) then return; end --Shouldn't happen

	gizmo:Update();

end