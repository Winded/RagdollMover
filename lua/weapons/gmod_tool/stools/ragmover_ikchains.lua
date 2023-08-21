
TOOL.Name = "#tool.ragmover_ikchains.name2"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["type"] = 1

local ikchains_iktypes = {
	"tool.ragmover_ikchains.ik1",
	"tool.ragmover_ikchains.ik2",
	"tool.ragmover_ikchains.ik3",
	"tool.ragmover_ikchains.ik4",
	"tool.ragmover_ikchains.ik5",
	"tool.ragmover_ikchains.ik6",
	"tool.ragmover_ikchains.ik7",
	"tool.ragmover_ikchains.ik8",
	"tool.ragmover_ikchains.ik9",
	"tool.ragmover_ikchains.ik10"
}

local RGM_NOTIFY = {
	BAD_ORDER = {id = 0, iserror = true},
	SAME_BONE = {id = 1, iserror = true},
	SUCCESS = {id = 2, iserror = false},
	CHAIN_CLEARED = {id = 3, iserror = false},
	ENT_SELECTED = {id = 4, iserror = false},
	SAVE_SUCCESS = {id = 5, iserror = false},
	SAVE_FAIL = {id = 6, iserror = true},
	LOAD_SUCCESS = {id = 7, iserror = false}
}

local function PrettifyMDLName(name)
	local tablething = string.Explode("/", name)
	name = tablething[#tablething]
	name = string.sub(name, 1, -5)
	return name
end

local function rgmSendNotif(message, pl)
	net.Start("rgmikMessage")
	net.WriteUInt(message,5)
	net.Send(pl)
end

local function rgmSendBone(ent, physbone, pl)
	net.Start("rgmikSendBone")
	net.WriteEntity(ent)
	net.WriteUInt(ent:TranslatePhysBoneToBone(physbone),10)
	net.Send(pl)
end

local function rgmCallReset(pl)
	net.Start("rgmikReset")
	net.Send(pl)
end

local function rgmSendPhysBones(ent)
	local num = ent:GetPhysicsObjectCount()

	net.WriteUInt(num, 10)

	for i = 0, num do
		net.WriteUInt(ent:TranslatePhysBoneToBone(i), 10)

		local parent = rgm.GetPhysBoneParent(ent, i)
		parent = not parent and 1023 or ent:TranslatePhysBoneToBone(parent) -- 512 should be the absolute maximum bone amount, with those .dmx that sfm has
		net.WriteUInt(parent, 10)
	end
end

local function rgmReceivePhysBones()
	local bones = {}

	for i = 0, net.ReadUInt(10) do
		bones[net.ReadUInt(10)] = net.ReadUInt(10)
	end

	return bones
end

local function rgmSendEnt(ent, pl)
	net.Start("rgmikSendEnt")
	net.WriteEntity(ent)
	net.Send(pl)
end

local function RecursionBoneFind(ent, startbone, lookfor)
	local nextbone = rgm.GetPhysBoneParent(ent, startbone)
	if not nextbone then return false end

	if nextbone == lookfor then return true end
	return RecursionBoneFind(ent, nextbone, lookfor)
end

local function RecursionPropFind(startent, lookfor)
	local nextent = startent.rgmPRparent
	if not nextent then return false end

	nextent = startent.rgmPRidtoent[nextent]
	if nextent == lookfor then return true end
	return RecursionPropFind(nextent, lookfor)
end

if SERVER then

util.AddNetworkString("rgmikMessage")
util.AddNetworkString("rgmikAimedBone")
util.AddNetworkString("rgmikSendBone")
util.AddNetworkString("rgmikReset")
util.AddNetworkString("rgmikSendEnt")
util.AddNetworkString("rgmikRequestSave")
util.AddNetworkString("rgmikSave")
util.AddNetworkString("rgmikLoad")


net.Receive("rgmikRequestSave", function(len, pl)
	local tool = pl:GetTool("ragmover_ikchains")
	if not tool then return end

	local ent = tool.SelectedSaveEnt
	if not ent or not ent.rgmIKChains then rgmSendNotif(6, pl) return end

	local ispropragdoll = ent.rgmPRidtoent and true or false

	local num = 0
	local iks = {}

	for type, iktable in pairs(ent.rgmIKChains) do
		num = num + 1
		iks[num] = iktable
	end

	net.Start("rgmikSave")

	net.WriteBool(ispropragdoll)

	net.WriteEntity(ent)
	net.WriteUInt(num,4)

	if not ispropragdoll then
		for i = 1, num do
			net.WriteUInt(iks[i].type, 4)
			net.WriteUInt(ent:TranslatePhysBoneToBone(iks[i].hip), 10)
			net.WriteUInt(ent:TranslatePhysBoneToBone(iks[i].knee), 10)
			net.WriteUInt(ent:TranslatePhysBoneToBone(iks[i].foot), 10)
		end
	else
		for i = 1, num do
			net.WriteUInt(iks[i].type, 4)
			net.WriteUInt(iks[i].hip, 13)
			net.WriteUInt(iks[i].knee, 13)
			net.WriteUInt(iks[i].foot, 13)
		end
	end

	net.Send(pl)
end)

net.Receive("rgmikLoad", function(len, pl)
	local ispropragdoll = net.ReadBool()
	local num = net.ReadUInt(4)
	local iktable = {}

	if not ispropragdoll then
		for i = 1, num do
			iktable[i] = {}
			iktable[i].type = net.ReadUInt(4)
			iktable[i].hip = net.ReadUInt(10)
			iktable[i].knee = net.ReadUInt(10)
			iktable[i].foot = net.ReadUInt(10)
		end
	else
		for i = 1, num do
			iktable[i] = {}
			iktable[i].type = net.ReadUInt(4)
			iktable[i].hip = net.ReadUInt(13)
			iktable[i].knee = net.ReadUInt(13)
			iktable[i].foot = net.ReadUInt(13)
		end
	end

	local tool = pl:GetTool("ragmover_ikchains")
	if not tool then return end

	local ent = tool.SelectedSaveEnt
	if not ent then return end

	if not ispropragdoll then
		ent.rgmIKChains = {}

		for k, ik in ipairs(iktable) do
			if ik.hip == 1023 or ik.knee == 1023 or ik.foot == 1023 then continue end
			table.insert(ent.rgmIKChains, {hip = rgm.BoneToPhysBone(ent, ik.hip), knee = rgm.BoneToPhysBone(ent, ik.knee), foot = rgm.BoneToPhysBone(ent, ik.foot), type = ik.type})
		end
	else
		if not ent.rgmPRidtoent or not ent:GetClass() == "prop_physics" then return end

		for id, ent in pairs(ent.rgmPRidtoent) do
			ent.rgmIKChains = {}

			for k, ik in ipairs(iktable) do
				table.insert(ent.rgmIKChains, {hip = ik.hip, knee = ik.knee, foot = ik.foot, type = ik.type})
			end
		end
	end

	rgmSendNotif(7, pl)
end)

end

function TOOL:LeftClick(tr)
	local ent = tr.Entity
	if not IsValid(ent) or (ent:GetClass() ~= "prop_ragdoll" and not ent.rgmPRenttoid) or not tr.PhysicsBone then return false end
	local stage = self:GetStage()

	if stage == 0 then
		self.IsPropRagdoll = ent.rgmPRenttoid and true or false
		self.SelectedHipEnt = ent
		self.SelectedHip = tr.PhysicsBone
		self.SelectedKneeEnt = nil
		self.SelectedKnee = nil

		if SERVER then
			rgmSendBone(ent, tr.PhysicsBone, self:GetOwner())
		end

		self:SetStage(1)
		return true
	elseif stage == 1 then
		if ent ~= self.SelectedHipEnt and (not ent.rgmPRenttoid or not ent.rgmPRenttoid[self.SelectedHipEnt]) then return false end
		if (not self.IsPropRagdoll and self.SelectedHip == tr.PhysicsBone) or (self.IsPropRagdoll and self.SelectedHipEnt == ent) then
			if SERVER then rgmSendNotif(RGM_NOTIFY.SAME_BONE.id, self:GetOwner()) end
			return false
		end

		self.SelectedKneeEnt = ent
		self.SelectedKnee = tr.PhysicsBone

		if SERVER then
			rgmSendBone(ent, tr.PhysicsBone, self:GetOwner())
		end

		self:SetStage(2)
		return true
	else
		if ent ~= self.SelectedHipEnt and (not ent.rgmPRenttoid or not ent.rgmPRenttoid[self.SelectedHipEnt]) then return false end
		if (not self.IsPropRagdoll and (self.SelectedHip == tr.PhysicsBone or self.SelectedKnee == tr.PhysicsBone)) or (self.IsPropRagdoll and (self.SelectedHipEnt == ent or self.SelectedKneeEnt == ent)) then
			if SERVER then rgmSendNotif(RGM_NOTIFY.SAME_BONE.id, self:GetOwner()) end
			return false
		end

		if not self.IsPropRagdoll and RecursionBoneFind(self.SelectedHipEnt, tr.PhysicsBone, self.SelectedKnee) and RecursionBoneFind(self.SelectedHipEnt, self.SelectedKnee, self.SelectedHip) then
			if SERVER then 
				rgmSendNotif(RGM_NOTIFY.SUCCESS.id, self:GetOwner())
				rgmCallReset(self:GetOwner())
			end

			if not ent.rgmIKChains then ent.rgmIKChains = {} end
			local Type = self:GetClientNumber("type",1)
			ent.rgmIKChains[Type] = {hip = self.SelectedHip,knee = self.SelectedKnee,foot = tr.PhysicsBone,type = Type}

			self:SetStage(0)
			self.SelectedHipEnt = nil
			self.SelectedHip = nil
			self.SelectedKneeEnt = nil
			self.SelectedKnee = nil
			return true
		elseif self.IsPropRagdoll and RecursionPropFind(ent, self.SelectedKneeEnt) and RecursionPropFind(self.SelectedKneeEnt, self.SelectedHipEnt) then
			if SERVER then
				rgmSendNotif(RGM_NOTIFY.SUCCESS.id, self:GetOwner())
				rgmCallReset(self:GetOwner())
			end

			local Type = self:GetClientNumber("type",1)
			local IKTable = {hip = ent.rgmPRenttoid[self.SelectedHipEnt], knee = ent.rgmPRenttoid[self.SelectedKneeEnt], foot = ent.rgmPRenttoid[ent], type = Type}
			for id, ent in pairs(ent.rgmPRidtoent) do
				if not ent.rgmIKChains then ent.rgmIKChains = {} end
				ent.rgmIKChains[Type] = IKTable
			end

			self:SetStage(0)
			self.SelectedHipEnt = nil
			self.SelectedHip = nil
			self.SelectedKneeEnt = nil
			self.SelectedKnee = nil
			return true
		else
			if SERVER then 
				rgmSendNotif(RGM_NOTIFY.BAD_ORDER.id, self:GetOwner())
				rgmCallReset(self:GetOwner())
			end

			self:SetStage(0)
			self.SelectedHipEnt = nil
			self.SelectedHip = nil
			self.SelectedKnee = nil
			self.SelectedKnee = nil
			return false
		end
	end
	return false
end

function TOOL:RightClick(tr)
	local ent = tr.Entity

	if ent:GetClass() == "prop_ragdoll" or (ent:GetClass() == "prop_physics" and ent.rgmPRidtoent) then
		if SERVER then
			if self.SelectedSaveEnt == ent then return false end
			rgmSendEnt(ent, self:GetOwner())
			self.SelectedSaveEnt = ent

			rgmSendNotif(RGM_NOTIFY.ENT_SELECTED.id, self:GetOwner())
		end

		return true
	end

	return false
end

function TOOL:Reload(tr)
	if self:GetStage() == 0 then
		local Type = self:GetClientNumber("type",1)
		if tr.Entity.rgmIKChains and tr.Entity.rgmIKChains[Type] then
			if SERVER then rgmSendNotif(RGM_NOTIFY.CHAIN_CLEARED.id, self:GetOwner()) end
			tr.Entity.rgmIKChains[Type] = nil
		end
		return true
	else
		if SERVER then rgmCallReset(self:GetOwner()) end
		self:SetStage(0)
		self.SelectedHip = nil
		self.SelectedKnee = nil
	end
	return false
end

if SERVER then
local PrevEnt = {}

function TOOL:Think()
	local pl = self:GetOwner()
	local tr = pl:GetEyeTrace()
	if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_ragdoll" then
		net.Start("rgmikAimedBone")
		net.WriteUInt(tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone),10)

		if PrevEnt[pl] ~= tr.Entity then
			net.WriteBool(true)
			rgmSendPhysBones(tr.Entity)
		else
			net.WriteBool(false)
		end

		net.Send(pl)
		PrevEnt[pl] = tr.Entity
	end
end

end

if CLIENT then

local IK_DIR = "rgmik"

local SelectedEntName = "none"
local SelectedEnt = nil
local ChainSavePanel = nil

local function ChainSaver(cpanel)
	local main = vgui.Create("DPanel")
	main:SetTall(45)

	main.selector = vgui.Create("DComboBox", main)

	if not file.Exists(IK_DIR, "DATA") then file.CreateDir(IK_DIR) end
	local files = file.Find(IK_DIR .. "/*.txt", "DATA")
	for k, file in ipairs(files) do
		main.selector:AddChoice(string.sub(file, 1, -5))
	end

	main.save = vgui.Create("DButton", main)
	main.save:SetText("Save")
	main.save.DoClick = function()
		net.Start("rgmikRequestSave")
		net.SendToServer()
	end

	main.load = vgui.Create("DButton", main)
	main.load:SetText("Load")
	main.load.DoClick = function()
		if not SelectedEnt then return end

		local name = main.selector:GetSelected()
		if not name then return end
		if not file.Exists(IK_DIR, "DATA") or not file.Exists(IK_DIR .. "/" .. name .. ".txt", "DATA") then return end

		local json = file.Read(IK_DIR .. "/" .. name .. ".txt", "DATA")
		local iktable = util.JSONToTable(json)

		net.Start("rgmikLoad")
		net.WriteBool(iktable.ispropragdoll)
		net.WriteUInt(#iktable, 4)
		if not iktable.ispropragdoll then
			for k, ik in ipairs(iktable) do
				net.WriteUInt(ik.type, 4)
				net.WriteUInt(SelectedEnt:LookupBone(ik.hip) or 1023, 10)
				net.WriteUInt(SelectedEnt:LookupBone(ik.knee) or 1023, 10)
				net.WriteUInt(SelectedEnt:LookupBone(ik.foot) or 1023, 10)
			end
		else
			for k, ik in ipairs(iktable) do
				net.WriteUInt(ik.type, 4)
				net.WriteUInt(ik.hip, 13)
				net.WriteUInt(ik.knee, 13)
				net.WriteUInt(ik.foot, 13)
			end
		end
		net.SendToServer()
	end

	main.label = vgui.Create("DLabel")
	main.label:SetDark(true)

	main.PerformLayout = function()
		main.selector:SetPos(0,0)
		main.selector:SetSize(main:GetWide(),20)

		main.save:SetPos(0,25)
		main.save:SetSize(main:GetWide()/2 - 20,20)

		main.load:SetPos(main:GetWide()/2 + 20,25)
		main.load:SetSize(main:GetWide()/2 - 20,20)
	end

	main.SetText = function(self, text)
		self.label:SetText("Selected ragdoll: " .. text)
		self.label:SizeToContents()
	end

	main.AddChoice = function(self, option)
		self.selector:AddChoice(option)
	end

	cpanel:AddItem(main)
	cpanel:AddItem(main.label)

	return main
end

local function LimbSelection(cpanel)
	local main = vgui.Create("DPanel")
	main:SetTall(200)

	local buttons = {}

	for k, v in ipairs(ikchains_iktypes) do
		buttons[k] = vgui.Create("DButton", main)

		buttons[k]:SetText("#" .. v)

		buttons[k].DoClick = function()
			RunConsoleCommand("ragmover_ikchains_type", k)
			main.text:SetText(language.GetPhrase("tool.ragmover_ikchains.ikslot") .. " " .. language.GetPhrase(ikchains_iktypes[k]))
		end

		buttons[k].PerformLayout = function(self)
			local x, y, tall

			if (k % 2) ~= 0 then
				x = 0
			else
				x = main:GetWide() / 2 + 5
			end

			if k == 1 or k == 2 then
				y = 55
			elseif k < 5 then
				y = 0
			else
				y = 130 + (math.ceil((k - 4) / 2) - 1)*25
			end

			if k > 4 then
				tall = 20
			else
				tall = 50
			end

			self:SetPos(x,y)
			self:SetSize(main:GetWide() / 2 - 5, tall)
		end
	end

	main.text = vgui.Create("DLabel", cpanel)

	local id = GetConVar("ragmover_ikchains_type"):GetInt() ~= 0 and GetConVar("ragmover_ikchains_type"):GetInt() or 1
	main.text:SetText(language.GetPhrase("tool.ragmover_ikchains.ikslot") .. " " .. language.GetPhrase(ikchains_iktypes[id]))
	main.text:SetDark(true)
	main.text:SizeToContents()

	main.PerformLayout = function(self)
		for k, v in ipairs(ikchains_iktypes) do
			buttons[k]:PerformLayout()
		end
	end

	cpanel:AddItem(main)
	cpanel:AddItem(main.text)
end

function TOOL.BuildCPanel(CPanel)

	ChainSavePanel = ChainSaver(CPanel)
	LimbSelection(CPanel)
	ChainSavePanel:SetText(SelectedEntName)

end

function TOOL:DrawHUD()

	local pl = LocalPlayer()

	local aimedent = pl:GetEyeTrace().Entity

	if IsValid(aimedent) and (aimedent:GetClass() == "prop_ragdoll") then

		if pl.ragdollmoverik_aimedskeleton then
			for bone, pbone in pairs(pl.ragdollmoverik_aimedskeleton) do
				local pos = aimedent:GetBonePosition(bone)
				pos = pos:ToScreen()

				if pbone ~= 1023 then
					local ppos = aimedent:GetBonePosition(pbone)
					ppos = ppos:ToScreen()
					surface.SetDrawColor( 255, 255, 255, 255 )
					surface.DrawLine(ppos.x, ppos.y, pos.x, pos.y)
				end

				surface.DrawCircle(pos.x, pos.y, 2.5, Color(0,200,0,255))
			end
		end

		local aimedbone = pl.ragdollmoverik_aimedbone or 0
		local hipbone, kneebone = pl.ragdollmoverik_hip and pl.ragdollmoverik_hip.bone or 0, pl.ragdollmoverik_knee and pl.ragdollmoverik_knee.bone or 0
		local hipent, kneeent = pl.ragdollmoverik_hip and pl.ragdollmoverik_hip.ent or nil, pl.ragdollmoverik_knee and pl.ragdollmoverik_knee.ent or nil
		if aimedbone ~= hipbone and aimedbone ~= kneebone or aimedent ~= hipent and aimedent ~= kneeent then
			rgm.DrawBoneName(aimedent,aimedbone)
		end

	end

	local iktype = self:GetClientNumber("type",1)
	iktype = ((iktype == 3) or (iktype == 4)) and true or false

	if pl.ragdollmoverik_hip and IsValid(pl.ragdollmoverik_hip.ent) then
		local hipname = iktype and "#tool.ragmover_ikchains.upperarm" or "#tool.ragmover_ikchains.hip"
		rgm.DrawBoneName(pl.ragdollmoverik_hip.ent,pl.ragdollmoverik_hip.bone,hipname)
	end

	if pl.ragdollmoverik_knee and IsValid(pl.ragdollmoverik_knee.ent) then
		local kneename = iktype and "#tool.ragmover_ikchains.elbow" or "#tool.ragmover_ikchains.knee"
		rgm.DrawBoneName(pl.ragdollmoverik_knee.ent,pl.ragdollmoverik_knee.bone,kneename)
	end

end

local function rgmDoNotification(message)
	local MessageTable = {}

	for key, data in pairs(RGM_NOTIFY) do
		if not data.iserror then
			MessageTable[data.id] = function()
				notification.AddLegacy("#tool.ragmover_ikchains.message" .. data.id, NOTIFY_GENERIC, 5)
				surface.PlaySound("buttons/button14.wav")
			end
		else
			MessageTable[data.id] = function()
				notification.AddLegacy("#tool.ragmover_ikchains.message" .. data.id, NOTIFY_ERROR, 5)
				surface.PlaySound("buttons/button10.wav")
			end
		end
	end

	MessageTable[message]()
end

net.Receive("rgmikMessage", function(len)
	local message = net.ReadUInt(5)
	rgmDoNotification(message)
end)

net.Receive("rgmikAimedBone", function(len)
	local pl = LocalPlayer()
	pl.ragdollmoverik_aimedbone = net.ReadUInt(10)

	if net.ReadBool() then
		pl.ragdollmoverik_aimedskeleton = rgmReceivePhysBones()
	end
end)

net.Receive("rgmikSendBone", function(len)
	local ent = net.ReadEntity()
	local bone = net.ReadUInt(10)
	local pl = LocalPlayer()
	local tool = pl:GetTool("ragmover_ikchains")
	if not tool then return end

	local stage = tool:GetStage()
	if stage == 0 then
		pl.ragdollmoverik_hip = { bone = bone, ent = ent }
	elseif stage == 1 then
		pl.ragdollmoverik_knee = { bone = bone, ent = ent }
	end
end)

net.Receive("rgmikReset", function(len)
	local pl = LocalPlayer()
	pl.ragdollmoverik_hip = nil
	pl.ragdollmoverik_knee = nil
end)

net.Receive("rgmikSendEnt", function(len)
	SelectedEnt = net.ReadEntity()
	local pname = PrettifyMDLName(SelectedEnt:GetModel())

	SelectedEntName = "[" .. SelectedEnt:EntIndex() .. "] " .. pname

	if ChainSavePanel then
		ChainSavePanel:SetText(SelectedEntName)
	end
end)

net.Receive("rgmikSave", function(len)
	local iktable = {}
	local ispropragdoll = net.ReadBool()
	local ent = net.ReadEntity()
	local count = net.ReadUInt(4)

	if not ispropragdoll then
		for i = 1, count do
			iktable[i] = {}
			iktable[i].type = net.ReadUInt(4)
			iktable[i].hip = ent:GetBoneName(net.ReadUInt(10))
			iktable[i].knee = ent:GetBoneName(net.ReadUInt(10))
			iktable[i].foot = ent:GetBoneName(net.ReadUInt(10))
		end
	else
		iktable.ispropragdoll = true
		for i = 1, count do
			iktable[i] = {}
			iktable[i].type = net.ReadUInt(4)
			iktable[i].hip = net.ReadUInt(13)
			iktable[i].knee = net.ReadUInt(13)
			iktable[i].foot = net.ReadUInt(13)
		end
	end

	local json = util.TableToJSON(iktable, true)
	if not file.Exists(IK_DIR, "DATA") then file.CreateDir(IK_DIR) end

	local name = PrettifyMDLName(ent:GetModel())
	if file.Exists(IK_DIR .. "/" .. name .. ".txt", "DATA") then
		local exists = true
		local count = 1

		while exists do
			local newname = name .. count

			if not file.Exists(IK_DIR .. "/" .. newname .. ".txt", "DATA") then
				name = newname
				exists = false
			end

			count = count + 1
		end
	end

	file.Write(IK_DIR .. "/" .. name .. ".txt", json)
	ChainSavePanel:AddChoice(name)
	rgmDoNotification(5)
end)

end
