
include("shared.lua");

local function MakeLines()
	local RTable = {};
	local ang = Angle(0,0,11.25);
	local startpos = Vector(0, 0, 1);
	for i=1,32 do
		local pos1 = startpos*1;
		local pos2 = startpos*1;
		pos1:Rotate(ang * (i - 1));
		pos2:Rotate(ang * i);
		RTable[i] = { a = pos1, b = pos2 };
	end
	return RTable;
end
local discLines = MakeLines();

function ENT:Initialize()

	self.BaseClass.Initialize(self);

	self.m_Lines = discLines;

end