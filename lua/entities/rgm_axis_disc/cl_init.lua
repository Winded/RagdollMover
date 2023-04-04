
include("shared.lua")

local VECTOR_RED = Vector(255,0,0)
local ANG = Angle(0,0,11.25)

function ENT:GetLinePositions(width)
	local RTable = {}
	local ang = ANG
	local startposmin = Vector(0,0,1 - 0.1*width)
	local startposmax = Vector(0,0,1 + 0.1*width)
	for i=1,32 do
		local pos1 = startposmin*1
		local pos2 = startposmin*1
		local pos3 = startposmax*1
		local pos4 = startposmax*1
		pos1:Rotate(ang*(i-1))
		pos2:Rotate(ang*(i))
		pos3:Rotate(ang*(i))
		pos4:Rotate(ang*(i-1))
		RTable[i] = {pos1,pos2,pos3,pos4}
	end
	return RTable
end

local COLOR_YELLOW = Color(255,255,0,255)

function ENT:DrawLines(yellow,scale,width)
	local ToScreen = {}
	local linetable = self:GetLinePositions(width)
	local eyepos = LocalPlayer():EyePos()
	local largedisc = self:GetParent().DiscLarge
	if not IsValid(largedisc) then return end

	local borderpos = largedisc:GetPos()
	local color = self:GetColor()
	color = Color(color.r,color.g,color.b,color.a)
	local color2 = self:GetNWVector("color2",VECTOR_RED)
	color2 = Color(color2.x,color2.y,color2.z,255)
	local moving = LocalPlayer().rgm.Moving or false

	for i,v in ipairs(linetable) do
		local points = self:PointsToWorld(v, scale)
		local col = color
		if yellow then
			col = COLOR_YELLOW
		end
		if GetConVar("ragdollmover_fulldisc"):GetBool() or (moving or
		(points[1]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos) and points[2]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos) and 
		points[3]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos) and points[4]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos))) then
			table.insert(ToScreen,{points,col})
		end
	end
	for i,v in ipairs(ToScreen) do
		render.DrawQuad(v[1][1],v[1][2],v[1][3],v[1][4],v[2])
	end
end
