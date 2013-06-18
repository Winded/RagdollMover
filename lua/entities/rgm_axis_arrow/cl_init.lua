
include("shared.lua");

function ENT:Initialize(  )

	self:SharedInitialize();

	self.m_Lines =
	{
		{Vector(0, 0, 0), Vector(1, 0, 0)},
		{Vector(1, 0, 0), Vector(0.9, 0.1, 0)},
		{Vector(1, 0, 0), Vector(0.9, -0.1, 0)},
	};

end