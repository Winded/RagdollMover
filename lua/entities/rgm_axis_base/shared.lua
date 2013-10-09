
ENT.Type = "anim";
ENT.Base = "rgm_base_entity";

function ENT:SharedInitialize()

	self.BaseClass.SharedInitialize(self);
	
end

function ENT:GetGizmo()
	return self:GetParent();
end

function ENT:GetManipulator()
	return self:GetGizmo():GetManipulator();
end

function ENT:GetPlayer()
	return self:GetManipulator():GetPlayer();
end

function ENT:GetTarget()
	return self:GetManipulator():GetTarget();
end

function ENT:GetType() --TODO purpose?
	return self:GetNWInt("Type", 1);
end

function ENT:GetScale()
	return self:GetNWFloat("Scale", 1.0);
end

function ENT:GetGrabOffset()

	local go = self:GetManipulator():GetGrabOffset();
	if not go then return nil; end

	return go;

end

---
-- Test player's eye trace against the axis, and returns rgm.Trace
---
function ENT:GetTrace()
	-- Abstract - inheriting entities should declare.
	return nil;
end

---
-- Returns if the axis is currently grabbed or not.
---
function ENT:IsGrabbed()
	local ga = self:GetManipulator():GetGrabAxis();
	return IsValid(ga) and ga == self;
end