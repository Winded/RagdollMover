
ENT.Type = "anim"
ENT.Base = "base_entity"

local GizmoType = RGMGIZMOS.GizmoTypeEnum
local AxisType = RGMGIZMOS.AxisTypeEnum
local GizmoCanGimbalLock = RGMGIZMOS.CanGimbalLock

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

	local CreateGizmo = RGMGIZMOS.GizmoFactory()

	-- The creation order of the gizmos below must match with `RGMGIZMOS.GizmoTable`
	self.ArrowOmni = CreateGizmo(GizmoType.OmniPos, self, Color(255, 165, 0, 255), Vector(1, 0, 0):Angle())

	self.ArrowX = CreateGizmo(GizmoType.PosArrow, self, Color(255, 0, 0, 255), Vector(1, 0, 0):Angle())
	self.ArrowY = CreateGizmo(GizmoType.PosArrow, self, Color(0, 255, 0, 255), Vector(0, 1, 0):Angle())
	self.ArrowZ = CreateGizmo(GizmoType.PosArrow, self, Color(0, 0, 255, 255), Vector(0, 0, 1):Angle())

	self.ArrowXY = CreateGizmo(GizmoType.PosSide, self, Color(0, 255, 0, 255), Vector(0, 0, -1):Angle(), Color(255, 0, 0, 255))
	self.ArrowXZ = CreateGizmo(GizmoType.PosSide, self, Color(255, 0, 0, 255), Vector(0, -1, 0):Angle(), Color(0, 0, 255, 255))
	self.ArrowYZ = CreateGizmo(GizmoType.PosSide, self, Color(0, 255, 0, 255), Vector(1, 0, 0):Angle(), Color(0, 0, 255, 255))
	
	self.Ball = CreateGizmo(GizmoType.Ball, self, Color(255, 255, 255, 5), Vector(0, 0, 0):Angle())

	self.DiscP = CreateGizmo(GizmoType.Disc, self, Color(255, 0, 0, 255), Vector(0, 1, 0):Angle()) -- 0 90 0
	self.DiscP.axistype = AxisType.Pitch -- axistype is a variable to help with setting non physical bones - 1 for pitch, 2 yaw, 3 roll, 4 for the big one
	self.DiscY = CreateGizmo(GizmoType.Disc, self, Color(0, 255, 0, 255), Vector(0, 0, 1):Angle()) -- 270 0 0
	self.DiscY.axistype = AxisType.Yaw
	self.DiscR = CreateGizmo(GizmoType.Disc, self, Color(0, 0, 255, 255), Vector(1, 0, 0):Angle()) -- 0 0 0
	self.DiscR.axistype = AxisType.Roll

	self.DiscLarge = CreateGizmo(GizmoType.DiscLarge, self, Color(175, 175, 175, 255), Vector(1, 0, 0):Angle())
	self.DiscLarge.axistype = AxisType.Large

	self.ScaleX = CreateGizmo(GizmoType.ScaleArrow, self, Color(255, 0, 0, 255), Vector(1, 0, 0):Angle())
	self.ScaleX.axistype = AxisType.X
	self.ScaleY = CreateGizmo(GizmoType.ScaleArrow, self, Color(0, 255, 0, 255), Vector(0, 1, 0):Angle())
	self.ScaleY.axistype = AxisType.Y
	self.ScaleZ = CreateGizmo(GizmoType.ScaleArrow, self, Color(0, 0, 255, 255), Vector(0, 0, 1):Angle())
	self.ScaleZ.axistype = AxisType.Z

	self.ScaleXY = CreateGizmo(GizmoType.ScaleSide, self, Color(0, 255, 0, 255), Vector(0, 0, -1):Angle(), Color(255, 0, 0, 255))
	self.ScaleXZ = CreateGizmo(GizmoType.ScaleSide, self, Color(255, 0, 0, 255), Vector(0, -1, 0):Angle(), Color(0, 0, 255, 255))
	self.ScaleYZ = CreateGizmo(GizmoType.ScaleSide, self, Color(0, 255, 0, 255), Vector(1, 0, 0):Angle(), Color(0, 0, 255, 255))

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

function ENT:TestCollision(pl)
	-- PrintTable(self:GetTable())
	local plTable = RAGDOLLMOVER[pl]
	local ent = plTable.Entity
	local bone = plTable.Bone
	local isparentbone = IsValid(ent) and IsValid(ent:GetParent()) and bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not ent:IsEffectActive(EF_FOLLOWBONE) and not (ent:GetClass() == "prop_ragdoll")
	local isnonphysbone = not (isparentbone or plTable.IsPhysBone)
	local rotate = plTable.Rotate or false
	local modescale = plTable.Scale or false
	
	local start, last, inc = 1, 7, 1

	if rotate then start, last, inc = 12, 8, -1 end
	if modescale then start, last = 13, 18 end

	if not self.Axises then return false end
	for i = start, last, inc do
		local e = self.Axises[i]
		if GizmoCanGimbalLock(e.gizmotype, isnonphysbone) then continue end
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
