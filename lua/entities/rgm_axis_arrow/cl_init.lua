
include("shared.lua")

local VECTOR_FRONT = Vector(1, 0, 0)

function ENT:GetLinePositions(width)
	local RTable = {
		{Vector(0.1, -0.075 * width, 0), Vector(0.75, -0.075 * width, 0), Vector(0.75, 0.075 * width, 0), Vector(0.1, 0.075 * width, 0)},
		{Vector(0.75, -0.0625 - 0.0625 * width, 0), VECTOR_FRONT, VECTOR_FRONT, Vector(0.75, 0.0625 + 0.0625 * width, 0)}
	}
	return RTable
end
