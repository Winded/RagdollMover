
ENT.Type = "anim";
ENT.Base = "base_entity";

function ENT:SharedInitialize()

	self:SetNoDraw(true);
	self:DrawShadow(false);
	self:SetCollisionBounds(Vector(-0.1,-0.1,-0.1),Vector(0.1,0.1,0.1));
	self:SetSolid(SOLID_VPHYSICS);
	self:SetNotSolid(true);

end

function ENT:CallBase(name, ...)

	local args = {...};
	local basecount = self.__basecount;

	if not basecount then
		basecount = 0;
		local base = getmetatable(self);
		while true do
			base = getmetatable(base);
			if not base then
				break;
			end
			basecount = basecount + 1;
		end
		self.__basecount = basecount;
	end

	if basecount == 0 then return; end

	local baselevel = self.__baselevel;
	if not baselevel then
		baselevel = 1;
	end

	local base = getmetatable(self);
	local i = 0;
	while i < baselevel do
		base = getmetatable(base);
		i = i + 1;
	end

	base = getmetatable(base);
	if not base then
		self.__baselevel = nil;
		return;
	end

	self.__baselevel = baselevel;

end