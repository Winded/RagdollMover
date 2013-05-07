
ENT.Type = "anim"
ENT.Base = "base_entity"

--TODO Separate gizmos to entities

--Gizmo mode constants.
ENT.GIZMO_MODE_MOVE = 1;
ENT.GIZMO_MODE_ROTATE = 2;
ENT.GIZMO_MODE_SCALE = 3;

function ENT:InitializeShared()

	self.BaseClass.Initialize(self);
	
	self.m_AllowedFuncs = {"SetupGizmos"};
	
	self.m_Gizmos = {};
	
	self.m_GrabData = nil;
	
end

function ENT:IsEnabled()
	return self:GetNWBool("Enabled", false);
end

function ENT:GetGizmos()
	return self.m_Gizmos;
end

function ENT:GetPlayer()
	return self:GetNWEntity("Player", NULL);
end

function ENT:GetTarget()
	return self:GetNWEntity("Target", NULL);
end

function ENT:GetScale()
	return self:GetNWFloat("Scale", 1);
end

---
-- Get the current mode of the manipulator.
-- Should be 1, 2 or 3, meaning move, rotate or scale.
---
function ENT:GetMode()
	return self:GetNWInt("Mode", self.GIZMO_MODE_MOVE);
end

function ENT:GetMoveGizmo()
	return self:GetNWEntity("GizmoMove", NULL);
end
function ENT:GetRotateGizmo()
	return self:GetNWEntity("GizmoRotate", NULL);
end
function ENT:GetScaleGizmo()
	return self:GetNWEntity("GizmoScale", NULL);
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
-- Returns the manipulator's rgm grab data, if an axis is grabbed.
-- If no axis is grabbed, returns nil
---
function ENT:GetGrabData()
	return self.m_GrabData;
end

function ENT:ThinkShared()
	
end

function ENT:UpdateCollision()
	
end