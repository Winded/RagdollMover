
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

local BAD_ORDER = 0
local SAME_BONE = 1
local SUCCESS = 2
local CHAIN_CLEARED = 3
local ENT_SELECTED = 4
local SAVE_SUCCESS = 5
local SAVE_FAIL = 6
local LOAD_SUCCESS = 7

local function PrettifyMDLName(name)
	local tablething = string.Explode("/", name)
	name = tablething[#tablething]
	name = string.sub(name, 1, -5)
	return name
end

local function rgmCanTool(ent, pl)
	local cantool

	if CPPI and ent.CPPICanTool then
		cantool = ent:CPPICanTool(pl, "ragmover_ikchains")
	else
		cantool = true
	end

	return cantool
end

local function rgmSendNotif(message, pl)
	net.Start("RAGDOLLMOVER_IK")
		net.WriteUInt(1, 3)
		net.WriteUInt(message, 5)
	net.Send(pl)
end

local function rgmSendBone(ent, physbone, pl)
	net.Start("RAGDOLLMOVER_IK")
		net.WriteUInt(3, 3)
		net.WriteEntity(ent)
		net.WriteUInt(ent:TranslatePhysBoneToBone(physbone), 10)
	net.Send(pl)
end

local function rgmCallReset(pl)
	net.Start("RAGDOLLMOVER_IK")
		net.WriteUInt(4, 3)
	net.Send(pl)
end

local function rgmSendPhysBones(ent)
	local num = ent:GetPhysicsObjectCount()

	net.WriteUInt(num, 6)

	for i = 0, num - 1 do
		net.WriteUInt(ent:TranslatePhysBoneToBone(i), 10)

		local parent = rgm.GetPhysBoneParent(ent, i)
		parent = parent and ent:TranslatePhysBoneToBone(parent) or 1023
		net.WriteUInt(parent, 10)
	end
end

local function rgmReceivePhysBones()
	local bones = {}
	local num = net.ReadUInt(6)

	for i = 0, num - 1 do
		bones[net.ReadUInt(10)] = net.ReadUInt(10)
	end

	return bones
end

local function rgmSendEnt(ent, pl)
	net.Start("RAGDOLLMOVER_IK")
		net.WriteUInt(5, 3)
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

util.AddNetworkString("RAGDOLLMOVER_IK")

local NETFUNC = {
	function(len, pl) -- 	1 (0) - rgmikRequestSave
		local tool = pl:GetTool("ragmover_ikchains")
		if not tool then return end

		local ent = tool.SelectedSaveEnt
		if not IsValid(ent) or not ent.rgmIKChains then rgmSendNotif(6, pl) return end
		if not rgmCanTool(ent, pl) then return end

		local ispropragdoll = ent.rgmPRidtoent and true or false

		local num = 0
		local iks = {}

		for type, iktable in pairs(ent.rgmIKChains) do
			num = num + 1
			iks[num] = iktable
		end

		net.Start("RAGDOLLMOVER_IK")
			net.WriteUInt(6, 3)

			net.WriteBool(ispropragdoll)

			net.WriteEntity(ent)
			net.WriteUInt(num, 4)

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
	end,

	function(len, pl) --		2 (1) - rgmikLoad
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
		if not IsValid(ent) or not rgmCanTool(ent, pl) then return end

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
	end
}

net.Receive("RAGDOLLMOVER_IK", function(len, pl)
	NETFUNC[net.ReadUInt(1) + 1](len, pl)
end)

end

function TOOL:LeftClick(tr)
	local ent = tr.Entity
	if not IsValid(ent) or not rgmCanTool(ent, self:GetOwner()) or (ent:GetClass() ~= "prop_ragdoll" and not ent.rgmPRenttoid) or not tr.PhysicsBone then return false end
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
			if SERVER then rgmSendNotif(SAME_BONE, self:GetOwner()) end
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
			if SERVER then rgmSendNotif(SAME_BONE, self:GetOwner()) end
			return false
		end

		if not self.IsPropRagdoll and RecursionBoneFind(self.SelectedHipEnt, tr.PhysicsBone, self.SelectedKnee) and RecursionBoneFind(self.SelectedHipEnt, self.SelectedKnee, self.SelectedHip) then
			if SERVER then 
				rgmSendNotif(SUCCESS, self:GetOwner())
				rgmCallReset(self:GetOwner())
			end

			if not ent.rgmIKChains then ent.rgmIKChains = {} end
			local Type = self:GetClientNumber("type", 1)
			ent.rgmIKChains[Type] = {hip = self.SelectedHip, knee = self.SelectedKnee, foot = tr.PhysicsBone, type = Type}

			self:SetStage(0)
			self.SelectedHipEnt = nil
			self.SelectedHip = nil
			self.SelectedKneeEnt = nil
			self.SelectedKnee = nil
			return true
		elseif self.IsPropRagdoll and RecursionPropFind(ent, self.SelectedKneeEnt) and RecursionPropFind(self.SelectedKneeEnt, self.SelectedHipEnt) then
			if SERVER then
				rgmSendNotif(SUCCESS, self:GetOwner())
				rgmCallReset(self:GetOwner())
			end

			local Type = self:GetClientNumber("type", 1)
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
				rgmSendNotif(BAD_ORDER, self:GetOwner())
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

	if not rgmCanTool(ent, self:GetOwner()) then return end

	if ent:GetClass() == "prop_ragdoll" or (ent:GetClass() == "prop_physics" and ent.rgmPRidtoent) then
		if SERVER then
			if self.SelectedSaveEnt == ent then return false end
			rgmSendEnt(ent, self:GetOwner())
			self.SelectedSaveEnt = ent

			rgmSendNotif(ENT_SELECTED, self:GetOwner())
		end

		return true
	end

	return false
end

function TOOL:Reload(tr)
	if self:GetStage() == 0 then
		local Type = self:GetClientNumber("type", 1)
		if tr.Entity.rgmIKChains and tr.Entity.rgmIKChains[Type] then
			if SERVER then rgmSendNotif(CHAIN_CLEARED, self:GetOwner()) end
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
		net.Start("RAGDOLLMOVER_IK")
			net.WriteUInt(2, 3)
			net.WriteUInt(tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone), 10)

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

local RGM_NOTIFY = {
	[BAD_ORDER] = true,
	[SAME_BONE] = true,
	[SUCCESS] = false,
	[CHAIN_CLEARED] = false,
	[ENT_SELECTED] = false,
	[SAVE_SUCCESS] = false,
	[SAVE_FAIL] = true,
	[LOAD_SUCCESS] = false
}

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
	main.save:SetText("#tool.ragmover_ikchains.save")
	main.save.DoClick = function()
		net.Start("RAGDOLLMOVER_IK")
			net.WriteUInt(0, 1)
		net.SendToServer()
	end

	main.load = vgui.Create("DButton", main)
	main.load:SetText("#tool.ragmover_ikchains.load")
	main.load.DoClick = function()
		if not SelectedEnt then return end

		local name = main.selector:GetSelected()
		if not name then return end
		if not file.Exists(IK_DIR, "DATA") or not file.Exists(IK_DIR .. "/" .. name .. ".txt", "DATA") then return end

		local json = file.Read(IK_DIR .. "/" .. name .. ".txt", "DATA")
		local iktable = util.JSONToTable(json)

		net.Start("RAGDOLLMOVER_IK")
			net.WriteUInt(1, 1)
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
		main.selector:SetPos(0, 0)
		main.selector:SetSize(main:GetWide(), 20)

		main.save:SetPos(0, 25)
		main.save:SetSize(main:GetWide() / 2 - 20, 20)

		main.load:SetPos(main:GetWide() / 2 + 20, 25)
		main.load:SetSize(main:GetWide() / 2 - 20, 20)
	end

	main.SetText = function(self, text)
		self.label:SetText(language.GetPhrase("#tool.ragmover_ikchains.selectedragdoll") .. " " .. text)
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

		local mceil = math.ceil

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
				y = 130 + (mceil((k - 4) / 2) - 1)*25
			end

			if k > 4 then
				tall = 20
			else
				tall = 50
			end

			self:SetPos(x, y)
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

local PrevEnt = nil
local COLOR_GREEN = RGM_Constants.COLOR_GREEN
local AIMED_SKELETON, AIMED_BONE = nil, nil
local CHOSEN_HIP, CHOSEN_KNEE = nil, nil

function TOOL:DrawHUD()

	local pl = LocalPlayer()

	local aimedent = pl:GetEyeTrace().Entity

	if aimedent == PrevEnt and IsValid(aimedent) and (aimedent:GetClass() == "prop_ragdoll") then

		if AIMED_SKELETON then
			for bone, pbone in pairs(AIMED_SKELETON) do
				local pos = aimedent:GetBonePosition(bone)
				pos = pos:ToScreen()

				if pbone ~= 1023 then
					local ppos = aimedent:GetBonePosition(pbone)
					ppos = ppos:ToScreen()
					surface.SetDrawColor(255, 255, 255, 255)
					surface.DrawLine(ppos.x, ppos.y, pos.x, pos.y)
				end

				surface.DrawCircle(pos.x, pos.y, 2.5, COLOR_GREEN)
			end
		end

		local aimedbone = AIMED_BONE or 0
		local hipbone, kneebone = CHOSEN_HIP and CHOSEN_HIP.bone or 0, CHOSEN_KNEE and CHOSEN_KNEE.bone or 0
		local hipent, kneeent = CHOSEN_HIP and CHOSEN_HIP.ent or nil, CHOSEN_KNEE and CHOSEN_KNEE.ent or nil
		if aimedbone ~= hipbone and aimedbone ~= kneebone or aimedent ~= hipent and aimedent ~= kneeent then
			rgm.DrawBoneName(aimedent, aimedbone)
		end

	else
		PrevEnt = aimedent
	end

	local iktype = self:GetClientNumber("type", 1)
	iktype = ((iktype == 3) or (iktype == 4)) and true or false

	if CHOSEN_HIP and IsValid(CHOSEN_HIP.ent) then
		local hipname = iktype and "#tool.ragmover_ikchains.upperarm" or "#tool.ragmover_ikchains.hip"
		rgm.DrawBoneName(CHOSEN_HIP.ent, CHOSEN_HIP.bone, hipname)
	end

	if CHOSEN_KNEE and IsValid(CHOSEN_KNEE.ent) then
		local kneename = iktype and "#tool.ragmover_ikchains.elbow" or "#tool.ragmover_ikchains.knee"
		rgm.DrawBoneName(CHOSEN_KNEE.ent, CHOSEN_KNEE.bone, kneename)
	end

end

local function rgmDoNotification(message)
	if RGM_NOTIFY[message] == true then
		notification.AddLegacy("#tool.ragmover_ikchains.message" .. message, NOTIFY_ERROR, 5)
		surface.PlaySound("buttons/button10.wav")
	elseif RGM_NOTIFY[message] == false then
		notification.AddLegacy("#tool.ragmover_ikchains.message" .. message, NOTIFY_GENERIC, 5)
		surface.PlaySound("buttons/button14.wav")
	end
end

local NETFUNC = {
	function(len) -- 	1 - rgmikMessage
		local message = net.ReadUInt(5)
		rgmDoNotification(message)
	end,

	function(len) -- 	2 - rgmikAimedBone
		local pl = LocalPlayer()
		AIMED_BONE = net.ReadUInt(10)

		if net.ReadBool() then
			AIMED_SKELETON = rgmReceivePhysBones()
		end
	end,

	function(len) -- 	3 - rgmikSendBone
		local ent = net.ReadEntity()
		local bone = net.ReadUInt(10)
		local pl = LocalPlayer()
		local tool = pl:GetTool("ragmover_ikchains")
		if not tool then return end

		local stage = tool:GetStage()
		if stage == 0 then
			CHOSEN_HIP = {bone = bone, ent = ent}
		elseif stage == 1 then
			CHOSEN_KNEE = {bone = bone, ent = ent}
		end
	end,

	function(len) -- 		4 - rgmikReset
		local pl = LocalPlayer()
		CHOSEN_HIP = nil
		CHOSEN_KNEE = nil
	end,

	function(len) -- 	5 - rgmikSendEnt
		SelectedEnt = net.ReadEntity()
		local pname = PrettifyMDLName(SelectedEnt:GetModel())

		SelectedEntName = "[" .. SelectedEnt:EntIndex() .. "] " .. pname

		if ChainSavePanel then
			ChainSavePanel:SetText(SelectedEntName)
		end
	end,

	function(len) -- 		6 - rgmikSave
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
	end
}

net.Receive("RAGDOLLMOVER_IK", function(len)
	NETFUNC[net.ReadUInt(3)](len)
end)

end
