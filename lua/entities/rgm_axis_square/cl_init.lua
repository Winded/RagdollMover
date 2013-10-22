include("shared.lua");

function ENT:Initialize()

	self.BaseClass.Initialize(self);

	self.m_Lines = {
		{ a = Vector(0, -1, 1), b = Vector(0, 1, 1)  },
		{ a = Vector(0, 1, 1), b = Vector(0, 1, -1)  },
		{ a = Vector(0, 1, -1), b = Vector(0, -1, -1)  },
		{ a = Vector(0, -1, -1), b = Vector(0, -1, 1)  },
	};

end