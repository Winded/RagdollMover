
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