
ENT.Type = "anim"
ENT.Base = "base_entity"

function ENT:Initialize()

	self.DefaultMinMax = Vector(0.1, 0.1, 0.1)
	self.LastSize = self.DefaultMinMax
	self.LastPos = self:GetPos()

	self:DrawShadow(false)
	self:SetCollisionBounds(-self.DefaultMinMax, self.DefaultMinMax)
	self:SetMoveType(MOVETYPE_VPHYSICS)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetNotSolid(true)

	self.ArrowOmni = RGMGIZMOS.CreateGizmo(0, 1, self, Color(255, 165, 0, 255), Vector(1, 0, 0):Angle())

	self.ArrowX = RGMGIZMOS.CreateGizmo(1, 2, self, Color(255, 0, 0, 255), Vector(1, 0, 0):Angle())
	self.ArrowY = RGMGIZMOS.CreateGizmo(1, 3, self, Color(0, 255, 0, 255), Vector(0, 1, 0):Angle())
	self.ArrowZ = RGMGIZMOS.CreateGizmo(1, 4, self, Color(0, 0, 255, 255), Vector(0, 0, 1):Angle())

	self.ArrowXY = RGMGIZMOS.CreateGizmo(2, 5, self, Color(0, 255, 0, 255), Vector(0, 0, -1):Angle(), Color(255, 0, 0, 255))
	self.ArrowXZ = RGMGIZMOS.CreateGizmo(2, 6, self, Color(255, 0, 0, 255), Vector(0, -1, 0):Angle(), Color(0, 0, 255, 255))
	self.ArrowYZ = RGMGIZMOS.CreateGizmo(2, 7, self, Color(0, 255, 0, 255), Vector(1, 0, 0):Angle(), Color(0, 0, 255, 255))

	self.DiscP = RGMGIZMOS.CreateGizmo(3, 8, self, Color(255, 0, 0, 255), Vector(0, 1, 0):Angle()) -- 0 90 0
	self.DiscP.axistype = 1 -- axistype is a variable to help with setting non physical bones - 1 for pitch, 2 yaw, 3 roll, 4 for the big one
	self.DiscY = RGMGIZMOS.CreateGizmo(3, 9, self, Color(0, 255, 0, 255), Vector(0, 0, 1):Angle()) -- 270 0 0
	self.DiscY.axistype = 2
	self.DiscR = RGMGIZMOS.CreateGizmo(3, 10, self, Color(0, 0, 255, 255), Vector(1, 0, 0):Angle()) -- 0 0 0
	self.DiscR.axistype = 3

	self.DiscLarge = RGMGIZMOS.CreateGizmo(4, 11, self, Color(175, 175, 175, 255), Vector(1, 0, 0):Angle())
	self.DiscLarge.axistype = 4

	self.ScaleX = RGMGIZMOS.CreateGizmo(5, 12, self, Color(255, 0, 0, 255), Vector(1, 0, 0):Angle())
	self.ScaleX.axistype = 1
	self.ScaleY = RGMGIZMOS.CreateGizmo(5, 13, self, Color(0, 255, 0, 255), Vector(0, 1, 0):Angle())
	self.ScaleY.axistype = 2
	self.ScaleZ = RGMGIZMOS.CreateGizmo(5, 14, self, Color(0, 0, 255, 255), Vector(0, 0, 1):Angle())
	self.ScaleZ.axistype = 3

	self.ScaleXY = RGMGIZMOS.CreateGizmo(6, 15, self, Color(0, 255, 0, 255), Vector(0, 0, -1):Angle(), Color(255, 0, 0, 255))
	self.ScaleXZ = RGMGIZMOS.CreateGizmo(6, 16, self, Color(255, 0, 0, 255), Vector(0, -1, 0):Angle(), Color(0, 0, 255, 255))
	self.ScaleYZ = RGMGIZMOS.CreateGizmo(6, 17, self, Color(0, 255, 0, 255), Vector(1, 0, 0):Angle(), Color(0, 0, 255, 255))

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

	self.width = GetConVar("ragdollmover_width"):GetInt() or 0.5
	self.scale = GetConVar("ragdollmover_scale"):GetInt() or 10
	self:CalculateGizmo()

	if CLIENT then
		self:SetNoDraw(true)
		self.fulldisc = GetConVar("ragdollmover_fulldisc"):GetInt() ~= 0 -- last time i used GetBool, it was breaking for 64 bit branch
	end
end

function ENT:TestCollision(pl)
	-- PrintTable(self:GetTable())
	local rotate = RAGDOLLMOVER[pl].Rotate or false
	local modescale = RAGDOLLMOVER[pl].Scale or false
	local start, last = 1, 7

	if rotate then start, last = 8, 11 end
	if modescale then start, last = 12, 17 end

	if not self.Axises then return false end
	for i = start, last do
		local e = self.Axises[i]
		-- print(e)
		local intersect = e:TestCollision(pl)
		if intersect then return intersect end
	end

	return false
end

function ENT:CalculateGizmo()
	local scale = self.scale

	for i, axis in ipairs(self.Axises) do
		axis:CalculateGizmo(scale)
	end
end
