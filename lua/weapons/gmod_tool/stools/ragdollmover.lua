
TOOL.Name = "Ragdoll Mover"
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

--[[	if phys and 0 <= phys and count > phys then
		physobj = ent:GetPhysicsObjectNum(phys)

		if physobj then
			pl.rgm.IsPhysBone = true
		end
	end]]
	---------------------------------------------------------
	local bonen = phys or bone

	pl.rgm.PhysBone = bonen
	pl.rgm.Bone = bonen
end

if SERVER then

util.AddNetworkString("rgmUpdateBoneList")
util.AddNetworkString("rgmAskForPhysbones")
util.AddNetworkString("rgmAskForPhysbonesResponse")
util.AddNetworkString("rgmSelectBone")

net.Receive("rgmAskForPhysbones", function(len, pl)
	local ent = net.ReadEntity()
	if not IsValid(ent) then return end

	net.Start("rgmAskForPhysbonesResponse")
		local count = ent:GetPhysicsObjectCount() - 1
		net.WriteUInt(count, 8)
		for i = 0, count do
			local bone = ent:TranslatePhysBoneToBone(i)
			if bone == -1 then bone = 0 end
			net.WriteUInt(bone, 32)
		end
	net.Send(pl)
end)

net.Receive("rgmSelectBone", function(len, pl)
	local ent = net.ReadEntity()
	local bone = net.ReadUInt(32)
	RGMGetBone(pl, ent, bone)
	pl:rgmSync()
end)

end

concommand.Add("ragdollmover_resetroot", function(pl)
	pl.rgm.IsPhysBone = true
	pl.rgm.PhysBone = 0
	pl.rgm.Bone = 0
	pl:rgmSync()
end)

concommand.Add("ragdollmover_resetbone", function(pl)
	ent = pl.rgm.Entity
	ent:ManipulateBoneAngles(pl.rgm.Bone, Angle(0, 0, 0))
	ent:ManipulateBonePosition(pl.rgm.Bone, Vector(0, 0, 0))
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
	end
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
		pl.rgm.NPhysBonePos = ent:GetManipulateBonePosition(pl.rgm.Bone)
		pl.rgm.NPhysBoneAng = ent:GetManipulateBoneAngles(pl.rgm.Bone)

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
		pl.rgm.Draw = true

		if not entity.rgmbonecached then -- also taken from locrotscale. some hacky way to cache the bones?
			local p = self.SWEP:GetParent()
			self.SWEP:FollowBone(entity, 0)
			self.SWEP:SetParent(p)
			entity.rgmbonecached = true
		end

		pl.rgm.PhysBone = tr.PhysicsBone
		pl.rgm.Bone = entity:TranslatePhysBoneToBone(tr.PhysicsBone)
		pl.rgm.IsPhysBone = true

		if ent ~= pl.rgm.Entity then
			net.Start("rgmUpdateBoneList")
			net.WriteEntity(pl.rgm.Entity)
			net.Send(pl)
		end

		pl:rgmSync()
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
			pl:rgmSyncClient("GizmoPos")
			pl:rgmSyncClient("GizmoParent")
		else
			pl.rgm.GizmoPos = nil
			pl.rgm.GizmoParent = nil
			pl:rgmSyncClient("GizmoPos")
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


			local postable = rgm.SetOffsets(self,ent,pl.rgmOffsetTable,{b = bone,p = obj:GetPos(),a = obj:GetAngles()})

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

language.Add("tool.ragdollmover.name","Ragdoll Mover")
language.Add("tool.ragdollmover.desc","Allows advanced movement of ragdolls!")
language.Add("tool.ragdollmover.0","Left click to select and move bones. Click with mid mouse button to toggle between move/rotate.")

local BONE_PHYSICAL = 1
local BONE_NONPHYSICAL = 2
local BONE_PROCEDURAL = 3

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

	local bind = vgui.Create("DBinder", parent)
	bind.Label = vgui.Create("DLabel", parent)
	bind:SetConVar("ragdollmover_rotatebutton")
	bind:SetSize(100, 50)
	bind:SetPos(80, 25)

	bind.Label:SetText("Move/Rotate toggle button")
	bind.Label:SetDark(true)
	bind.Label:SizeToContents()
	bind.Label:SetPos(65, 0)

	function bind:OnChange(keycode)
		net.Start("rgmSetToggleKey")
		net.WriteInt(keycode, 32)
		net.SendToServer()
	end
end

local function RGMResetButton(cpanel)
	local pl = LocalPlayer()
	local butt = vgui.Create("DButton", cpanel)
	butt:SetText("Reset Non-Physics Bone")
	function butt:DoClick()
		if not pl.rgm then return end
		if not IsValid(pl.rgm.Entity) then return end
		RunConsoleCommand("ragdollmover_resetbone")
	end
	cpanel:AddItem(butt)
end

local BonePanel
local nodes
local HoveredBone

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
		elseif nodes[v.id].Type == BONE_PROCEDURAL then
			nodes[v.id]:SetIcon("icon16/error.png")
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
end

function TOOL.BuildCPanel(CPanel)

	local Col1 = CCol(CPanel,"Gizmo")
		CCheckBox(Col1,"Localized position gizmo.","ragdollmover_localpos")
		CCheckBox(Col1,"Localized angle gizmo.","ragdollmover_localang")
		CNumSlider(Col1,"Scale","ragdollmover_scale",1.0,50.0,1)
		CCheckBox(Col1,"Fully visible discs.","ragdollmover_fulldisc")

	local Col2 = CCol(CPanel,"IK Chains")
		CCheckBox(Col2,"Left Hand IK","ragdollmover_ik_hand_L")
		CCheckBox(Col2,"Right Hand IK","ragdollmover_ik_hand_R")
		CCheckBox(Col2,"Left Leg IK","ragdollmover_ik_leg_L")
		CCheckBox(Col2,"Right Leg IK","ragdollmover_ik_leg_R")

	local Col3 = CCol(CPanel,"Misc")
		local CB = CCheckBox(Col3,"Unfreeze on release.","ragdollmover_unfreeze")
		CB:SetToolTip("Unfreeze bones that were unfrozen before grabbing the ragdoll.")
		local DisFil = CCheckBox(Col3, "Disable entity filter.","ragdollmover_disablefilter")
		DisFil:SetToolTip("Disable entity filter to select ANY entity. CAUTION - may be buggy")
		CNumSlider(Col3,"Tool update rate.","ragdollmover_updaterate",0.01,1.0,2)

	CBinder(CPanel)

	Col4 = CCol(CPanel, "Bone Manipulation")

		RGMResetButton(Col4)

		local colbones = CCol(Col4, "Bone List")
		BonePanel = vgui.Create("DTree", colbones)
		BonePanel:SetTall(600)

		colbones:AddItem(BonePanel)
		if IsValid(BonePanel) then
			RGMBuildBoneMenu(nil, BonePanel)
		end

end

net.Receive("rgmUpdateBoneList", function(len)
	local ent = net.ReadEntity()
	local pl = LocalPlayer()

	if IsValid(BonePanel) then
		RGMBuildBoneMenu(ent, BonePanel)
	end
end)

net.Receive("rgmAskForPhysbonesResponse", function(len)
	local count = net.ReadUInt(8)

	for i = 0, count do
		local bone = net.ReadUInt(32)
		nodes[bone].Type = BONE_PHYSICAL
		nodes[bone]:SetIcon("icon16/brick.png")
	end
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
		local rotate = pl.rgm.Rotate or false
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
