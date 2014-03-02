
include("shared.lua");

local base = getmetatable(ENT);

function ENT:Initialize()

	base.Initialize(self);

	self.m_Lines =
	{
		{ a = Vector(0, 0, 0), b = Vector(1, 0, 0) },
		{ a = Vector(1, 0, 0), b = Vector(0.9, 0.1, 0) },
		{ a = Vector(1, 0, 0), b = Vector(0.9, -0.1, 0) },
	};

end