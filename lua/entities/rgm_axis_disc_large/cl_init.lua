
include("shared.lua")

local VECTOR_RED = Vector(255, 0, 0)

local COLOR_YELLOW = Color(255, 255, 0, 255)

function ENT:DrawLines(yellow, scale, width)
	-- self.BaseClass.DrawLines(self, yellow, scale * 1.25)
	local toscreen = {}
	local linetable = self:GetLinePositions(width)
	local color = self:GetColor()
	color = Color(color.r, color.g, color.b, color.a)
	local moving = LocalPlayer():GetNWBool("ragdollmover_moving", false)
	for i, v in ipairs(linetable) do
		local col = color
		if yellow then
			col = COLOR_YELLOW
		end
		local points = self:PointsToWorld(v, scale * 1.25)
		table.insert(toscreen, {points, col})
	end
	for i, v in ipairs(toscreen) do
		render.DrawQuad(v[1][1], v[1][2], v[1][3], v[1][4], v[2])
	end
end
