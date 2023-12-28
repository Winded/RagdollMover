
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

function ENT:ProcessMovement(offpos, offang, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, _, startgrab, _, _, nphysscale)
	local intersect = self:GetGrabPos(eyepos, eyeang, ppos)
	local localized = self:WorldToLocal(intersect)
	local pos, ang

	pos = ent:GetManipulateBoneScale(bone)
	localized = Vector(localized.x - startgrab.x, 0, 0)
	local posadd = nphysscale[self.axistype] + localized.x
	ang = ent:GetManipulateBoneAngles(bone)
	pos[self.axistype] = posadd
	return pos, ang
end
