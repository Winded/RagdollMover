
TOOL.Name = "#tool.ragmover_ikchains.name2"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["type"] = 1

local ikchains_iktypes = {
	"tool.ragmover_ikchains.ik1",
	"tool.ragmover_ikchains.ik2",
	"tool.ragmover_ikchains.ik3",
	"tool.ragmover_ikchains.ik4"
}

local function Message(ply,text,icon,sound)
	if SERVER then
		ply:SendLua("GAMEMODE:AddNotify('"..text.."', "..icon..", 5)")
		ply:SendLua("surface.PlaySound('"..sound.."')")
	end
end

function TOOL:LeftClick(tr)
	if not IsValid(tr.Entity) or tr.Entity:GetClass() ~= "prop_ragdoll" or not tr.PhysicsBone then return false end
	if self:GetStage() == 0 then
		self.SelectedEnt = tr.Entity
		self.SelectedBone = tr.PhysicsBone
		self:SetStage(1)
		return true
	else
		if tr.Entity ~= self.SelectedEnt then return false end
		local kneebone = rgm.GetPhysBoneParent(tr.Entity,tr.PhysicsBone)
		if rgm.GetPhysBoneParent(tr.Entity,kneebone) == self.SelectedBone then
			if not tr.Entity.rgmIKChains then tr.Entity.rgmIKChains = {} end
			local Type = self:GetClientNumber("type",1)
			Type = math.ceil(Type)
			tr.Entity.rgmIKChains[Type] = {hip = self.SelectedBone,knee = kneebone,foot = tr.PhysicsBone,type = Type}
		else
			Message(self:GetOwner(),"#tool.ragmover_ikchains.error",1,"buttons/button8.wav")
		end
		self:SetStage(0)
		return true
	end
	return false
end

function TOOL:RightClick(tr)
	if self:GetStage() == 0 then
		local Type = self:GetClientNumber("type",1)
		if tr.Entity.rgmIKChains and tr.Entity.rgmIKChains[Type] then
			tr.Entity.rgmIKChains[Type] = nil
		end
		return true
	else
		self:SetStage(0)
		return true
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

function TOOL.BuildCPanel(CPanel)

	local s = CPanel:NumSlider(language.GetPhrase("tool.ragmover_ikchains.ikslot") .. " " .. language.GetPhrase(ikchains_iktypes[1]),"ragmover_ikchains_type",1,4,0)
	s:SetValue(0)
	s.ValueChanged = function(self,val)
		RunConsoleCommand("ragmover_ikchains_type",math.Round(self:GetValue()))
		self:SetText(language.GetPhrase("tool.ragmover_ikchains.ikslot") .. " " .. language.GetPhrase(ikchains_iktypes[math.Round(self:GetValue())]))
	end

end

function TOOL:DrawHUD()

	local pl = LocalPlayer()

	local tr = pl:GetEyeTrace()
	if IsValid(tr.Entity) and (tr.Entity:GetClass() == "prop_ragdoll") then
		local aimedbone = pl:GetNWInt("ragdollmoverik_aimedbone",0)
		rgm.DrawBoneName(tr.Entity,aimedbone)
	end

end

end
