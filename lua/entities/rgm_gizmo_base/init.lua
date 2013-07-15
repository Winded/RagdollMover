
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
include("shared.lua");

function ENT:Initialize()
	
	self:SharedInitialize();
	
end

function ENT:AddAxis(name, color, angle)

	local axis = ents.Create(name);
	axis:SetParent(self);
	axis:Spawn();
	axis:SetColor(color);
	axis:SetLocalPos(Vector(0, 0, 0));
	axis:SetLocalAngles(angle);
	axis:SetScale(self:GetScale());

	self.m_Axes:insert(axis);
	
	return axis;
		
end

---
-- Sends SetAxes function to clients, i.e. syncs the axes table with client or clients
---
function ENT:SyncAxes()

	self:SendMessage("SetAxes", self.m_Axes);

end

---
-- Updates the skeleton node position
---
function ENT:Update()
	
	local axis = self:GetGrabAxis();
	if not IsValid(axis) then return; end

	axis:UpdatePosition();

end