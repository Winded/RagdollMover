
include("shared.lua")

function ENT:GetLinePositions()
	local RTable = {}
	RTable[1] = {Vector(0,0,0),Vector(1,0,0)}
	RTable[2] = {Vector(1,0,0),Vector(0.9,0.1,0)}
	RTable[3] = {Vector(1,0,0),Vector(0.9,-0.1,0)}
	return RTable
end