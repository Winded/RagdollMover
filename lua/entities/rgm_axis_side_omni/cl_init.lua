
include("shared.lua")

function ENT:GetLinePositions(width)
	local RTable = {}
	RTable[1] = {Vector(0,-0.08*width,-0.08*width),Vector(0,-0.08*width,0.08*width),Vector(0,0.08*width,0.08*width),Vector(0,0.08*width,-0.08*width)}
	return RTable
end
