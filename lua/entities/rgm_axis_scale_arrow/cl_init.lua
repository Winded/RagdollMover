
include("shared.lua")

function ENT:GetLinePositions(width)
	local RTable = {}
	RTable[1] = {Vector(0.075*width,-0.075*width,0),Vector(0.97,-0.075*width,0),Vector(0.97,0.075*width,0),Vector(0.075*width,0.075*width,0)}
	RTable[2] = {Vector(0.97,-0.0625 - 0.0625*width,0), Vector(1,-0.0625 - 0.0625*width,0),Vector(1,0.0625 + 0.0625*width,0),Vector(0.97,0.0625 + 0.0625*width,0)}
	return RTable
end
