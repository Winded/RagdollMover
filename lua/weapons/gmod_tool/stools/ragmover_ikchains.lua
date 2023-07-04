
TOOL.Name = "#tool.ragmover_ikchains.name2"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["type"] = 1

if SERVER then

util.AddNetworkString("rgmikMessage")

end

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
	CHAINCLEARED = {id = 3, iserror = false}
}

local function rgmSendNotif(message, pl)
	net.Start("rgmikMessage")
	net.WriteUInt(message,5)
	net.Send(pl)
end

local function RecursionBoneFind(ent, startbone, lookfor)
	local nextbone = rgm.GetPhysBoneParent(ent, startbone)
	if not nextbone then return false end

	if nextbone == lookfor then return true end
	return RecursionBoneFind(ent, nextbone, lookfor)
end

function TOOL:LeftClick(tr)
	if not IsValid(tr.Entity) or tr.Entity:GetClass() ~= "prop_ragdoll" or not tr.PhysicsBone then return false end
	local stage = self:GetStage()

	if stage == 0 then
		self.SelectedEnt = tr.Entity
		self.SelectedHip = tr.PhysicsBone
		self.SelectedKnee = nil
		self:SetStage(1)
		return true
	elseif stage == 1 then
		if tr.Entity ~= self.SelectedEnt then return false end
		if self.SelectedHip == tr.PhysicsBone then
			if SERVER then rgmSendNotif(RGM_NOTIFY.SAME_BONE.id, self:GetOwner()) end
			return false
		end

		self.SelectedKnee = tr.PhysicsBone
		self:SetStage(2)
		return true
	else
		if tr.Entity ~= self.SelectedEnt then return false end
		if self.SelectedHip == tr.PhysicsBone or self.SelectedKnee == tr.PhysicsBone then
			if SERVER then rgmSendNotif(RGM_NOTIFY.SAME_BONE.id, self:GetOwner()) end
			return false
		end

		if RecursionBoneFind(self.SelectedEnt, tr.PhysicsBone, self.SelectedKnee) and RecursionBoneFind(self.SelectedEnt, self.SelectedKnee, self.SelectedHip) then
			if SERVER then rgmSendNotif(RGM_NOTIFY.SUCCESS.id, self:GetOwner()) end
			if not tr.Entity.rgmIKChains then tr.Entity.rgmIKChains = {} end
			local Type = self:GetClientNumber("type",1)
			Type = math.ceil(Type)
			tr.Entity.rgmIKChains[Type] = {hip = self.SelectedHip,knee = self.SelectedKnee,foot = tr.PhysicsBone,type = Type}
			self:SetStage(0)
			self.SelectedHip = nil
			self.SelectedKnee = nil
			return true
		else
			if SERVER then rgmSendNotif(RGM_NOTIFY.BAD_ORDER.id, self:GetOwner()) end
			self:SetStage(0)
			self.SelectedHip = nil
			self.SelectedKnee = nil
			return false
		end
	end
	return false
end

function TOOL:RightClick(tr)
	
end

function TOOL:Reload(tr)
	if self:GetStage() == 0 then
		local Type = self:GetClientNumber("type",1)
		if tr.Entity.rgmIKChains and tr.Entity.rgmIKChains[Type] then
			if SERVER then rgmSendNotif(RGM_NOTIFY.CHAINCLEARED.id, self:GetOwner()) end
			tr.Entity.rgmIKChains[Type] = nil
		end
		return true
	else
		self:SetStage(0)
		self.SelectedHip = nil
		self.SelectedKnee = nil
	end
	return false
end

if SERVER then

function TOOL:Think()
	local tr = self:GetOwner():GetEyeTrace()
	if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_ragdoll" then
		self:GetOwner():SetNWInt("ragdollmoverik_aimedbone",tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone))
	end
end

end

if CLIENT then

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

	LimbSelection(CPanel)

end

function TOOL:DrawHUD()

	local pl = LocalPlayer()

	local tr = pl:GetEyeTrace()
	if IsValid(tr.Entity) and (tr.Entity:GetClass() == "prop_ragdoll") then
		local aimedbone = pl:GetNWInt("ragdollmoverik_aimedbone",0)
		rgm.DrawBoneName(tr.Entity,aimedbone)
	end
--[[	if self:GetStage() > 0 then
		if IsValid(self.SelectedEnt) then
			if self.SelectedHip then
				rgm.DrawBoneName(self.SelectedEnt,self.SelectedEnt:TranslatePhysBoneToBone(self.SelectedHip))
			end
			if self.SelectedKnee then
				rgm.DrawBoneName(self.SelectedEnt,self.SelectedEnt:TranslatePhysBoneToBone(self.SelectedKnee))
			end
		end
	end]]

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

end
