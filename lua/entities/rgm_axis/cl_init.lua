
include("shared.lua")

local TransTable = {
	"ArrowX", "ArrowY", "ArrowZ",
	"ArrowXY", "ArrowXZ", "ArrowYZ",
	"DiscP", "DiscY", "DiscR", "DiscLarge",
	"ScaleX", "ScaleY", "ScaleZ",
	"ScaleXY", "ScaleXZ", "ScaleYZ"
}

net.Receive("rgmAxis",function(len)
	local self = net.ReadEntity()
	self.ArrowX =		net.ReadEntity()
	self.ArrowY =		net.ReadEntity()
	self.ArrowZ =		net.ReadEntity()
	self.ArrowXY =		net.ReadEntity()
	self.ArrowXZ =		net.ReadEntity()
	self.ArrowYZ =		net.ReadEntity()
	self.DiscP =		net.ReadEntity()
	self.DiscY =		net.ReadEntity()
	self.DiscR =		net.ReadEntity()
	self.DiscLarge = 	net.ReadEntity()
	self.ScaleX =		net.ReadEntity()
	self.ScaleY =		net.ReadEntity()
	self.ScaleZ =		net.ReadEntity()
	self.ScaleXY =		net.ReadEntity()
	self.ScaleXZ =		net.ReadEntity()
	self.ScaleYZ =		net.ReadEntity()
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
		self.ScaleX,
		self.ScaleY,
		self.ScaleZ,
		self.ScaleXY,
		self.ScaleXZ,
		self.ScaleYZ,
	}
end)

net.Receive("rgmAxisUpdate",function(len)
	local self = net.ReadEntity()
	local pos = net.ReadVector()
	local ang = net.ReadAngle()

	local discpos = net.ReadVector()
	local discang = net.ReadAngle()

	if not self.Axises then return end

	self.TargetPos = pos
	self.TargetAng = ang
	self.TargetDiscPos = discpos
	self.TargetDiscAng = discang
end)

function ENT:DrawLines(scale,width)
	local pl = LocalPlayer()

	local rotate = pl.rgm.Rotate or false
	local modescale = pl.rgm.Scale or false
	local collision = self:TestCollision(LocalPlayer(),scale)
	local Start,End = 1,6
	if rotate then Start,End = 7,10 end
	if modescale then Start, End = 11, 16 end
	-- print(self.Axises)
	if not self.Axises then return end
	for i=Start,End do
		local moveaxis = self.Axises[i]
		local yellow = false
		if collision and moveaxis == collision.axis then
			yellow = true
		end
		moveaxis:DrawLines(yellow,scale,width)
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

function ENT:DrawAngleText(axis, hitpos, startAngle)
	local pos = WorldToLocal(hitpos, Angle(0,0,0), axis:GetPos(), axis:GetAngles())
	local overnine
	pos = WorldToLocal(pos, pos:Angle(), Vector(0, 0, 0), startAngle:Angle())

	local localized = Vector(pos.x, pos.z, 0):Angle()

	if(localized.y > 181) then
		overnine = 360
	else
		overnine = 0
	end

	local textAngle = math.abs(math.Round( (overnine - localized.y) * 100 ) / 100)
	local textpos = hitpos:ToScreen()
	draw.SimpleText(textAngle,"HudHintTextLarge",textpos.x + 5,textpos.y,Color(0,200,0,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
end

function ENT:Draw()
end
function ENT:DrawTranslucent()
end

function ENT:Think()

end
