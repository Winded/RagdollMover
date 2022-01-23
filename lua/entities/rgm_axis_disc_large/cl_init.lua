
include("shared.lua")

function ENT:DrawLines(yellow,scale)
	-- self.BaseClass.DrawLines(self,yellow,scale*1.25)
	local ToScreen = {}
	local linetable = self:GetLinePositions()
	local color = self:GetColor()
	color = {color.r,color.g,color.b,color.a}
	local color2 = self:GetNWVector("color2",Vector(255,0,0))
	color2 = {color2.x,color2.y,color2.z,255}
	local moving = LocalPlayer():GetNWBool("ragdollmover_moving",false)
	for i,v in ipairs(linetable) do
		local col = color
		if yellow then
			col = {255,255,0,255}
		end
		local pos1 = self:LocalToWorld(v[1]*(scale*1.25))
		local pos2 = self:LocalToWorld(v[2]*(scale*1.25))
		table.insert(ToScreen,{pos1:ToScreen(),pos2:ToScreen(),col})
		if !GetConVar("ragdollmover_fulldisc"):GetBool() and !moving then
			local col2 = color2
			local Pos1 = self:LocalToWorld(v[1]*scale)
			local Pos2 = self:LocalToWorld(v[2]*scale)
			table.insert(ToScreen,{Pos1:ToScreen(),Pos2:ToScreen(),col2})
		end
	end
	for i,v in ipairs(ToScreen) do
		surface.SetDrawColor(unpack(v[3]))
		surface.DrawLine(v[1].x,v[1].y,v[2].x,v[2].y)
	end
end
