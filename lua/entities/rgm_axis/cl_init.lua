
include("shared.lua")

local COLOR_RGMGREEN = Color(0, 200, 0, 255)

local TransTable = {
	"ArrowOmni",
	"ArrowX", "ArrowY", "ArrowZ",
	"ArrowXY", "ArrowXZ", "ArrowYZ",
	"DiscP", "DiscY", "DiscR", "DiscLarge",
	"ScaleX", "ScaleY", "ScaleZ",
	"ScaleXY", "ScaleXZ", "ScaleYZ"
}

local Fulldisc = GetConVar("ragdollmover_fulldisc")

net.Receive("rgmAxis", function(len)
	local self = net.ReadEntity()
	self.ArrowOmni =	net.ReadEntity()
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
		self.ArrowOmni,
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
		self.ScaleYZ
	}

	self.fulldisc = Fulldisc:GetInt() ~= 0
end)

local pl

function ENT:DrawLines(scale, width)
	if not pl then pl = LocalPlayer() end

	local rotate = pl.rgm.Rotate or false
	local modescale = pl.rgm.Scale or false
	local start, last = 1, 7
	if rotate then start, last = 8, 11 end
	if modescale then start, last = 12, 17 end
	-- print(self.Axises)

	if not self.Axises then
		if self.RequestedAxis then return end
		self.RequestedAxis = true
		net.Start("rgmAxisRequest")
		net.SendToServer()
		return
	end

	local gotselected = false
	for i = start, last do
		local moveaxis = self.Axises[i]
		local yellow = false
		if moveaxis:TestCollision(pl, scale) and not gotselected then
			yellow = true
			gotselected = true
		end
		moveaxis:DrawLines(yellow, scale, width)
	end
end

function ENT:DrawDirectionLine(norm, scale, ghost)
	local pos1 = self:GetPos():ToScreen()
	local pos2 = (self:GetPos() + (norm * scale)):ToScreen()
	local grn = 255
	if ghost then grn = 150 end
	surface.SetDrawColor(0, grn, 0, 255)
	surface.DrawLine(pos1.x, pos1.y, pos2.x, pos2.y)
end

local mabs, mround = math.abs, math.Round

function ENT:DrawAngleText(axis, hitpos, startAngle)
	local pos = WorldToLocal(hitpos, angle_zero, axis:GetPos(), axis:GetAngles())
	local overnine
	pos = WorldToLocal(pos, pos:Angle(), vector_origin, startAngle:Angle())

	local localized = Vector(pos.x, pos.z, 0):Angle()

	if(localized.y > 181) then
		overnine = 360
	else
		overnine = 0
	end

	local textAngle = mabs(mround((overnine - localized.y) * 100) / 100)
	local textpos = hitpos:ToScreen()
	draw.SimpleText(textAngle, "HudHintTextLarge", textpos.x + 5, textpos.y, COLOR_RGMGREEN, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)
end

function ENT:Draw()
end
function ENT:DrawTranslucent()
end

function ENT:Think()

end
