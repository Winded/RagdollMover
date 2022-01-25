
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

local TYPE_ARROW = 1
local TYPE_ARROWSIDE = 2
local TYPE_DISC = 3

util.AddNetworkString("rgmAxis")
util.AddNetworkString("rgmAxisUpdate")

function ENT:Setup()

	--Arrows
	self.ArrowX = ents.Create("rgm_axis_arrow")
		self.ArrowX:SetParent(self)
		self.ArrowX:Spawn()
		self.ArrowX:SetColor(Color(255,0,0,255))
		self.ArrowX:SetLocalPos(Vector(0,0,0))
		self.ArrowX:SetLocalAngles(Vector(1,0,0):Angle())
		self.ArrowX.axistype = 1

	self.ArrowY = ents.Create("rgm_axis_arrow")
		self.ArrowY:SetParent(self)
		self.ArrowY:Spawn()
		self.ArrowY:SetColor(Color(0,255,0,255))
		self.ArrowY:SetLocalPos(Vector(0,0,0))
		self.ArrowY:SetLocalAngles(Vector(0,1,0):Angle())
		self.ArrowY.axistype = 2

	self.ArrowZ = ents.Create("rgm_axis_arrow")
		self.ArrowZ:SetParent(self)
		self.ArrowZ:Spawn()
		self.ArrowZ:SetColor(Color(0,0,255,255))
		self.ArrowZ:SetLocalPos(Vector(0,0,0))
		self.ArrowZ:SetLocalAngles(Vector(0,0,1):Angle())
		self.ArrowZ.axistype = 3

	--Arrow sides
	self.ArrowXY = ents.Create("rgm_axis_side")
		self.ArrowXY:SetParent(self)
		self.ArrowXY:Spawn()
		self.ArrowXY:SetColor(Color(0,255,0,255))
		self.ArrowXY:SetNWVector("color2",Vector(255,0,0))
		self.ArrowXY:SetNWInt("type",TYPE_ARROWSIDE)
		self.ArrowXY:SetLocalPos(Vector(0,0,0))
		self.ArrowXY:SetLocalAngles(Vector(0,0,-1):Angle())

	self.ArrowXZ = ents.Create("rgm_axis_side")
		self.ArrowXZ:SetParent(self)
		self.ArrowXZ:Spawn()
		self.ArrowXZ:SetColor(Color(255,0,0,255))
		self.ArrowXZ:SetNWVector("color2",Vector(0,0,255))
		self.ArrowXZ:SetNWInt("type",TYPE_ARROWSIDE)
		self.ArrowXZ:SetLocalPos(Vector(0,0,0))
		self.ArrowXZ:SetLocalAngles(Vector(0,-1,0):Angle())

	self.ArrowYZ = ents.Create("rgm_axis_side")
		self.ArrowYZ:SetParent(self)
		self.ArrowYZ:Spawn()
		self.ArrowYZ:SetColor(Color(0,255,0,255))
		self.ArrowYZ:SetNWVector("color2",Vector(0,0,255))
		self.ArrowYZ:SetNWInt("type",TYPE_ARROWSIDE)
		self.ArrowYZ:SetLocalPos(Vector(0,0,0))
		self.ArrowYZ:SetLocalAngles(Vector(1,0,0):Angle())

	--Discs
	self.DiscP = ents.Create("rgm_axis_disc")
		self.DiscP:SetParent(self)
		self.DiscP:Spawn()
		self.DiscP:SetColor(Color(255,0,0,255))
		self.DiscP:SetNWInt("type",TYPE_DISC)
		self.DiscP:SetLocalPos(Vector(0,0,0))
		self.DiscP:SetLocalAngles(Vector(0,1,0):Angle())
		self.DiscP.axistype = 1 -- axistype is a variable to help with setting non physical bones - 1 for pitch, 2 yaw, 3 roll, 4 for the big one

	self.DiscY = ents.Create("rgm_axis_disc")
		self.DiscY:SetParent(self)
		self.DiscY:Spawn()
		self.DiscY:SetColor(Color(0,255,0,255))
		self.DiscY:SetNWInt("type",TYPE_DISC)
		self.DiscY:SetLocalPos(Vector(0,0,0))
		self.DiscY:SetLocalAngles(Vector(0,0,1):Angle())
		self.DiscY.axistype = 2

	self.DiscR = ents.Create("rgm_axis_disc")
		self.DiscR:SetParent(self)
		self.DiscR:Spawn()
		self.DiscR:SetColor(Color(0,0,255,255))
		self.DiscR:SetNWInt("type",TYPE_DISC)
		self.DiscR:SetLocalPos(Vector(0,0,0))
		self.DiscR:SetLocalAngles(Vector(1,0,0):Angle())
		self.DiscR.axistype = 3

	self.DiscLarge = ents.Create("rgm_axis_disc_large")
		self.DiscLarge:SetParent(self)
		self.DiscLarge:Spawn()
		self.DiscLarge:SetColor(Color(175,175,175,255))
		self.DiscLarge:SetNWVector("color2",Vector(88,88,88))
		self.DiscLarge:SetNWInt("type",TYPE_DISC)
		self.DiscLarge:SetLocalPos(Vector(0,0,0))
		self.DiscLarge:SetLocalAngles(Vector(1,0,0):Angle()) --This will be constantly changed
		self.DiscLarge.axistype = 4

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
	}

	timer.Create("rgmAxis", 1, 1, function()
		net.Start("rgmAxis")
		net.WriteEntity(self)
		net.WriteEntity(self.ArrowX)
		net.WriteEntity(self.ArrowY)
		net.WriteEntity(self.ArrowZ)
		net.WriteEntity(self.ArrowXY)
		net.WriteEntity(self.ArrowXZ)
		net.WriteEntity(self.ArrowYZ)
		net.WriteEntity(self.DiscP)
		net.WriteEntity(self.DiscY)
		net.WriteEntity(self.DiscR)
		net.WriteEntity(self.DiscLarge)
		net.Send(self.Owner)
	end)

	-- self:SetNWEntity("ArrowX",self.ArrowX)
	-- self:SetNWEntity("ArrowY",self.ArrowY)
	-- self:SetNWEntity("ArrowZ",self.ArrowZ)
	-- self:SetNWEntity("ArrowXY",self.ArrowXY)
	-- self:SetNWEntity("ArrowXZ",self.ArrowXZ)
	-- self:SetNWEntity("ArrowYZ",self.ArrowYZ)
	-- self:SetNWEntity("DiscP",self.DiscP)
	-- self:SetNWEntity("DiscY",self.DiscY)
	-- self:SetNWEntity("DiscR",self.DiscR)
	-- self:SetNWEntity("DiscLarge",self.DiscLarge)
end

function ENT:Think()
	local pl = self.Owner
	if not IsValid(pl) then return end

	local ent = pl.rgm.Entity
	local bone = pl.rgm.PhysBone
	if not IsValid(ent) or not pl.rgm.Bone then return end

	local OldPos = self:GetPos()
	local OldAng = self:GetAngles()
	local OldDiscPos = self.DiscLarge:GetLocalPos()
	local OldDiscAng = self.DiscLarge:GetLocalAngles()
	local pos, ang
	local rotate = pl.rgm.Rotate or false

	if pl.rgm.IsPhysBone then
		local physobj = ent:GetPhysicsObjectNum(bone)
		if physobj == nil then return end
		pos,ang = physobj:GetPos(),physobj:GetAngles()
	else
		if not pl.rgm.GizmoPos then
			local matrix = ent:GetBoneMatrix(bone)
			pos = ent:GetBonePosition(bone)
			if pos == ent:GetPos() then
				pos = matrix:GetTranslation()
			end
		else
			pos = pl.rgm.GizmoPos
		end

		if rotate then
			if not pl.rgm.GizmoAng then -- dunno if there is a need for these failsafes
				_ , ang = ent:GetBonePosition(bone)
			else
				ang = pl.rgm.GizmoAng
			end
		else
			if ent:GetBoneParent(bone) ~= -1 then
				if not pl.rgm.GizmoParent then
					matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone)) -- never would have guessed that when moving bones they use angles of their parent bone rather than their own angles. happened to get to know that after looking at vanilla bone manipulator!
					ang = matrix:GetAngles()
				else
					ang = pl.rgm.GizmoParent
				end
			else
				if IsValid(ent) then
					ang = ent:GetAngles()
				end
			end
		end
	end
	self:SetPos(pos)

	local localstate = self.localizedpos
	if rotate then localstate = self.localizedang end
	if not pl.rgm.Moving then -- Prevent whole thing from rotating when we do localized rotation - needed for proper angle reading
		if localstate or not pl.rgm.IsPhysBone then -- Non phys bones don't go well with world coordinates. Well, I didn't make them to behave with those
			self:SetAngles(ang or Angle(0,0,0))
		else
			self:SetAngles(Angle(0,0,0))
		end
	end

	--Updating positions
	-- self.ArrowX:SetLocalPos(Vector(0,0,0))
	-- self.ArrowX:SetLocalAngles(Vector(1,0,0):Angle())

	-- self.ArrowY:SetLocalPos(Vector(0,0,0))
	-- self.ArrowY:SetLocalAngles(Vector(0,1,0):Angle())

	-- self.ArrowZ:SetLocalPos(Vector(0,0,0))
	-- self.ArrowZ:SetLocalAngles(Vector(0,0,1):Angle())

	-- self.ArrowXY:SetLocalPos(Vector(0,0,0))
	-- self.ArrowXY:SetLocalAngles(Vector(0,0,-1):Angle())

	-- self.ArrowXZ:SetLocalPos(Vector(0,0,0))
	-- self.ArrowXZ:SetLocalAngles(Vector(0,-1,0):Angle())

	-- self.ArrowYZ:SetLocalPos(Vector(0,0,0))
	-- self.ArrowYZ:SetLocalAngles(Vector(1,0,0):Angle())

	-- self.DiscP:SetLocalPos(Vector(0,0,0))
	-- self.DiscP:SetLocalAngles(Vector(0,1,0):Angle())

	-- self.DiscY:SetLocalPos(Vector(0,0,0))
	-- self.DiscY:SetLocalAngles(Vector(0,0,1):Angle())

	-- self.DiscR:SetLocalPos(Vector(0,0,0))
	-- self.DiscR:SetLocalAngles(Vector(1,0,0):Angle())

	local disc = self.DiscLarge
	local ang = (self:GetPos()-pl:EyePos()):Angle()
	ang = self:WorldToLocalAngles(ang)
	disc:SetLocalAngles(ang)

	local NewPos = self:GetPos()
	local NewAng = self:GetAngles()
	local NewDiscPos = self.DiscLarge:GetLocalPos()
	local NewDiscAng = self.DiscLarge:GetLocalAngles()

	if NewPos ~= OldPos or NewAng ~= OldAng
	or NewDiscPos ~= OldDiscPos or NewDiscAng ~= OldDiscAng then
		net.Start("rgmAxisUpdate")
		net.WriteEntity(self)
		net.WriteVector(self:GetPos())
		net.WriteAngle(self:GetAngles())
		net.WriteVector(disc:GetLocalPos())
		net.WriteAngle(disc:GetLocalAngles())
		net.Send(self.Owner)
	end

	self:NextThink(CurTime()+0.001)
	return true
end
