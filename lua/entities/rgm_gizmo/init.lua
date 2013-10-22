
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
include("shared.lua");

function ENT:Initialize()
	
	self.BaseClass.Initialize(self);
	
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
-- Sends SyncAxes function to clients, i.e. syncs the axes table with client or clients
---
function ENT:SyncAxes()

	net.Start("rgm_gizmo_sync");

	net.WriteEntity(self);
	net.WriteTable(self.m_Axes);

	net.Send(self:GetPlayer());

end

---
-- Updates the skeleton node position
---
function ENT:Update()
	
	for _, axis in pairs(self:GetAxes()) do
		axis:Update();
	end

end