
ENT.Type = "anim"
ENT.Base = "base_entity"

function ENT:Initialize()
	if CLIENT then
		self:SetNoDraw(true)
	end
	self:DrawShadow(false)
	self:SetCollisionBounds(Vector(-0.1,-0.1,-0.1),Vector(0.1,0.1,0.1))
	self:SetSolid(SOLID_VPHYSICS)
	self:SetNotSolid(true)
end

function ENT:GetType()
	return self:GetNWInt("type",1)
end

function ENT:GetGrabPos(eyepos,eyeang,ppos,pnorm)
	local pos = eyepos
	local norm = eyeang:Forward()
	local planepos = self:GetPos()
	local planenorm = self:GetAngles():Forward()
	if ppos then planepos = ppos*1 end
	if pnorm then planenorm = pnorm*1 end
	local intersect = rgm.IntersectRayWithPlane(planepos,planenorm,pos,norm)
	return intersect
end

--To be overwritten
function ENT:TestCollision(id,pl,scale)
end
