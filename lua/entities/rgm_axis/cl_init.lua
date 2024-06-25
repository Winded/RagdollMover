
include("shared.lua")

local VECTOR_FRONT = Vector(1, 0, 0)
local COLOR_RGMGREEN = Color(0, 200, 0, 255)
local ANGLE_ARROW_OFFSET = Angle(0, 90, 90)
local ANGLE_DISC = Angle(0, 90, 0)

local Fulldisc = GetConVar("ragdollmover_fulldisc")

local pl

function ENT:DrawLines(scale, width)
	if not pl then pl = LocalPlayer() end

	local rotate = pl.rgm.Rotate or false
	local modescale = pl.rgm.Scale or false
	local start, last = 1, 7
	if rotate then start, last = 8, 11 end
	if modescale then start, last = 12, 17 end
	-- print(self.Axises)

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

	self.width = width
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

local lastang = nil

function ENT:Think()
	if not pl or not pl.rgm then return end
	if self ~= pl.rgm.Axis then return end

	local ent = pl.rgm.Entity
	if not IsValid(ent) or not pl.rgm.Bone or not self.Axises then return end

	if not pl.rgm.Moving then -- Prevent whole thing from rotating when we do localized rotation
		if pl.rgm.Rotate then
			if not pl.rgm.IsPhysBone then
				local manipang = ent:GetManipulateBoneAngles(pl.rgm.Bone)
				if manipang ~= lastang then
					self.DiscP.LocalAng = Angle(0, 90 + manipang.y, 0) -- Pitch follows Yaw angles
					self.DiscR.LocalAng = Angle(0 + manipang.x, 0 + manipang.y, 0) -- Roll follows Pitch and Yaw angles
					lastang = manipang
				end
			else
				self.DiscP.LocalAng = ANGLE_DISC
				self.DiscR.LocalAng = angle_zero
				lastang = nil
			end
		else
			self.DiscP.LocalAng = ANGLE_DISC
			self.DiscR.LocalAng = angle_zero
			lastang = nil
		end
	end

	local pos, poseye = self:GetPos(), pl:EyePos()
	local ang = (pos - poseye):Angle()
	ang = self:WorldToLocalAngles(ang)
	self.DiscLarge.LocalAng = ang
	self.ArrowOmni.LocalAng = ang

	pos, poseye = self:WorldToLocal(pos), self:WorldToLocal(poseye)
	local xangle, yangle = (Vector(pos.y, pos.z, 0) - Vector(poseye.y, poseye.z, 0)):Angle(), (Vector(pos.x, pos.z, 0) - Vector(poseye.x, poseye.z, 0)):Angle()
	local XAng, YAng, ZAng = Angle(0, 0, xangle.y + 90) + VECTOR_FRONT:Angle(), ANGLE_ARROW_OFFSET - Angle(0, 0, yangle.y), Angle(0, ang.y, 0) + vector_up:Angle()
	self.ArrowX.LocalAng = XAng
	self.ScaleX.LocalAng = XAng
	self.ArrowY.LocalAng = YAng
	self.ScaleY.LocalAng = YAng
	self.ArrowZ.LocalAng = ZAng
	self.ScaleZ.LocalAng = ZAng
end
