
ENT.Type = "anim";
ENT.Base = "rgm_base_entity";

function ENT:SharedInitialize()

	self.BaseClass.Initialize(self);
	
end

function ENT:GetGizmo()
	return self:GetParent();
end

function ENT:GetManipulator()
	return self:GetGizmo():GetManipulator();
end

function ENT:GetPlayer()
	return self:GetGizmo():GetPlayer();
end

function ENT:GetTarget()
	return self:GetGizmo():GetTarget();
end

function ENT:GetType() --TODO purpose?
	return self:GetNWInt("Type", 1);
end

function ENT:GetScale()
	return self:GetGizmo():GetScale();
end

function ENT:GetGrabOffset()

	local go = self:GetGizmo():GetManipulator():GetGrabOffset();
	if not go then return nil; end

	return go;

end

---
-- Test player's eye trace against the axis, and returns rgm.Trace
---
function ENT:GetTrace()
	
	-- Abstract - inheriting entities should declare.
	
end

---
-- Returns if the axis is currently grabbed or not.
---
function ENT:IsGrabbed()
	local ga = self:GetGizmo():GetGrabAxis();
	return IsValid(ga) and ga == self;
end