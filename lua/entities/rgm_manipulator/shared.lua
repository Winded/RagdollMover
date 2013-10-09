--[[--------------------

RGM Manipulator
The central authority of the entire movement and rendering process of gizmos.
The code using the manipulator (e.g. toolgun) communicates with this entity,
and this entity manages moving skeletons and rendering gizmos.

----------------------]]

ENT.Type = "anim"
ENT.Base = "base_entity"

--Gizmo mode constants.
ENT.GIZMO_MODE_MOVE = 1;
ENT.GIZMO_MODE_ROTATE = 2;
ENT.GIZMO_MODE_SCALE = 3;

-- Alignment constants.
ENT.ALIGNMENT_LOCAL = 1;
ENT.ALIGNMENT_WORLD = 2;

function ENT:InitializeShared()

	self.BaseClass.SharedInitialize(self);
	
	self:SetAllowedMessages({ "SetupGizmos" });
	
	self.m_Gizmos = {};
	
	self.m_GrabData = nil;
	
end

---
-- Returns if the manipulator is enabled or not.
-- When the manipulator is disabled, grabbing, updating and rendering
-- functions do nothing.
---
function ENT:IsEnabled()
	return self:GetNWBool("Enabled", false);
end

function ENT:GetGizmos()
	return self.m_Gizmos;
end

function ENT:GetPlayer()
	return self:GetNWEntity("Player", NULL);
end

---
-- Get the current target to be manipulated. (This should be rgm_skeleton_node)
---
function ENT:GetTarget()
	return self:GetNWEntity("Target", NULL);
end

---
-- Get the gizmo scale.
---
function ENT:GetScale()
	return self:GetNWFloat("Scale", 1);
end

---
-- Get the manipulator's alignment. This is the relative rotation of the gizmo.
---
function ENT:GetAlignment()
	return self:GetNWInt("Alignment", ENT.ALIGNMENT_LOCAL);
end

---
-- Returns if the manipulator is currently grabbed or not.
---
function ENT:IsGrabbed()
	return self:GetNWBool("Grabbed", false);
end

---
-- Get the current mode of the manipulator.
-- Should be 1, 2 or 3, meaning move, rotate or scale.
---
function ENT:GetMode()
	return self:GetNWInt("Mode", self.GIZMO_MODE_MOVE);
end

function ENT:GetMoveGizmo()
	return self.m_MoveGizmo;
end
function ENT:GetRotateGizmo()
	return self.m_RotateGizmo;
end
function ENT:GetScaleGizmo()
	return self.m_ScaleGizmo;
end

---
-- Get the gizmo entity of the current mode.
---
function ENT:GetActiveGizmo()
	local mode = self:GetMode();
	if mode == self.GIZMO_MODE_MOVE then
		return self:GetMoveGizmo();
	elseif mode == self.GIZMO_MODE_ROTATE then
		return self:GetRotateGizmo();
	elseif mode == self.GIZMO_MODE_SCALE then
		return self:GetScaleGizmo();
	else
		return self:GetMoveGizmo();
	end
end

---
-- Test player's eye trace against the active gizmo, and returns rgm.Trace
---
function ENT:GetTrace()

	local gizmo = self:GetActiveGizmo();

	local resp = gizmo:GetTrace();
	
	return resp;
	
end

---
-- Returns the currently grabbed axis, if one is grabbed.
---
function ENT:GetGrabAxis()
	return self:GetNWEntity("GrabData_Axis", NULL);
end

---
-- Returns the grab point offset from the grabbed axis, if one is grabbed.
---
function ENT:GetGrabOffset()
	return self:GetNWVector("GrabData_AxisOffset", NULL);
end

function ENT:ThinkShared()
	
end

function ENT:UpdateCollision()
	
end