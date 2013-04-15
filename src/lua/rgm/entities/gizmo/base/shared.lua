
ENT.BaseClass = "entity";

function ENT:Initialize()
	self.m_Axes = {};
end

function ENT:GetAxes()
	return self.m_Axes;
end