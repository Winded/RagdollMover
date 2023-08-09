
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
	self:SetCollisionBounds(Vector(-0.1,-0.1,-0.1),Vector(0.1,0.1,0.1))
	self:SetSolid(SOLID_VPHYSICS)
	self:SetNotSolid(true)
end

function ENT:TestCollision(pl,scale)
	-- PrintTable(self:GetTable())
	local rotate = pl.rgm.Rotate or false
	local modescale = pl.rgm.Scale or false
	local Start,End = 1,7
	if rotate then Start,End = 8,11 end
	if modescale then Start, End = 12, 17 end

	local cols = {}
	if not self.Axises then return false end
	for i=Start,End do
		local e = self.Axises[i]
		-- print(e)
		cols[i] = e:TestCollision(pl,scale)
	end
	for i=Start,End do
		if cols[i] then return cols[i] end
	end
	return false
end
