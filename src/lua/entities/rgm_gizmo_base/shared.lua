
ENT.Base = "rgm_base_entity";
ENT.Type = "anim";

function ENT:MakeAxis(name, color, angle)

	local axis = ents.Create(name);
	axis:SetParent(self);
	axis:Spawn();
	axis:SetColor(color);
	axis:SetLocalPos(Vector(0,0,0));
	axis:SetLocalAngles(angle);
	axis:SetScale(self:GetScale());
	
	return axis;
		
end

function ENT:SharedInitialize()

	self.BaseClass.Initialize(self);
	
	self.m_AllowedFuncs = {"SetAxes"};
	
	self.m_Axes = {};
	
end

function ENT:GetAxes()
	return self.m_Axes;
end

function ENT:SetAxes(axes)
	self.m_Axes = axes;
	
	if SERVER then self:SendMessage("SetAxes", axes); end
end

---
-- Get the axis of this gizmo that is grabbed.
-- If no axis is grabbed, or not from this gizmo, returns NULL.
---
function ENT:GetGrabbedAxis()
	
	local gdata = self:GetManipulator():GetGrabData();
	if not gdata then return NULL; end --No axis is currently grabbed
	
	local gg = gdata.axis:GetGizmo();
	if gg ~= self then return NULL; end --An axis is grabbed, but not from this gizmo
	
	return gdata.axis;
	
end

---
-- Test player's eye trace against the gizmo's axes, and returns rgm.Trace
---
function ENT:GetTrace()
	
	local traces = {};
	
	for i, axis in ipairs(self:GetAxes()) do
		local tr = axis:GetTrace();
		if tr.success then table.Insert(traces, tr); end
	end
	
	local resp;
	local lowestLen = 2147483647;
	for i, tr in ipairs(traces) do
		if tr.position:Length() < lowestLen then
			resp = tr;
			lowestLen = tr.position:Length();
		end
	end
	
	if not resp then return rgm.Trace(false); end
	
	return resp;
	
end