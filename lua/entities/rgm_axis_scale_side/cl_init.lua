
include("shared.lua")

function ENT:GetLinePositions()
	local RTable = {}
	RTable[1] = {Vector(0,0.25,0),Vector(0,0.25,0.25)}
	RTable[2] = {Vector(0,0,0.25),Vector(0,0.25,0.25)}
	return RTable
end

function ENT:DrawLines(yellow,scale)
	local ToScreen = {}
	local linetable = self:GetLinePositions()
	local color = self:GetColor()
	color = {color.r,color.g,color.b,color.a}
	local color2 = self:GetNWVector("color2",Vector(255,0,0))
	color2 = {color2.x,color2.y,color2.z,255}
	for i,v in ipairs(linetable) do
		local pos1 = self:LocalToWorld(v[1]*scale)
		local pos2 = self:LocalToWorld(v[2]*scale)
		local col = color
		if yellow then
			col = {255,255,0,255}
		elseif i == 2 then
			col = color2
		end
		table.insert(ToScreen,{pos1:ToScreen(),pos2:ToScreen(),col})
	end
	for i,v in ipairs(ToScreen) do
		surface.SetDrawColor(unpack(v[3]))
		surface.DrawLine(v[1].x,v[1].y,v[2].x,v[2].y)
	end
end
