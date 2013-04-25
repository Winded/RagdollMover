
include("shared.lua")

local TransTable = {
	"ArrowX", "ArrowY", "ArrowZ",
	"ArrowXY", "ArrowXZ", "ArrowYZ",
	"DiscP", "DiscY", "DiscR", "DiscLarge"
}

net.Receive("rgmAxis",function(len)
	local self = net.ReadEntity();
	self.ArrowX =		net.ReadEntity();
	self.ArrowY =		net.ReadEntity();
	self.ArrowZ =		net.ReadEntity();
	self.ArrowXY =		net.ReadEntity();
	self.ArrowXZ =		net.ReadEntity();
	self.ArrowYZ =		net.ReadEntity();
	self.DiscP =		net.ReadEntity();
	self.DiscY =		net.ReadEntity();
	self.DiscR =		net.ReadEntity();
	self.DiscLarge = 	net.ReadEntity();
	self.Axises = {
		self.ArrowX,
		self.ArrowY,
		self.ArrowZ,
		self.ArrowXY,
		self.ArrowXZ,
		self.ArrowYZ,
		self.DiscP,
		self.DiscY,
		self.DiscR,
		self.DiscLarge,
	};
	print(self.DiscP);
	print(self.Axises);
end)

net.Receive("rgmAxisUpdate",function(len)
	local self = net.ReadEntity();
	local pos = net.ReadVector();
	local ang = net.ReadAngle();
	
	local discpos = net.ReadVector();
	local discang = net.ReadAngle();
	
	if !self.Axises then return end
	
	self.TargetPos = pos;
	self.TargetAng = ang;
	self.TargetDiscPos = discpos;
	self.TargetDiscAng = discang;
end)

function ENT:DrawLines(scale)
	local pl = LocalPlayer();
	if !self.Axises then return end
	
	local rotate = pl.rgm.Rotate or false;
	local collision = self:TestCollision(LocalPlayer(),scale)
	local ToScreen = {}
	local Start,End = 1,6
	if rotate then Start,End = 7,10 end
	-- print(self.Axises);
	for i=Start,End do
		local moveaxis = self.Axises[i];
		local yellow = false
		if collision and moveaxis == collision.axis then
			yellow = true
		end
		moveaxis:DrawLines(yellow,scale)
		table.Add(ToScreen,lines)
	end
end

// Deprecated
function ENT:DrawLinesSingle(id,scale)
	local ToScreen = self:GetNWEntity(TransTable[id]):DrawLines(true,scale)
	for i,v in ipairs(ToScreen) do
		surface.SetDrawColor(unpack(v[3]))
		surface.DrawLine(v[1].x,v[1].y,v[2].x,v[2].y)
	end
end

function ENT:DrawDirectionLine(norm,scale,ghost)
	local pos1 = self:GetPos():ToScreen()
	local pos2 = (self:GetPos()+(norm*scale)):ToScreen()
	local grn = 255
	if ghost then grn = 150 end
	surface.SetDrawColor(0,grn,0,255)
	surface.DrawLine(pos1.x,pos1.y,pos2.x,pos2.y)
end

function ENT:Draw()
end
function ENT:DrawTranslucent()
end

function ENT:Think()
	
end