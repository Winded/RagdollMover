
ENT.BaseClass = nil;

function ENT:Initialize()
	
end

function ENT:Think()
	
end

function ENT:Remove()
	rgm.RemoveEntity(self);
end

function ENT:Enable()
	self.m_Enabled = true;
end

function ENT:Disable()
	self.m_Enabled = false;
end

function ENT:GetPos()
	return Vector(0, 0, 0);
end
function ENT:SetPos(pos) end

function ENT:GetAngles()
	return Angle(0, 0, 0);
end
function ENT:SetAngles(ang) end