
TOOL.Name = "#tool.ragdollmover.name"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["localpos"] = 0
TOOL.ClientConVar["localang"] = 1
TOOL.ClientConVar["scale"] = 10
TOOL.ClientConVar["fulldisc"] = 0
TOOL.ClientConVar["disablefilter"] = 0
TOOL.ClientConVar["disablechildbone"] = 0

TOOL.ClientConVar["ik_leg_L"] = 0
TOOL.ClientConVar["ik_leg_R"] = 0
TOOL.ClientConVar["ik_hand_L"] = 0
TOOL.ClientConVar["ik_hand_R"] = 0
TOOL.ClientConVar["hipkneeroll"] = 3
TOOL.ClientConVar["ignoredaxis"] = 3

TOOL.ClientConVar["unfreeze"] = 0
TOOL.ClientConVar["updaterate"] = 0.01

TOOL.ClientConVar["rotatebutton"] = MOUSE_MIDDLE
TOOL.ClientConVar["scalebutton"] = MOUSE_RIGHT

local function RGMGetBone(pl, ent, bone)
	--------------------------------------------------------- yeah this part is from locrotscale
	local phys, physobj
	pl.rgm.IsPhysBone = false

	local count = ent:GetPhysicsObjectCount()

	for i = 0, count - 1 do
		local b = ent:TranslatePhysBoneToBone(i)
		if bone == b then 
			phys = i
			pl.rgm.IsPhysBone = true
		end
	end

	if count == 1 then
		if (ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_effect") and bone == 0 then
			phys = 0
			pl.rgm.IsPhysBone = true
		end
	end
	---------------------------------------------------------
	local bonen = phys or bone

	pl.rgm.PhysBone = bonen
	if pl.rgm.IsPhysBone then
		pl.rgm.Bone = ent:TranslatePhysBoneToBone(bonen)
	else
		pl.rgm.Bone = bonen
	end
end

if SERVER then

util.AddNetworkString("rgmUpdateLists")

util.AddNetworkString("rgmUpdateBones")

util.AddNetworkString("rgmAskForPhysbones")
util.AddNetworkString("rgmAskForPhysbonesResponse")

util.AddNetworkString("rgmAskForParented")
util.AddNetworkString("rgmAskForParentedResponse")

util.AddNetworkString("rgmSelectBone")
util.AddNetworkString("rgmSelectBoneResponse")

util.AddNetworkString("rgmLockBone")
util.AddNetworkString("rgmLockBoneResponse")

util.AddNetworkString("rgmSelectEntity")

net.Receive("rgmAskForPhysbones", function(len, pl)
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end

	local count = ent:GetPhysicsObjectCount() - 1
	if count ~= -1 then
		net.Start("rgmAskForPhysbonesResponse")
			net.WriteUInt(count, 8)
			for i = 0, count do
				local bone = ent:TranslatePhysBoneToBone(i)
				if bone == -1 then bone = 0 end
				net.WriteUInt(bone, 32)
			end
		net.Send(pl)
	end
end)

net.Receive("rgmAskForParented", function(len, pl)
	local ent = net.ReadEntity()
	if not IsValid(ent) or not IsValid(pl.rgm.ParentEntity) then return end

	local parented = {}

	for i = 0, ent:GetBoneCount() - 1 do
		if pl.rgm.ParentEntity:LookupBone(ent:GetBoneName(i)) then
			table.insert(parented, i)
		end
	end

	if next(parented) then
		net.Start("rgmAskForParentedResponse")
			net.WriteUInt(#parented, 32)
			for k, id in ipairs(parented) do
				net.WriteUInt(id, 32)
			end
		net.Send(pl)
	end
end)

net.Receive("rgmSelectBone", function(len, pl)
	local ent = net.ReadEntity()
	local bone = net.ReadUInt(32)
	RGMGetBone(pl, ent, bone)
	pl:rgmSync()

	net.Start("rgmSelectBoneResponse")
		net.WriteBool(pl.rgm.IsPhysBone)
		net.WriteEntity(ent)
		net.WriteUInt(pl.rgm.Bone, 32)
	net.Send(pl)
end)

net.Receive("rgmLockBone", function(len, pl)
	local mode = net.ReadUInt(2)
	local ent = pl.rgm.Entity
	if not IsValid(ent) or not pl.rgm.IsPhysBone then return end
	if ent:GetClass() ~= "prop_ragdoll" then return end

	if mode == 1 then
		if not pl.rgmPosLocks[pl.rgm.PhysBone] then
			pl.rgmPosLocks[pl.rgm.PhysBone] = ent:GetPhysicsObjectNum(pl.rgm.PhysBone)
		else
			pl.rgmPosLocks[pl.rgm.PhysBone] = nil
		end
	elseif mode == 2 then
		if not pl.rgmAngLocks[pl.rgm.PhysBone] then
			pl.rgmAngLocks[pl.rgm.PhysBone] = ent:GetPhysicsObjectNum(pl.rgm.PhysBone)
		else
			pl.rgmAngLocks[pl.rgm.PhysBone] = nil
		end
	end

	local poslock, anglock = IsValid(pl.rgmPosLocks[pl.rgm.PhysBone]), IsValid(pl.rgmAngLocks[pl.rgm.PhysBone])

	net.Start("rgmLockBoneResponse")
		net.WriteUInt(ent:TranslatePhysBoneToBone(pl.rgm.PhysBone), 32)
		net.WriteBool(poslock)
		net.WriteBool(anglock)
	net.Send(pl)
end)

net.Receive("rgmSelectEntity", function(len, pl)
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end

	pl.rgm.Entity = ent

	if not ent.rgmbonecached then -- also taken from locrotscale. some hacky way to cache the bones?
		local p = pl.rgmSwep:GetParent()
		pl.rgmSwep:FollowBone(ent, 0)
		pl.rgmSwep:SetParent(p)
		ent.rgmbonecached = true
	end

	RGMGetBone(pl, pl.rgm.Entity, 0)
	pl:rgmSync()

	net.Start("rgmUpdateBones")
		net.WriteEntity(ent)
	net.Send(pl)
end)

end

concommand.Add("ragdollmover_resetroot", function(pl)
	RGMGetBone(pl, pl.rgm.Entity, 0)
	pl:rgmSync()
end)

concommand.Add("ragdollmover_resetbone", function(pl)
	ent = pl.rgm.Entity
	ent:ManipulateBoneAngles(pl.rgm.Bone, Angle(0, 0, 0))
	ent:ManipulateBonePosition(pl.rgm.Bone, Vector(0, 0, 0))
end)

concommand.Add("ragdollmover_resetscale", function(pl)
	ent = pl.rgm.Entity
	ent:ManipulateBoneScale(pl.rgm.Bone, Vector(1, 1, 1))
end)

function TOOL:Deploy()
	if SERVER then
		local pl = self:GetOwner()
		local axis = pl.rgm.Axis
		if not IsValid(axis) then
			axis = ents.Create("rgm_axis")
			axis:Spawn()
			axis.Owner = pl
			pl.rgm.Axis = axis
		end
		pl.rgmToolActive = true
	end
end

function TOOL:Holster()
	if CLIENT then return end
	local pl = self:GetOwner()
	pl.rgmToolActive = false
end

local function rgmFindEntityChildren(parent)
	local children = {}

	if parent:GetClass() == "prop_effect" and IsValid(parent.AttachedEntity) then
		table.insert(children, parent.AttachedEntity)
	end
	for k, ent in pairs(parent:GetChildren()) do
		if !IsValid(ent) then continue end
		if ent:GetClass() == "ent_bonemerged" then
			table.insert(children, ent)
		end
	end

	return children
end

local function EntityFilter(ent)
	return (ent:GetClass() == "prop_ragdoll" or ent:GetClass() == "prop_physics" or ent:GetClass() == "prop_effect") or (tobool(GetConVar("ragdollmover_disablefilter"):GetBool()) and not ent:IsWorld())
end

function TOOL:LeftClick(tr)

	if CLIENT then return false end

	local pl = self:GetOwner()

	if pl.rgm.Moving then return false end

	local axis = pl.rgm.Axis
	if not IsValid(axis) then
		pl:ChatPrint("Axis entity isn't found. Spawning new one, try selecting the entity again.")
		axis = ents.Create("rgm_axis")
		axis:Spawn()
		axis.Owner = pl
		pl.rgm.Axis = axis
		return false
	end
	if not axis.Axises then
		axis:Setup()
	end

	local collision = axis:TestCollision(pl,self:GetClientNumber("scale",10))
	local ent = pl.rgm.Entity

	if collision and IsValid(ent) then

		if _G["physundo"] and _G["physundo"].Create then
			_G["physundo"].Create(ent,pl)
		end

		local apart = collision.axis

		pl.rgmISPos = collision.hitpos*1
		pl.rgmISDir = apart:GetAngles():Forward()

		pl.rgmOffsetPos = WorldToLocal(apart:GetPos(),apart:GetAngles(),collision.hitpos,apart:GetAngles())

		local opos = apart:WorldToLocal(collision.hitpos)
		local obj = ent:GetPhysicsObjectNum(pl.rgm.PhysBone)
		local grabang = apart:LocalToWorldAngles(Angle(0,0,Vector(opos.y,opos.z,0):Angle().y))
		local _p
		if obj then 
			_p,pl.rgmOffsetAng = WorldToLocal(apart:GetPos(),obj:GetAngles(),apart:GetPos(),grabang)
			pl.rgmOffsetTable = rgm.GetOffsetTable(self, ent, pl.rgm.Rotate)
		end

		pl.rgm.StartAngle = WorldToLocal(collision.hitpos, Angle(0,0,0), apart:GetPos(), apart:GetAngles())
		if ent:GetClass() ~= "prop_ragdoll" and pl.rgm.IsPhysBone then
			pl.rgm.Bone = 0
		end
		pl.rgm.NPhysBonePos = ent:GetManipulateBonePosition(pl.rgm.Bone)
		pl.rgm.NPhysBoneAng = ent:GetManipulateBoneAngles(pl.rgm.Bone)
		pl.rgm.NPhysBoneScale = ent:GetManipulateBoneScale(pl.rgm.Bone)


		local dirnorm = (collision.hitpos-axis:GetPos())
		dirnorm:Normalize()
		pl.rgm.DirNorm = dirnorm
		pl.rgm.MoveAxis = apart
		pl.rgm.KeyDown = true
		pl.rgm.Moving = true
		pl:rgmSync()
		return false

	elseif IsValid(tr.Entity) and EntityFilter(tr.Entity) then
		local entity
		entity = tr.Entity
		pl.rgm.Entity = tr.Entity
		pl.rgm.ParentEntity = tr.Entity

		if not entity.rgmbonecached then -- also taken from locrotscale. some hacky way to cache the bones?
			pl.rgmSwep = self.SWEP
			local p = self.SWEP:GetParent()
			self.SWEP:FollowBone(entity, 0)
			self.SWEP:SetParent(p)
			entity.rgmbonecached = true
		end

		pl.rgm.PhysBone = tr.PhysicsBone
		pl.rgm.Bone = entity:TranslatePhysBoneToBone(tr.PhysicsBone)
		pl.rgm.IsPhysBone = true

		if ent ~= pl.rgm.ParentEntity then
			local children = rgmFindEntityChildren(pl.rgm.ParentEntity)

			net.Start("rgmUpdateLists")
				net.WriteEntity(pl.rgm.Entity)
				net.WriteUInt(#children, 32)
				for k, v in ipairs(children) do
					net.WriteEntity(v)
				end
			net.Send(pl)

			pl.rgmPosLocks = {}
			pl.rgmAngLocks = {}
		end

		pl:rgmSync()

		net.Start("rgmSelectBoneResponse")
			net.WriteBool(pl.rgm.IsPhysBone)
			net.WriteEntity(pl.rgm.Entity)
			net.WriteUInt(pl.rgm.Bone, 32)
		net.Send(pl)
	end

	return false
end

function TOOL:RightClick(tr)
	return false
end

function TOOL:Reload()
	if CLIENT then return false end

	local pl = self:GetOwner()
		RunConsoleCommand("ragdollmover_resetroot")
	return false
end

function TOOL:Think()
	if CLIENT then
		local pl = self:GetOwner()
		if not pl.rgm then return end

		if pl.rgm.Moving then return end -- don't want to keep updating this stuff when we move stuff, so it'll go smoother

		local ent, axis = pl.rgm.Entity, pl.rgm.Axis -- so, this thing... bone position and angles seem to work clientside best, whereas server's ones are kind of shite
		if IsValid(ent) and IsValid(axis) and pl.rgm.Bone then
			local bone = pl.rgm.Bone
			local pos, ang = ent:GetBonePosition(bone)
			if pos == ent:GetPos() then
				local matrix = ent:GetBoneMatrix(bone)
				pos = matrix:GetTranslation()
				ang = matrix:GetAngles()
			end
			if ent:GetBoneParent(bone) ~= -1 then
				local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
				local ang = matrix:GetAngles()
				pl.rgm.GizmoParent = ang
			else
				pl.rgm.GizmoParent = nil
			end
			pl.rgm.GizmoPos = pos
			pl.rgm.GizmoAng = ang
			pl:rgmSyncClient("GizmoPos")
			pl:rgmSyncClient("GizmoAng")
			pl:rgmSyncClient("GizmoParent")
		else
			pl.rgm.GizmoPos = nil
			pl.rgm.GizmoAng = nil
			pl.rgm.GizmoParent = nil
			pl:rgmSyncClient("GizmoPos")
			pl:rgmSyncClient("GizmoAng")
			pl:rgmSyncClient("GizmoParent")
		end
	end

if SERVER then

	if not self.LastThink then self.LastThink = CurTime() end
	if CurTime() < self.LastThink + self:GetClientNumber("updaterate",0.01) then return end

	local pl = self:GetOwner()
	local ent = pl.rgm.Entity

	local axis = pl.rgm.Axis
	if IsValid(axis) then
		if axis.localizedpos ~= tobool(self:GetClientNumber("localpos",1)) then
			axis.localizedpos = tobool(self:GetClientNumber("localpos",1))
		end
		if axis.localizedang ~= tobool(self:GetClientNumber("localang",1)) then
			axis.localizedang = tobool(self:GetClientNumber("localang",1))
		end
	end

	local moving = pl.rgm.Moving or false
	local rotate = pl.rgm.Rotate or false
	local scale = pl.rgm.Scale or false
	if moving then

		if not IsValid(axis) then return end

		local eyepos,eyeang = rgm.EyePosAng(pl)

		local apart = pl.rgm.MoveAxis
		local bone = pl.rgm.PhysBone

		if not IsValid(ent) then
			pl.rgm.Moving = false
			return
		end

		local physbonecount = ent:GetBoneCount() - 1
		if physbonecount == nil then return end

		if not scale then
			if pl.rgm.IsPhysBone then

				local isik,iknum = rgm.IsIKBone(self,ent,bone)

				local pos,ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir, true)

				local obj = ent:GetPhysicsObjectNum(bone)
				if not isik or iknum == 3 or (rotate and (iknum == 1 or iknum == 2)) then
					obj:EnableMotion(true)
					obj:Wake()
					obj:SetPos(pos)
					obj:SetAngles(ang)
					obj:EnableMotion(false)
					obj:Wake()
				elseif iknum == 2 then
					for k,v in pairs(ent.rgmIKChains) do
						if v.knee == bone then
							local intersect = apart:GetGrabPos(eyepos,eyeang)
							local obj1 = ent:GetPhysicsObjectNum(v.hip)
							local obj2 = ent:GetPhysicsObjectNum(v.foot)
							local kd = (intersect-(obj2:GetPos()+(obj1:GetPos()-obj2:GetPos())))
							kd:Normalize()
							ent.rgmIKChains[k].ikkneedir = kd*1
						end
					end
				end


				local postable = rgm.SetOffsets(self,ent,pl.rgmOffsetTable,{b = bone,p = obj:GetPos(),a = obj:GetAngles()}, pl.rgmAngLocks, pl.rgmPosLocks)

				local sbik,sbiknum = rgm.IsIKBone(self,ent,bone)
				if not sbik or sbiknum ~= 2 then
					postable[bone].dontset = true
				end
				for i=0,ent:GetPhysicsObjectCount()-1 do
					if postable[i] and not postable[i].dontset then
						local obj = ent:GetPhysicsObjectNum(i)
						local poslen = postable[i].pos:Length()
						local anglen = Vector(postable[i].ang.p,postable[i].ang.y,postable[i].ang.r):Length()

						--Temporary solution for INF and NaN decimals crashing the game (Even rounding doesnt fix it)
						if poslen > 2 and anglen > 2 then
							obj:EnableMotion(true)
							obj:Wake()
							obj:SetPos(postable[i].pos)
							obj:SetAngles(postable[i].ang)
							obj:EnableMotion(false)
							obj:Wake()
						end
					end
				end

				-- if not pl:GetNWBool("ragdollmover_keydown") then
				if not pl:KeyDown(IN_ATTACK) then
					if self:GetClientNumber("unfreeze",1) > 0 then
						for i=0,ent:GetPhysicsObjectCount()-1 do
							if pl.rgmOffsetTable[i].moving then
								local obj = ent:GetPhysicsObjectNum(i)
								obj:EnableMotion(true)
								obj:Wake()
							end
						end
					end

					pl.rgm.Moving = false
					pl:rgmSyncOne("Moving")
				end
			else
				local pos, ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir, false, pl.rgm.StartAngle, pl.rgm.NPhysBonePos, pl.rgm.NPhysBoneAng) -- if a bone is not physics one, we pass over "start angle" thing

				ent:ManipulateBoneAngles(bone, ang)
				ent:ManipulateBonePosition(bone, pos)

				if not pl:KeyDown(IN_ATTACK) then -- don't think entity has to be unfrozen if you were working with non phys bones, that would be weird?
					pl.rgm.Moving = false
					pl:rgmSyncOne("Moving")
				end
			end
		else
			bone = pl.rgm.Bone
			local sc, ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir, false, pl.rgm.StartAngle, pl.rgm.NPhysBonePos, pl.rgm.NPhysBoneAng, pl.rgm.NPhysBoneScale)

			ent:ManipulateBoneScale(bone, sc)

			if not pl:KeyDown(IN_ATTACK) then -- don't think entity has to be unfrozen if you were working with non phys bones, that would be weird?
				pl.rgm.Moving = false
				pl:rgmSyncOne("Moving")
			end
		end

	end

	local tr = pl:GetEyeTrace()
	if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_ragdoll" then
		local b = tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone)
		pl.rgm.AimedBone = b
		pl:rgmSyncOne("AimedBone")
	end

	self.LastThink = CurTime()

end

end

if CLIENT then

local BONE_PHYSICAL = 1
local BONE_NONPHYSICAL = 2
local BONE_PROCEDURAL = 3
local BONE_PARENTED = 4

local function GetRecursiveBones(ent, boneid, tab)
	for k, v in ipairs(ent:GetChildBones(boneid)) do
		local bone = {id = v, Type = BONE_NONPHYSICAL, parent = boneid}

		if ent:BoneHasFlag(v, 4) then -- BONE_ALWAYS_PROCEDURAL flag
			bone.Type = BONE_PROCEDURAL
		else
			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local b = ent:TranslatePhysBoneToBone(i)
				if v == b then
					bone.Type = BONE_PHYSICAL
					break
				end
			end
		end

		table.insert(tab, bone)
		GetRecursiveBones(ent, v, tab)
	end
end

local function GetModelName(ent)
	local name = ent:GetModel()
	local splitname = string.Split(name, "/")
	return splitname[#splitname]
end

local function CCheckBox(cpanel,text,cvar)
	local CB = vgui.Create("DCheckBoxLabel",cpanel)
	CB:SetText(text)
	CB:SetConVar(cvar)
	CB:SetDark(true)
	cpanel:AddItem(CB)
	return CB
end
local function CNumSlider(cpanel,text,cvar,min,max,dec)
	local SL = vgui.Create("DNumSlider",cpanel)
	SL:SetText(text)
	SL:SetDecimals(dec)
	SL:SetMinMax(min,max)
	SL:SetConVar(cvar)
	SL:SetDark(true)

	cpanel:AddItem(SL)

	return SL
end
local function CButton(cpanel, text, func, arg)
	local butt = vgui.Create("DButton", cpanel)
	butt:SetText(text)
	function butt:DoClick()
		func(arg)
	end
	cpanel:AddItem(butt)
	return butt
end
local function CCol(cpanel,text)
	local cat = vgui.Create("DCollapsibleCategory",cpanel)
	cat:SetExpanded(1)
	cat:SetLabel(text)
	cpanel:AddItem(cat)
	local col = vgui.Create("DPanelList")
	col:SetAutoSize(true)
	col:SetSpacing(5)
	col:EnableHorizontal(false)
	col:EnableVerticalScrollbar(true)
	col.Paint = function()
		surface.DrawRect(0, 0, 500, 500)
	end
	cat:SetContents(col)
	return col, cat
end
local function CBinder(cpanel)
	local parent = vgui.Create("Panel", cpanel)
	parent:SetHeight(80)
	cpanel:AddItem(parent)

	local bindrot = vgui.Create("DBinder", parent)
	bindrot.Label = vgui.Create("DLabel", parent)
	bindrot:SetConVar("ragdollmover_rotatebutton")
	bindrot:SetSize(100, 50)
	bindrot:SetPos(25, 25)

	bindrot.Label:SetText("#tool.ragdollmover.bindrot")
	bindrot.Label:SetDark(true)
	bindrot.Label:SizeToContents()
	bindrot.Label:SetPos(25, 0)

	function bindrot:OnChange(keycode)
		net.Start("rgmSetToggleRot")
		net.WriteInt(keycode, 32)
		net.SendToServer()
	end

	local bindsc = vgui.Create("DBinder", parent)
	bindsc.Label = vgui.Create("DLabel", parent)
	bindsc:SetConVar("ragdollmover_scalebutton")
	bindsc:SetSize(100, 50)
	bindsc:SetPos(135, 25)

	bindsc.Label:SetText("#tool.ragdollmover.bindscale")
	bindsc.Label:SetDark(true)
	bindsc.Label:SizeToContents()
	bindsc.Label:SetPos(137, 0)

	function bindsc:OnChange(keycode)
		net.Start("rgmSetToggleScale")
		net.WriteInt(keycode, 32)
		net.SendToServer()
	end
end

local function RGMResetBone()
	local pl = LocalPlayer()
	if not pl.rgm then return end
	if not IsValid(pl.rgm.Entity) then return end
	RunConsoleCommand("ragdollmover_resetbone")
end

local function RGMResetScale()
	local pl = LocalPlayer()
	if not pl.rgm then return end
	if not IsValid(pl.rgm.Entity) then return end
	RunConsoleCommand("ragdollmover_resetscale")
end

local function RGMLockPBone(mode)
	local pl = LocalPlayer()
	if not pl.rgm then return end
	if not IsValid(pl.rgm.Entity) or not pl.rgm.IsPhysBone then return end
	net.Start("rgmLockBone")
		net.WriteUInt(mode, 2)
	net.SendToServer()
end

local BonePanel, EntPanel
local LockRotB, LockPosB
local nodes, entnodes
local HoveredBone
local Col4

local function RGMBuildBoneMenu(ent, bonepanel)
	bonepanel:Clear()
	if not IsValid(ent) then return end
	local sortedbones = {}

	local num = ent:GetBoneCount() - 1 -- first we find all rootbones and their children
	for v = 0, num do
		if ent:GetBoneName(v) == "__INVALIDBONE__" then continue end

		if ent:GetBoneParent(v) == -1 then
			local bone = { id = v, Type = BONE_NONPHYSICAL }
			if ent:BoneHasFlag(v, 4) then -- BONE_ALWAYS_PROCEDURAL flag
				bone.Type = BONE_PROCEDURAL
			end

			table.insert(sortedbones, bone)
			local bonesadd = GetRecursiveBones(ent, v, sortedbones)
		end
	end

	nodes = {}

	for k, v in ipairs(sortedbones) do
		local text1 = ent:GetBoneName(v.id)

		if not v.parent then
			nodes[v.id] = bonepanel:AddNode(text1)
		else
			nodes[v.id] = nodes[v.parent]:AddNode(text1)
		end

		nodes[v.id].Type = v.Type
		nodes[v.id]:SetExpanded(true)
		if nodes[v.id].Type == BONE_NONPHYSICAL then
			nodes[v.id]:SetIcon("icon16/connect.png")
			nodes[v.id].Label:SetToolTip("#tool.ragdollmover.nonphysbone")
		elseif nodes[v.id].Type == BONE_PROCEDURAL then
			nodes[v.id]:SetIcon("icon16/error.png")
			nodes[v.id].Label:SetToolTip("#tool.ragdollmover.proceduralbone")
		end

		nodes[v.id].DoClick = function()
			net.Start("rgmSelectBone")
				net.WriteEntity(ent)
				net.WriteUInt(v.id, 32)
			net.SendToServer()
		end

		nodes[v.id].Label.OnCursorEntered = function()
			HoveredBone = v.id
		end

		nodes[v.id].Label.OnCursorExited = function()
			HoveredBone = nil
		end
	end

	net.Start("rgmAskForPhysbones")
		net.WriteEntity(ent)
	net.SendToServer()

	if ent:GetClass() == "ent_bonemerged" then
		net.Start("rgmAskForParented")
			net.WriteEntity(ent)
		net.SendToServer()
	end
end

local function RGMBuildEntMenu(parent, children, entpanel)
	entpanel:Clear()
	if not IsValid(parent) then return end

	entnodes = {}

	entnodes[parent] = entpanel:AddNode(GetModelName(parent))
	entnodes[parent]:SetExpanded(true)

	entnodes[parent].DoClick = function()
		net.Start("rgmSelectEntity")
			net.WriteEntity(parent)
		net.SendToServer()
	end

	for k, v in ipairs(children) do
		entnodes[v] = entnodes[parent]:AddNode(GetModelName(v))

		entnodes[v].DoClick = function()
			net.Start("rgmSelectEntity")
				net.WriteEntity(v)
			net.SendToServer()
		end
	end
end

function TOOL.BuildCPanel(CPanel)

	local Col1 = CCol(CPanel,"#tool.ragdollmover.gizmopanel")
		CCheckBox(Col1,"#tool.ragdollmover.localpos","ragdollmover_localpos")
		CCheckBox(Col1,"#tool.ragdollmover.localang","ragdollmover_localang")
		CNumSlider(Col1,"#tool.ragdollmover.scale","ragdollmover_scale",1.0,50.0,1)
		CCheckBox(Col1,"#tool.ragdollmover.fulldisc","ragdollmover_fulldisc")

	local Col2 = CCol(CPanel,"#tool.ragdollmover.ikpanel")
		CCheckBox(Col2,"#tool.ragdollmover.ik3","ragdollmover_ik_hand_L")
		CCheckBox(Col2,"#tool.ragdollmover.ik4","ragdollmover_ik_hand_R")
		CCheckBox(Col2,"#tool.ragdollmover.ik1","ragdollmover_ik_leg_L")
		CCheckBox(Col2,"#tool.ragdollmover.ik2","ragdollmover_ik_leg_R")

	local Col3 = CCol(CPanel,"#tool.ragdollmover.miscpanel")
		local CB = CCheckBox(Col3,"#tool.ragdollmover.unfreeze","ragdollmover_unfreeze")
		CB:SetToolTip("#tool.ragdollmover.unfreezetip")
		local DisFil = CCheckBox(Col3, "#tool.ragdollmover.disablefilter","ragdollmover_disablefilter")
		DisFil:SetToolTip("#tool.ragdollmover.disablefiltertip")
		CNumSlider(Col3,"#tool.ragdollmover.updaterate","ragdollmover_updaterate",0.01,1.0,2)

	CBinder(CPanel)

	Col4 = CCol(CPanel, "#tool.ragdollmover.bonemanpanel")

		CButton(Col4, "#tool.ragdollmover.resetbone", RGMResetBone)

		CButton(Col4, "#tool.ragdollmover.resetscale", RGMResetScale)

		LockPosB = CButton(Col4, "#tool.ragdollmover.lockpos", RGMLockPBone, 1)
		LockPosB:SetVisible(false)

		LockRotB = CButton(Col4, "#tool.ragdollmover.lockang", RGMLockPBone, 2)
		LockRotB:SetVisible(false)

		local colbones = CCol(Col4, "#tool.ragdollmover.bonelist")
			BonePanel = vgui.Create("DTree", colbones)
			BonePanel:SetTall(600)
			colbones:AddItem(BonePanel)

	local colents = CCol(CPanel, "#tool.ragdollmover.entchildren")

		EntPanel = vgui.Create("DTree", colents)
		EntPanel:SetTall(150)
		EntPanel:SetShowIcons(false)
		colents:AddItem(EntPanel)

end

net.Receive("rgmUpdateLists", function(len)
	local ent = net.ReadEntity()
	local children = {}
	local pl = LocalPlayer()

	for i = 1, net.ReadUInt(32) do
		table.insert(children, net.ReadEntity())
	end

	if IsValid(BonePanel) then
		RGMBuildBoneMenu(ent, BonePanel)
	end
	if IsValid(EntPanel) then
		RGMBuildEntMenu(ent, children, EntPanel)
	end
end)


net.Receive("rgmUpdateBones", function(len)
	local ent = net.ReadEntity()

	if IsValid(BonePanel) then
		RGMBuildBoneMenu(ent, BonePanel)
	end
end)

net.Receive("rgmAskForPhysbonesResponse", function(len)
	local count = net.ReadUInt(8)
	for i = 0, count do
		local bone = net.ReadUInt(32)
		if bone then
			nodes[bone].Type = BONE_PHYSICAL
			nodes[bone]:SetIcon("icon16/brick.png")
			nodes[bone].Label:SetToolTip("#tool.ragdollmover.physbone")
		end
	end
end)

net.Receive("rgmAskForParentedResponse", function(len)
	local count = net.ReadUInt(32)

	for i = 1, count do
		local bone = net.ReadUInt(32)

		if nodes[bone] then
			nodes[bone].Type = BONE_PARENTED
			nodes[bone]:SetIcon("icon16/stop.png")
			nodes[bone].Label:SetToolTip("#tool.ragdollmover.parentedbone")
		end
	end
end)

net.Receive("rgmLockBoneResponse", function(len)
	local boneid = net.ReadUInt(32)
	local poslock = net.ReadBool()
	local anglock = net.ReadBool()

	nodes[boneid].poslock = poslock
	nodes[boneid].anglock = anglock

	if poslock or anglock then
		nodes[boneid]:SetIcon("icon16/lock.png")
		nodes[boneid].Label:SetToolTip("#tool.ragdollmover.lockedbone")
	else
		nodes[boneid]:SetIcon("icon16/brick.png")
		nodes[boneid].Label:SetToolTip("#tool.ragdollmover.physbone")
	end

	if nodes[boneid].poslock then
		LockPosB:SetText("#tool.ragdollmover.unlockpos")
	else
		LockPosB:SetText("#tool.ragdollmover.lockpos")
	end
	if nodes[boneid].anglock then
		LockRotB:SetText("#tool.ragdollmover.unlockang")
	else
		LockRotB:SetText("#tool.ragdollmover.lockang")
	end
end)

net.Receive("rgmSelectBoneResponse", function(len)
	local isphys = net.ReadBool()
	local ent = net.ReadEntity()
	local boneid = net.ReadUInt(32)

	if ent:GetClass() == "prop_ragdoll" and isphys then
		LockPosB:SetVisible(true)
		LockRotB:SetVisible(true)

		if nodes[boneid].poslock then
			LockPosB:SetText("#tool.ragdollmover.unlockpos")
		else
			LockPosB:SetText("#tool.ragdollmover.lockpos")
		end
		if nodes[boneid].anglock then
			LockRotB:SetText("#tool.ragdollmover.unlockang")
		else
			LockRotB:SetText("#tool.ragdollmover.lockang")
		end
	else
		LockPosB:SetVisible(false)
		LockRotB:SetVisible(false)
	end

	BonePanel:SetSelectedItem(nodes[boneid])

	Col4:InvalidateLayout()
end)

function TOOL:DrawHUD()

	local pl = LocalPlayer()
	if not pl.rgm then pl.rgm = {} end

	local ent = pl.rgm.Entity
	local bone = pl.rgm.Bone
	local axis = pl.rgm.Axis
	local moving = pl.rgm.Moving or false
	--We don't draw the axis if we don't have the axis entity or the target entity,
	--or if we're not allowed to draw it.
	if IsValid(ent) and IsValid(axis) and bone then
		local scale = self:GetClientNumber("scale",10)
		local moveaxis = pl.rgm.MoveAxis
		if moving and IsValid(moveaxis) then
			moveaxis:DrawLines(true,scale)
			if moveaxis:GetType() == 3 then
				local intersect = moveaxis:GetGrabPos(rgm.EyePosAng(pl))
				local fwd = (intersect-axis:GetPos())
				fwd:Normalize()
				axis:DrawDirectionLine(fwd,scale,false)
				local dirnorm = pl.rgm.DirNorm or Vector(1,0,0)
				axis:DrawDirectionLine(dirnorm,scale,true)
				axis:DrawAngleText(moveaxis, intersect, pl.rgm.StartAngle)
			end
		else
			axis:DrawLines(scale)
		end
		if collision then return end
	end

	local tr = pl:GetEyeTrace()
	local aimedbone = pl.rgm.AimedBone or 0
	if IsValid(pl.rgm.Entity) and EntityFilter(pl.rgm.Entity) and HoveredBone then
		rgm.DrawBoneName(pl.rgm.Entity,HoveredBone)
	elseif IsValid(tr.Entity) and EntityFilter(tr.Entity) and (not bone or aimedbone ~= bone or tr.Entity ~= pl.rgm.Entity) and not moving then
		rgm.DrawBoneName(tr.Entity,aimedbone)
	end

end

end
