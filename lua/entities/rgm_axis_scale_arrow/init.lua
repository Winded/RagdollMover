
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos, offang, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, _, startgrab, _, _, nphysscale)
	local intersect = self:GetGrabPos(eyepos, eyeang, ppos)
	local localized = self:WorldToLocal(intersect)
	local pos, ang

	pos = ent:GetManipulateBoneScale(bone)
	pos = pos*1 -- multiply by 1 to make a copy of the vector, in case if we scale advanced bonemerged item - those currently use modified ManipulateBoneX functions which seem to cause a bug if I keep altering vector given from GetManipulateBoneX stuff
	localized = Vector(localized.x - startgrab.x, 0, 0)
	local posadd = nphysscale[self.axistype] + localized.x
	ang = ent:GetManipulateBoneAngles(bone)
	pos[self.axistype] = posadd
	return pos, ang
end
