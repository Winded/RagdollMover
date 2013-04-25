
TOOL.Name = "Rag Mover - IK Chains"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["type"] = "Left Leg"

local ikchains_iktypes = {
	"Left Leg",
	"Right Leg",
	"Left Hand",
	"Right Hand"
}

local function Message(ply,text,icon,sound)
	if SERVER then
		ply:SendLua("GAMEMODE:AddNotify('"..text.."', "..icon..", 5)")
		ply:SendLua("surface.PlaySound('"..sound.."')")
	end
end

function TOOL:LeftClick(tr)
	if !IsValid(tr.Entity) or tr.Entity:GetClass() != "prop_ragdoll" or !tr.PhysicsBone then return false end
	if self:GetStage() == 0 then
		self.SelectedEnt = tr.Entity
		self.SelectedBone = tr.PhysicsBone
		self:SetStage(1)
		return true
	else
		if tr.Entity != self.SelectedEnt then return false end
		local kneebone = rgm.GetPhysBoneParent(tr.Entity,tr.PhysicsBone)
		if rgm.GetPhysBoneParent(tr.Entity,kneebone) == self.SelectedBone then
			if !tr.Entity.rgmIKChains then tr.Entity.rgmIKChains = {} end
			local Type = self:GetClientNumber("type",1)
			Type = math.ceil(Type);
			tr.Entity.rgmIKChains[Type] = {hip = self.SelectedBone,knee = kneebone,foot = tr.PhysicsBone,type = Type}
		else
			Message(self:GetOwner(),"There can be only one knee bone.",1,"buttons/button8.wav")
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

language.Add("tool.ragmover_ikchains.name","Ragdoll Mover - IK Chains")
language.Add("tool.ragmover_ikchains.desc","Make your own IK chains for ragdolls to be used with Ragdoll Mover.")
language.Add("tool.ragmover_ikchains.0","Left click to select IK hip bone.")
language.Add("tool.ragmover_ikchains.1","Now left click again to select foot bone.")

function TOOL.BuildCPanel(CPanel)

	CPanel:AddControl("Header",{Name = "#Tool_ragmover_ikchains_name","#Tool_ragmover_ikchains_desc"})
	
	/*local mc = CPanel:MultiChoice("IK chain type","ragmover_ikchains_type")
	mc:AddChoice("Left Leg")
	mc:AddChoice("Right Leg")
	mc:AddChoice("Left Hand")
	mc:AddChoice("Right Hand")*/
	
	local s = CPanel:NumSlider("IK slot: "..ikchains_iktypes[1],"ragmover_ikchains_type",1,4,0)
	s:SetValue(0)
	s:SetDecimals(0);
	s.ValueChanged = function(self,val)
		self:SetText("IK slot: "..ikchains_iktypes[math.ceil(self:GetValue())])
	end
	
end

function TOOL:DrawHUD()

	local pl = LocalPlayer()
	
	local tr = pl:GetEyeTrace()
	if IsValid(tr.Entity) and (tr.Entity:GetClass() == "prop_ragdoll") then
		local aimedbone = pl:GetNWInt("ragdollmoverik_aimedbone",0)
		rgm.DrawBoneName(tr.Entity,aimedbone);
		-- local name = tr.Entity:GetBoneName(aimedbone)
		-- local _pos,_ang = tr.Entity:GetBonePosition(aimedbone)
		-- if !_pos or !_ang then
			-- _pos,_ang = tr.Entity:GetPos(),tr.Entity:GetAngles()
		-- end
		-- _pos = _pos:ToScreen()
		-- local textpos = {x = _pos.x+5,y = _pos.y-5}
		-- surface.DrawCircle(_pos.x,_pos.y,2.5,Color(0,200,0,255))
		-- draw.SimpleText(name,"Default",textpos.x,textpos.y,Color(0,200,0,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
	end
	
end

end