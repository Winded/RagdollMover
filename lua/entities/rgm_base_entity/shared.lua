
ENT.Type = "anim";
ENT.Base = "base_entity";

function ENT:SharedInitialize()

	self:SetNoDraw(true);
	self:DrawShadow(false);
	self:SetCollisionBounds(Vector(-0.1,-0.1,-0.1),Vector(0.1,0.1,0.1));
	self:SetSolid(SOLID_VPHYSICS);
	self:SetNotSolid(true);

end