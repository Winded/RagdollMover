
include("shared.lua")

function ENT:DrawLines(yellow,scale,width)
	-- self.BaseClass.DrawLines(self,yellow,scale*1.25)
	local ToScreen = {}
	local linetable = self:GetLinePositions(width)
	local color = self:GetColor()
	color = Color(color.r,color.g,color.b,color.a)
	local color2 = self:GetNWVector("color2",Vector(255,0,0))
	color2 = Color(color2.x,color2.y,color2.z,255)
	local moving = LocalPlayer():GetNWBool("ragdollmover_moving",false)
	for i,v in ipairs(linetable) do
		local col = color
		if yellow then
			col = Color(255,255,0,255)
		end
		local points = self:PointsToWorld(v, scale*1.25)
		table.insert(ToScreen,{points,col})
	end
	for i,v in ipairs(ToScreen) do
		render.DrawQuad(v[1][1],v[1][2],v[1][3],v[1][4],v[2])
	end
end
