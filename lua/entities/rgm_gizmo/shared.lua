
ENT.Base = "rgm_base_entity";
ENT.Type = "anim";

function ENT:SharedInitialize()

	self.BaseClass.SharedInitialize(self);
	
	self.m_Axes = {};
	
end

function ENT:GetManipulator()
	return self:GetParent();
end

function ENT:GetPlayer()
	return self:GetManipulator():GetPlayer();
end

function ENT:GetTarget()
	return self:GetManipulator():GetTarget();
end

function ENT:GetScale()
	return self:GetManipulator():GetScale();
end

function ENT:GetAxes()
	return self.m_Axes;
end

---
-- Get the axis of this gizmo that is grabbed.
-- If no axis is grabbed, or not from this gizmo, returns NULL.
---
function ENT:GetGrabAxis()
	return self:GetManipulator():GetGrabAxis();
end

---
-- Test player's eye trace against the gizmo's axes, and returns rgm.Trace
---
function ENT:GetTrace()
	
	local traces = {};
	
	for i, axis in ipairs(self:GetAxes()) do
		local tr = axis:GetTrace();
		if IsValid(tr) then table.Insert(traces, tr); end
	end
	
	local resp;
	local lowestLen = 2147483647; -- int max
	for i, tr in ipairs(traces) do
		if tr.position:Length() < lowestLen then
			resp = tr;
			lowestLen = tr.position:Length();
		end
	end
	
	if not resp then return nil; end
	
	return resp;
	
end