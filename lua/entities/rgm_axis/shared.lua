
ENT.Type = "anim"
ENT.Base = "base_entity"

local TransTable = {
	"ArrowOmni",
	"ArrowX", "ArrowY", "ArrowZ",
	"ArrowXY", "ArrowXZ", "ArrowYZ",
	"DiscP", "DiscY", "DiscR", "DiscLarge",
	"ScaleX", "ScaleY", "ScaleZ",
	"ScaleXY", "ScaleXZ", "ScaleYZ"
}

function ENT:Initialize()
	if CLIENT then
		self:SetNoDraw(true)
	end
	self:DrawShadow(false)
	self:SetCollisionBounds(Vector(-0.1, -0.1, -0.1), Vector(0.1, 0.1, 0.1))
	self:SetSolid(SOLID_VPHYSICS)
	self:SetNotSolid(true)
end

function ENT:TestCollision(pl, scale)
	-- PrintTable(self:GetTable())
	local rotate = pl.rgm.Rotate or false
	local modescale = pl.rgm.Scale or false
	local start, last = 1, 7

	if rotate then start, last = 8, 11 end
	if modescale then start, last = 12, 17 end

	if not self.Axises then return false end
	for i = start, last do
		local e = self.Axises[i]
		-- print(e)
		local intersect = e:TestCollision(pl, scale)
		if intersect then return intersect end
	end
	return false
end
