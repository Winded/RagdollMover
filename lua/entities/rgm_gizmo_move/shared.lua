
ENT.Base = "rgm_gizmo_base";
ENT.Type = "anim";

local TYPE_ARROW = 1;
local TYPE_ARROWSIDE = 2;

local RED = Color(255, 0, 0, 255);
local GREEN = Color(0, 255, 0, 255);
local BLUE = Color(0, 0, 255, 255);
local GREY = Color(175,175,175,255);

function ENT:MakeArrow(color, angle)
	local axis = self:MakeAxis("rgm_axis_arrow", color, angle);
	
	return axis;
end

function ENT:MakeSide(color1, color2, angle)
	local axis = self:MakeAxis("rgm_axis_side", GREY, angle);
	axis:SetColor1(color1);
	axis:SetColor2(color2);
	
	return axis;
end

function ENT:Initialize()
	
	self.BaseClass.Initialize(self);
	
	local axes = {};

	axes.ArrowX = 		self:MakeArrow(	RED, 			Vector(1, 0, 0):Angle());
	axes.ArrowY = 		self:MakeArrow(	GREEN, 			Vector(0, 1, 0):Angle());
	axes.ArrowY = 		self:MakeArrow(	BLUE, 			Vector(0, 0, 1):Angle());
	
	axes.ArrowXY = 		self:MakeSide(	RED, 	GREEN, 	Vector(0, 0, -1):Angle());
	axes.ArrowXZ =		self:MakeSide(	RED, 	BLUE, 	Vector(0, -1, 0):Angle());
	axes.ArrowYZ = 		self:MakeSide(	GREEN, 	BLUE,	Vector(1, 0, 0):Angle());
	
	self:SetAxes(axes);
	
end