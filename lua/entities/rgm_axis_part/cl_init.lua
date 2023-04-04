
include("shared.lua")

local VECTOR_RED = Vector(255,0,0)

--To be overwritten
function ENT:GetLinePositions()
end

function ENT:PointsToWorld(vectors, scale)
	local translated = {}
	for k, vec in ipairs(vectors) do
		table.insert(translated,self:LocalToWorld(vec*scale))
	end
	return translated
end

local COLOR_YELLOW = Color(255,255,0,255)

function ENT:DrawLines(yellow,scale,width)
	local ToScreen = {}
	local linetable = self:GetLinePositions(width)
	local color = self:GetColor()
	color = Color(color.r,color.g,color.b,color.a)
	local color2 = self:GetNWVector("color2",VECTOR_RED)
	color2 = Color(color2.x,color2.y,color2.z,255)

	for i,v in ipairs(linetable) do
		local points = self:PointsToWorld(v, scale)
		local col = color
		if yellow then
			col = COLOR_YELLOW
		end
		table.insert(ToScreen,{points,col})
	end

	for i,v in ipairs(ToScreen) do
		render.DrawQuad(v[1][1],v[1][2],v[1][3],v[1][4],v[2])
	end
end
