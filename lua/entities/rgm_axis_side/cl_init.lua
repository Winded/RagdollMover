
include("shared.lua")

function ENT:GetLinePositions(width)
	local RTable = {}
	RTable[1] = {Vector(0,0.25 - 0.05*width,0),Vector(0,0.25 - 0.05*width,0.25 - 0.05*width),Vector(0,0.25 + 0.05*width,0.25 + 0.05*width),Vector(0,0.25 + 0.05*width,0)}
	RTable[2] = {Vector(0,0,0.25 - 0.05*width),Vector(0,0.25 - 0.05*width,0.25 - 0.05*width),Vector(0,0.25 + 0.05*width,0.25 + 0.05*width),Vector(0,0,0.25 + 0.05*width)}
	return RTable
end

function ENT:DrawLines(yellow,scale,width)
	local ToScreen = {}
	local linetable = self:GetLinePositions(width)
	local color = self:GetColor()
	color = Color(color.r,color.g,color.b,color.a)
	local color2 = self:GetNWVector("color2",Vector(255,0,0))
	color2 = Color(color2.x,color2.y,color2.z,255)
	for i,v in ipairs(linetable) do
		local points = self:PointsToWorld(v, scale)
		local col = color
		if yellow then
			col = Color(255,255,0,255)
		elseif i == 2 then
			col = color2
		end
		table.insert(ToScreen,{points,col})
	end
	for i,v in ipairs(ToScreen) do
		render.DrawQuad(v[1][1],v[1][2],v[1][3],v[1][4],v[2])
	end
end
