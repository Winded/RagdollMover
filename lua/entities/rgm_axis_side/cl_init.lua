
include("shared.lua")

local VECTOR_RED = Vector(255, 0, 0)

function ENT:GetLinePositions(width)
	local RTable = {
		{Vector(0, 0.25 - 0.05 * width, 0), Vector(0, 0.25 - 0.05 * width, 0.25 - 0.05 * width), Vector(0, 0.25 + 0.05 * width, 0.25 + 0.05 * width), Vector(0, 0.25 + 0.05 * width, 0)},
		{Vector(0, 0, 0.25 - 0.05 * width), Vector(0, 0.25 - 0.05 * width, 0.25 - 0.05 * width), Vector(0, 0.25 + 0.05 * width, 0.25 + 0.05 * width), Vector(0, 0, 0.25 + 0.05 * width)}
	}
	return RTable
end

local COLOR_YELLOW = Color(255, 255, 0, 255)

function ENT:DrawLines(yellow, scale, width)
	local toscreen = {}
	local linetable = self:GetLinePositions(width)
	local color = self:GetColor()
	color = Color(color.r, color.g, color.b, color.a)
	local color2 = self:GetNWVector("color2", VECTOR_RED)
	color2 = Color(color2.x, color2.y, color2.z, 255)
	for i, v in ipairs(linetable) do
		local points = self:PointsToWorld(v, scale)
		local col = color
		if yellow then
			col = COLOR_YELLOW
		elseif i == 2 then
			col = color2
		end
		table.insert(toscreen, {points, col})
	end
	for i, v in ipairs(toscreen) do
		render.DrawQuad(v[1][1], v[1][2], v[1][3], v[1][4], v[2])
	end
end
