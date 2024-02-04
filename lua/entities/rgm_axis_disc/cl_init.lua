
include("shared.lua")

local VECTOR_RED = Vector(255, 0, 0)
local ANG = Angle(0, 0, 11.25)

function ENT:GetLinePositions(width)
	local RTable = {}
	local ang = ANG
	local startposmin = Vector(0, 0,1 - 0.1 * width)
	local startposmax = Vector(0, 0,1 + 0.1 * width)
	for i = 1, 32 do
		local pos1 = startposmin*1
		local pos2 = startposmin*1
		local pos3 = startposmax*1
		local pos4 = startposmax*1
		pos1:Rotate(ang * (i - 1))
		pos2:Rotate(ang * (i))
		pos3:Rotate(ang * (i))
		pos4:Rotate(ang * (i - 1))
		RTable[i] = {pos1, pos2, pos3, pos4}
	end
	return RTable
end

local COLOR_YELLOW = Color(255, 255, 0, 255)
local pl, parent

function ENT:DrawLines(yellow, scale, width)
	if not pl then pl = LocalPlayer() end
	if not parent then parent = self:GetParent() end
	local toscreen = {}
	local linetable = self:GetLinePositions(width)
	local eyepos = pl:EyePos()
	local largedisc = parent.DiscLarge
	if not IsValid(largedisc) then return end

	local borderpos = largedisc:GetPos()
	local color = self:GetColor()
	color = Color(color.r, color.g, color.b, color.a)
	local moving = pl.rgm.Moving or false

	for i,v in ipairs(linetable) do
		local points = self:PointsToWorld(v, scale)
		local col = color
		if yellow then
			col = COLOR_YELLOW
		end
		if parent.fulldisc or (moving or
		(points[1]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos) and points[2]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos) and 
		points[3]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos) and points[4]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos))) then
			table.insert(toscreen, {points, col})
		end
	end
	for i,v in ipairs(toscreen) do
		render.DrawQuad(v[1][1], v[1][2], v[1][3], v[1][4], v[2])
	end
end
