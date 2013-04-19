
ENT.Base = "rgm_gizmo_base";
ENT.Type = "anim";

local RED = Color(255, 0, 0, 255);
local GREEN = Color(0, 255, 0, 255);
local BLUE = Color(0, 0, 255, 255);
local GREY = Color(175,175,175,255);

function ENT:MakeDisc(color, angle)
	return self:MakeAxis("rgm_axis_disc", color, angle);
end

function ENT:MakeBall()
	return self:MakeAxis("rgm_axis_ball", GREY, Angle(0, 0, 0));
end

function ENT:InitializeShared()
	
	self.BaseClass.Initialize(self);
	
	self.DiscP = self:MakeDisc(RED, Vector(0, 1, 0):Angle());
	self.DiscY = self:MakeDisc(GREEN, Vector(0, 0, 1):Angle());
	self.DiscR = self:MakeDisc(BLUE, Vector(1, 0, 0):Angle());
	
	local axes = 
	{
		self.DiscP,
		self.DiscY,
		self.DiscR
	};
	
	self:SetAxes(axes);
	
end