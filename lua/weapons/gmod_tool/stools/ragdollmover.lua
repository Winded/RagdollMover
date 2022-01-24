
TOOL.Name = "Ragdoll Mover"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["localpos"] = 0
TOOL.ClientConVar["localang"] = 1
TOOL.ClientConVar["scale"] = 10
TOOL.ClientConVar["fulldisc"] = 0
TOOL.ClientConVar["manual"] = 0
TOOL.ClientConVar["boneid"] = 0
TOOL.ClientConVar["disablefilter"] = 0
TOOL.ClientConVar["disablechildbone"] = 0
TOOL.ClientConVar["selecteffects"] = 0

TOOL.ClientConVar["ik_leg_L"] = 0
TOOL.ClientConVar["ik_leg_R"] = 0
TOOL.ClientConVar["ik_hand_L"] = 0
TOOL.ClientConVar["ik_hand_R"] = 0
TOOL.ClientConVar["hipkneeroll"] = 3
TOOL.ClientConVar["ignoredaxis"] = 3

TOOL.ClientConVar["unfreeze"] = 0
TOOL.ClientConVar["updaterate"] = 0.01

TOOL.ClientConVar["rotatebutton"] = MOUSE_MIDDLE

RunConsoleCommand("ragdollmover_boneid",0)

if SERVER then

util.AddNetworkString("rgmUpdateBoneList")


end

concommand.Add("ragdollmover_resetroot", function(pl)
	if not tobool(GetConVarNumber("ragdollmover_manual")) then
		pl.rgm.IsPhysBone = true
		pl.rgm.PhysBone = 0
		pl.rgm.Bone = 0
	end
	RunConsoleCommand("ragdollmover_boneid","0")
	pl:rgmSync()
end)

concommand.Add("ragdollmover_resetbone", function(pl)
	ent = pl.rgm.Entity
	ent:ManipulateBoneAngles(pl.rgm.Bone, Angle(0, 0, 0))
	ent:ManipulateBonePosition(pl.rgm.Bone, Vector(0, 0, 0))
end)

local function RGMGetBone(pl, ent, bone)
	--------------------------------------------------------- yeah this part is from locrotscale
	local phys, physobj
	local manual = tobool(GetConVarNumber("ragdollmover_manual"))
	pl.rgm.IsPhysBone = false

	for i = 0, ent:GetPhysicsObjectCount() - 1 do
		local b = ent:TranslatePhysBoneToBone(i)
		if bone == b then 
			phys = i
		end
	end

	local count = ent:GetPhysicsObjectCount()

	if count == 0 then
		phys = -1
	elseif count == 1 then
		if ent:GetBoneCount() <= 1 then
			phys = 0
			pl.rgm.IsPhysBone = true
		end
	end

	if phys and 0 <= phys and count > phys then
		physobj = ent:GetPhysicsObjectNum(phys)

		if physobj then
			pl.rgm.IsPhysBone = true
		end
	end
	---------------------------------------------------------
	if manual and tobool(GetConVarNumber("ragdollmover_selecteffects")) then
		if phys == -1 then phys = nil end
	end
	local bonen = phys or bone

	pl.rgm.PhysBone = bonen
	pl.rgm.Bone = bonen
end

function TOOL:Deploy()
	if SERVER then
		local pl = self:GetOwner()
		local axis = pl.rgm.Axis
		if !IsValid(axis) then
			axis = ents.Create("rgm_axis")
			axis:Spawn()
			axis.Owner = pl
			pl.rgm.Axis = axis
		end
	end
end

function TOOL:LeftClick(tr)

	if CLIENT then return false end

	local pl = self:GetOwner()

	if pl.rgm.Moving then return false end

	local axis = pl.rgm.Axis
	if !IsValid(axis) then
		pl:ChatPrint("Axis entity isn't found. Spawning new one, try selecting the entity again.")
		axis = ents.Create("rgm_axis")
		axis:Spawn()
		axis.Owner = pl
		pl.rgm.Axis = axis
		return false
	end
	if !axis.Axises then
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

	elseif IsValid(tr.Entity) and ( (tr.Entity:GetClass() == "prop_ragdoll" or tr.Entity:GetClass() == "prop_physics" or tr.Entity:GetClass() == "prop_effect" ) or tobool(self:GetClientNumber("disablefilter",0)) and not tr.Entity:IsWorld() ) then
		local entity

		if tobool(self:GetClientNumber("manual",0)) and tobool(self:GetClientNumber("selecteffects",0)) and IsValid(tr.Entity.AttachedEntity) then
			pl.rgm.EffectBase = tr.Entity
			entity = tr.Entity.AttachedEntity
			pl.rgm.Entity = tr.Entity.AttachedEntity
			pl.rgm.Draw = true
		else
			entity = tr.Entity
			pl.rgm.Entity = tr.Entity
			pl.rgm.EffectBase = nil
			pl.rgm.Draw = true
		end

		if not entity.rgmbonecached then -- also taken from locrotscale. some hacky way to cache the bones?
			local p = self.SWEP:GetParent()
			self.SWEP:FollowBone(entity, 0)
			self.SWEP:SetParent(p)
			entity.rgmbonecached = true
		end

		if !tobool(self:GetClientNumber("manual",0)) then
			pl.rgm.PhysBone = tr.PhysicsBone
			pl.rgm.Bone = entity:TranslatePhysBoneToBone(tr.PhysicsBone)
			pl.rgm.IsPhysBone = true
		end

		if ent ~= pl.rgm.Entity then
			net.Start("rgmUpdateBoneList")
			net.WriteEntity(pl.rgm.Entity)
			net.Send(pl)
		end

		if ent ~= pl.rgm.Entity and tobool(self:GetClientNumber("manual",0)) then
			RunConsoleCommand("ragdollmover_resetroot")
		else
			pl:rgmSync()
		end
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
		if !pl.rgm then return end

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

	if !self.LastThink then self.LastThink = CurTime() end
	if CurTime() < self.LastThink + self:GetClientNumber("updaterate",0.01) then return end

	local pl = self:GetOwner()
	local ent = pl.rgm.Entity

	if pl.rgm.Bone ~= GetConVarNumber("ragdollmover_boneid") and tobool(self:GetClientNumber("manual",0)) and IsValid(ent) then
		RGMGetBone(pl, ent, self:GetClientNumber( "boneid",0 ))
		pl:rgmSync()
	end

	local axis = pl.rgm.Axis
	if IsValid(axis) then
		if axis.localizedpos != tobool(self:GetClientNumber("localpos",1)) then
			axis.localizedpos = tobool(self:GetClientNumber("localpos",1))
		end
		if axis.localizedang != tobool(self:GetClientNumber("localang",1)) then
			axis.localizedang = tobool(self:GetClientNumber("localang",1))
		end
	end

	local moving = pl.rgm.Moving or false
	local rotate = pl.rgm.Rotate or false
	if moving then

		if !IsValid(axis) then return end

		local eyepos,eyeang = rgm.EyePosAng(pl)

		local apart = pl.rgm.MoveAxis
		local bone = pl.rgm.PhysBone

		if !IsValid(ent) then
			pl.rgm.Moving = false
			return
		end

		local physbonecount = ent:GetBoneCount() - 1
		if physbonecount == nil then return end

		if pl.rgm.IsPhysBone then

			local isik,iknum = rgm.IsIKBone(self,ent,bone)

			local pos,ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir, true)

			local obj = ent:GetPhysicsObjectNum(bone)
			if !isik or iknum == 3 or (rotate and (iknum == 1 or iknum == 2)) then
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
			if !tobool(self:GetClientNumber("disablechildbone",0)) then

				local sbik,sbiknum = rgm.IsIKBone(self,ent,bone)
				if !sbik or sbiknum != 2 then
					postable[bone].dontset = true
				end
				for i=0,ent:GetPhysicsObjectCount()-1 do
					if postable[i] and !postable[i].dontset then
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
			end

			-- if !pl:GetNWBool("ragdollmover_keydown") then
			if !pl:KeyDown(IN_ATTACK) then
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

			if !pl:KeyDown(IN_ATTACK) then -- don't think entity has to be unfrozen if you were working with non phys bones, that would be weird?
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

local function RGMBuildBoneMenu(ent, bonepanel)
	bonepanel:Clear()
	if not IsValid(ent) then return end
	local num = ent:GetBoneCount() - 1
	for i = 0, num do
		local text1 = ent:GetBoneName(i)
		if text1 == "__INVALIDBONE__" then continue end

		local butt = vgui.Create("DButton", bonepanel)
		butt:SetText(text1)
		butt:Dock(TOP)
		function butt:DoClick() --think making a function to call a console command is better than making another console command... to call another console command
			RunConsoleCommand("ragdollmover_boneid",i)
		end
		bonepanel:AddItem(butt)
	end
end

local BonePanel
local BoneIDSlider

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
		local manual = CCheckBox(Col4,"Manual Bone Picking","ragdollmover_manual")
		manual:SetToolTip("Enable bone selection through the bone menu. Select bone ID and then click on the selected ragdoll to pick that bone.")

		local disableoffset = CCheckBox(Col4, "Disable Child Bone Offset", "ragdollmover_disablechildbone")
		disableoffset:SetToolTip("Disable child bone offset (Example: When you rotate pelvis, angles of other bones will be the same)")

		local effectselect = CCheckBox(Col4, "Select Effects", "ragdollmover_selecteffects")
		effectselect:SetToolTip("MAKE SURE MANUAL BONE PICKING IS ENABLED. Allows you to manipulate bones of the effect props.")

		local colbones = CCol(Col4, "Bone List")
		RGMResetButton(colbones)
		BoneIDSlider = CNumSlider(colbones,"BoneID","ragdollmover_boneid",0,128,0)
		BonePanel = vgui.Create("DScrollPanel", colbones)
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
		BoneIDSlider:SetMinMax(0, ent:GetBoneCount() - 1)
		RGMBuildBoneMenu(ent, BonePanel)
	end
end)

function TOOL:DrawHUD()

	local pl = LocalPlayer()
	if !pl.rgm then pl.rgm = {} end

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
	if IsValid(tr.Entity) and (tr.Entity:GetClass() == "prop_ragdoll" or tr.Entity:GetClass() == "prop_physics" or tr.Entity:GetClass() == "prop_effect")
	and (!bone or aimedbone != bone) and !moving then
		rgm.DrawBoneName(tr.Entity,aimedbone)
	end

end

end
