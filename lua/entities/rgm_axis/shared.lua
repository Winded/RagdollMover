
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
	self:SetRenderMode(RENDERMODE_TRANSCOLOR)

	self.ArrowOmni = RGMGIZMOS.CreateGizmo(0, 1, self, Color(255, 165, 0, 255), Vector(1, 0, 0):Angle())

	self.ArrowX = RGMGIZMOS.CreateGizmo(1, 2, self, Color(255, 0, 0, 255), Vector(1, 0, 0):Angle())
	self.ArrowY = RGMGIZMOS.CreateGizmo(1, 3, self, Color(0, 255, 0, 255), Vector(0, 1, 0):Angle())
	self.ArrowZ = RGMGIZMOS.CreateGizmo(1, 4, self, Color(0, 0, 255, 255), Vector(0, 0, 1):Angle())

	self.ArrowXY = RGMGIZMOS.CreateGizmo(2, 5, self, Color(0, 255, 0, 255), Vector(0, 0, -1):Angle(), Color(255, 0, 0, 255))
	self.ArrowXZ = RGMGIZMOS.CreateGizmo(2, 6, self, Color(255, 0, 0, 255), Vector(0, -1, 0):Angle(), Color(0, 0, 255, 255))
	self.ArrowYZ = RGMGIZMOS.CreateGizmo(2, 7, self, Color(0, 255, 0, 255), Vector(1, 0, 0):Angle(), Color(0, 0, 255, 255))
	
	self.Ball = RGMGIZMOS.CreateGizmo(5, 8, self, Color(175, 175, 175, 75), Vector(0, 0, 0):Angle())

	self.DiscP = RGMGIZMOS.CreateGizmo(3, 9, self, Color(255, 0, 0, 255), Vector(0, 1, 0):Angle()) -- 0 90 0
	self.DiscP.axistype = 1 -- axistype is a variable to help with setting non physical bones - 1 for pitch, 2 yaw, 3 roll, 4 for the big one
	self.DiscY = RGMGIZMOS.CreateGizmo(3, 10, self, Color(0, 255, 0, 255), Vector(0, 0, 1):Angle()) -- 270 0 0
	self.DiscY.axistype = 2
	self.DiscR = RGMGIZMOS.CreateGizmo(3, 11, self, Color(0, 0, 255, 255), Vector(1, 0, 0):Angle()) -- 0 0 0
	self.DiscR.axistype = 3

	self.DiscLarge = RGMGIZMOS.CreateGizmo(4, 12, self, Color(175, 175, 175, 255), Vector(1, 0, 0):Angle())
	self.DiscLarge.axistype = 4

	self.ScaleX = RGMGIZMOS.CreateGizmo(6, 13, self, Color(255, 0, 0, 255), Vector(1, 0, 0):Angle())
	self.ScaleX.axistype = 1
	self.ScaleY = RGMGIZMOS.CreateGizmo(6, 14, self, Color(0, 255, 0, 255), Vector(0, 1, 0):Angle())
	self.ScaleY.axistype = 2
	self.ScaleZ = RGMGIZMOS.CreateGizmo(6, 15, self, Color(0, 0, 255, 255), Vector(0, 0, 1):Angle())
	self.ScaleZ.axistype = 3

	self.ScaleXY = RGMGIZMOS.CreateGizmo(7, 16, self, Color(0, 255, 0, 255), Vector(0, 0, -1):Angle(), Color(255, 0, 0, 255))
	self.ScaleXZ = RGMGIZMOS.CreateGizmo(7, 17, self, Color(255, 0, 0, 255), Vector(0, -1, 0):Angle(), Color(0, 0, 255, 255))
	self.ScaleYZ = RGMGIZMOS.CreateGizmo(7, 18, self, Color(0, 255, 0, 255), Vector(1, 0, 0):Angle(), Color(0, 0, 255, 255))

	self.Axises = {}

	for i, gizmoName in ipairs(RGMGIZMOS.GizmoTable) do
		self.Axises[i] = self[gizmoName]
	end

	self.width = GetConVar("ragdollmover_width"):GetInt() or 0.5
	self.scale = GetConVar("ragdollmover_scale"):GetInt() or 10
	self:CalculateGizmo()

	if CLIENT then
		self:SetNoDraw(true)
		self.fulldisc = GetConVar("ragdollmover_fulldisc"):GetInt() ~= 0 -- last time i used GetBool, it was breaking for 64 bit branch
	end
end

function ENT:TestCollision(pl, shouldTest)
	-- PrintTable(self:GetTable())
	local rotate = RAGDOLLMOVER[pl].Rotate or false
	local modescale = RAGDOLLMOVER[pl].Scale or false
	local start, last = 1, 7

	if rotate then start, last = 8, 12 end
	if modescale then start, last = 13, 18 end

	if not self.Axises then return false end
	for i = start, last do
		local e = self.Axises[i]
		-- print(e)
		local intersect = e:TestCollision(pl, self.scale, shouldTest)
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
