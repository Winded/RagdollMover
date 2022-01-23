
include("shared.lua")

function ENT:GetLinePositions()
	local RTable = {}
	local ang = Angle(0,0,11.25)
	local startpos = Vector(0,0,1)
	for i=1,32 do
		local pos1 = startpos*1
		local pos2 = startpos*1
		pos1:Rotate(ang*(i-1))
		pos2:Rotate(ang*(i))
		RTable[i] = {pos1,pos2}
	end
	return RTable
end

function ENT:DrawLines(yellow,scale)
	local ToScreen = {}
	local linetable = self:GetLinePositions()
	local eyepos = LocalPlayer():EyePos()
	local largedisc = self:GetParent().DiscLarge
	if !IsValid(largedisc) then return end
	local borderpos = largedisc:GetPos()
	local color = self:GetColor()
	color = {color.r,color.g,color.b,color.a}
	local color2 = self:GetNWVector("color2",Vector(255,0,0))
	color2 = {color2.x,color2.y,color2.z,255}
	local moving = LocalPlayer().rgm.Moving or false
	for i,v in ipairs(linetable) do
		local pos1 = self:LocalToWorld(v[1]*scale)
		local pos2 = self:LocalToWorld(v[2]*scale)
		local col = color
		if yellow then
			col = {255,255,0,255}
		end
		if GetConVar("ragdollmover_fulldisc"):GetBool() or (moving or
		(pos1:Distance(eyepos) <= borderpos:Distance(eyepos) and pos2:Distance(eyepos) <= borderpos:Distance(eyepos))) then
			table.insert(ToScreen,{pos1:ToScreen(),pos2:ToScreen(),col})
		end
	end
	for i,v in ipairs(ToScreen) do
		surface.SetDrawColor(unpack(v[3]))
		surface.DrawLine(v[1].x,v[1].y,v[2].x,v[2].y)
	end
end
