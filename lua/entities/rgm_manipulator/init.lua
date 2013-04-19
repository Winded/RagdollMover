
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

local TYPE_ARROW = 1
local TYPE_ARROWSIDE = 2
local TYPE_DISC = 3

local RED = Color(255, 0, 0, 255);
local GREEN = Color(0, 255, 0, 255);
local BLUE = Color(0, 0, 255, 255);
local GREY = Color(175,175,175,255);

local function MakeGizmo(self, name)
	
	local gizmo = ents.Create(name);
	gizmo:SetParent(self);
	gizmo:Spawn();
	gizmo:SetLocalPos(Vector(0, 0, 0));
	gizmo:SetLocalAngles(Angle(0, 0, 0));
	
end

local function MakeAxis(self, name, type, color, angle)

	local axis = ents.Create(name);
	axis:SetParent(self);
	axis:Spawn();
	axis:SetNWInt("Type", type);
	axis:SetColor(color);
	axis:SetLocalPos(Vector(0,0,0));
	axis:SetLocalAngles(angle);
	axis:SetScale(self:GetScale());
	
	return axis;
		
end

local function MakeSide(self, color1, color2, angle)
	local axis = MakeAxis(self, "rgm_axis_side", TYPE_ARROWSIDE, GREY, angle);
	axis:SetColor1(color1);
	axis:SetColor2(color2);
	
	return axis;
end

function ENT:Initialize()

	self:InitializeShared();
	
	self.MoveGizmo = MakeGizmo("rgm_gizmo_move");
	self.RotateGizmo = MakeGizmo("rgm_gizmo_rotate");
	self.ScaleGizmo = MakeGizmo("rgm_gizmo_scale");
	
	self.m_Gizmos = 
	{
		self.MoveGizmo,
		self.RotateGizmo,
		self.ScaleGizmo,
	};
	
	self.m_Skeleton = {};
	
	self:SendMessage("SetupGizmos", self.MoveGizmo, self.RotateGizmo, self.ScaleGizmo);
	
end

function ENT:SetTarget(target)
	self:SetNWEntity("Target", target);
end

---
-- Attempt to grab an axis from the player's eye trace.
-- If no axis is traced, returns false,
-- If an axis is traced, creates grab data for this axis and returns true.
---
function ENT:Grab()
	
	local trace = self:GetTrace();
	if not trace.success then return false; end
	
	local gdata = rgm.GrabData(trace.axis, trace.axisOffset);
	self.m_GrabData = gdata;
	
	return true;
	
end

---
-- If an axis is grabbed, it is released. This removes rgm grab data.
---
function ENT:Release()
	self.m_GrabData = nil;
end

function ENT:SetMode(mode)
	self:SetNWInt("Mode", mode);
end

function ENT:Think()
	local pl = self:GetThread():GetPlayer();
	if not IsValid(pl) then return end
	
	local ent = self:GetThread():GetEntity();
	local bone = self:GetThread():GetBone();
	if not IsValid(ent) then return end
	
	local physobj = ent:GetPhysicsObjectNum(bone)
	local pos,ang = physobj:GetPos(),physobj:GetAngles()
	
	self:SetPos(pos)
	
	if self:GetThread():IsLocalized() then
		self:SetAngles(ang)
	else
		self:SetAngles(Angle(0,0,0))
	end
	
	self:NextThink(CurTime() + 0.001);
	return true;
end