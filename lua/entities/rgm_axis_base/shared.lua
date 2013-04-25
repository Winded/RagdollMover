
ENT.Type = "anim";
ENT.Base = "rgm_base_entity";

function ENT:InitializeShared()

	self.BaseClass.Initialize(self);
	
end

function ENT:GetGizmo()
	return self:GetParent();
end

function ENT:GetManipulator()
	return self:GetGizmo():GetManipulator();
end

function ENT:GetType() --TODO purpose?
	return self:GetNWInt("Type", 1);
end

function ENT:GetScale()
	return self:GetManipulator():GetScale();
end

---
-- Test player's eye trace against the axis, and returns rgm.Trace
---
function ENT:GetTrace()
	
	-- Abstract - inheriting entities should declare.
	
end

---
-- Calculate target's position and angle during grab, when this axis is selected.
---
function ENT:CalculateTarget(is3D, startPos, curPos)
	--TODO
end

---
-- Returns if the axis is currently grabbed or not.
---
function ENT:IsGrabbed()
	local ga = self:GetGizmo():GetGrabbedAxis();
	return IsValid(ga) and ga == self;
end