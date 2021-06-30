
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
TOOL.ClientConVar["entityholder"] = "some"
TOOL.ClientConVar["entity"] = ""
 

TOOL.ClientConVar["ik_leg_L"] = 0
TOOL.ClientConVar["ik_leg_R"] = 0
TOOL.ClientConVar["ik_hand_L"] = 0
TOOL.ClientConVar["ik_hand_R"] = 0
TOOL.ClientConVar["hipkneeroll"] = 3
TOOL.ClientConVar["ignoredaxis"] = 3

TOOL.ClientConVar["unfreeze"] = 1
TOOL.ClientConVar["updaterate"] = 0.01

TOOL.ClientConVar["rotatebutton"] = MOUSE_MIDDLE

TOOL.ClientConVar["boneidmax"] = 20

TOOL.ClientConVar["boneidmaxholder"] = 20

TOOL.ClientConVar["boneidlabel"] = "root"

TOOL.ClientConVar["boneidlabelholder"] = "root"


RunConsoleCommand("ragdollmover_boneid",0)

local TransTable = {
	"ArrowX", "ArrowY", "ArrowZ",
	"ArrowXY", "ArrowXZ", "ArrowYZ",
	"DiscP", "DiscY", "DiscR"
}

function TOOL:LeftClick(tr)

	if CLIENT then return false end
	
	local pl = self:GetOwner();
	
	if pl.rgm.Moving then return false end
	
	local axis = pl.rgm.Axis;
	if !IsValid(axis) then
		axis = ents.Create("rgm_axis")
		axis:Spawn()
		axis.Owner = pl;
		axis:Setup()
		pl.rgm.Axis = axis;
	end
	
	local collision = axis:TestCollision(pl,self:GetClientNumber("scale",10))
	local ent = pl.rgm.Entity;
	local entstr = tostring(ent)
	RunConsoleCommand("ragdollmover_entity",entstr)
	if collision and IsValid(ent) then
	
		if _G["physundo"] and _G["physundo"].Create then
			_G["physundo"].Create(ent,pl)
		end
		
		local apart = collision.axis
		
		pl.rgmISPos = collision.hitpos*1
		pl.rgmISDir = apart:GetAngles():Forward()
		
		pl.rgmOffsetTable = rgm.GetOffsetTable(self, ent, pl.rgm.Rotate)
		
		pl.rgmOffsetPos = WorldToLocal(apart:GetPos(),apart:GetAngles(),collision.hitpos,apart:GetAngles())
		
		local opos = apart:WorldToLocal(collision.hitpos)
		local obj = ent:GetPhysicsObjectNum(pl.rgm.PhysBone)
		local grabang = apart:LocalToWorldAngles(Angle(0,0,Vector(opos.y,opos.z,0):Angle().y))
		local _p
		if obj == nil then return end
		_p,pl.rgmOffsetAng = WorldToLocal(apart:GetPos(),obj:GetAngles(),apart:GetPos(),grabang)
		
		local dirnorm = (collision.hitpos-axis:GetPos())
		dirnorm:Normalize()
		-- pl:SetNWVector("ragdollmover_dirnorm",dirnorm)
		-- pl:SetNWEntity("ragdollmover_moveaxis",apart)
		-- pl:SetNWBool("ragdollmover_keydown",true)
		-- pl:SetNWBool("ragdollmover_moving",true)
		pl.rgm.DirNorm = dirnorm;
		pl.rgm.MoveAxis = apart;
		pl.rgm.KeyDown = true;
		pl.rgm.Moving = true;
		
		pl:rgmSync();
		
		return false
		
	end
	
	if IsValid(tr.Entity) and (tr.Entity:GetClass() == "prop_ragdoll" or tr.Entity:GetClass() == "prop_physics" or tr.Entity:GetClass() == "prop_effect" ) then
		-- pl:SetNWInt("ragdollmover_physbone",tr.PhysicsBone)
		-- pl:SetNWInt("ragdollmover_bone",tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone))
		pl:SetNWEntity("ragdollmover_ent",tr.Entity)
		-- pl:SetNWBool("ragdollmover_draw",true)
		
		if(self:GetClientNumber("manual",0)==0) then
			pl.rgm.PhysBone = tr.PhysicsBone;
			pl.rgm.Bone = tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone);
		else
			pl.rgm.PhysBone = self:GetClientNumber("boneid",0)
			pl.rgm.Bone = tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone)
		end

		pl.rgm.Entity = tr.Entity;
		pl.rgm.Draw = true;
		
		pl:rgmSync();
	end
	
	return false
end

function TOOL:RightClick(tr)
	-- if self:GetOwner():GetNWBool("ragdollmover_moving",false) then return false end
	-- self:GetOwner():SetNWBool("ragdollmover_rotate",!self:GetOwner():GetNWBool("ragdollmover_rotate",false))
	return false
end

function TOOL:Reload()
	if CLIENT then return false end
	
	local pl = self:GetOwner();
	
	pl.rgm.PhysBone = 0;
	pl.rgm.Bone = 0;
	
	pl:rgmSync();
	
	return false
end


function TOOL:Think()
	if CLIENT then
		if (GetConVarNumber("ragdollmover_boneidmaxholder") ~= GetConVarNumber("ragdollmover_boneidmax")) then
			RunConsoleCommand("ragdollmover_boneidmaxholder", GetConVarNumber("ragdollmover_boneidmax"))

			--ripped from default faceposer
			self:UpdateFaceControlPanel()
	
		elseif (GetConVarString("ragdollmover_entity") ~= GetConVarString("ragdollmover_entityholder")) then
			RunConsoleCommand("ragdollmover_entityholder", GetConVarString("ragdollmover_entity"))

			--ripped from default faceposer
			self:UpdateFaceControlPanel()
	
		end 

	end	

if SERVER then
	

	if !self.LastThink then self.LastThink = CurTime() end
	if CurTime() < self.LastThink + self:GetClientNumber("updaterate",0.01) then return end

	local pl = self:GetOwner()
	local ent = pl.rgm.Entity;

	--[[ physboneid = ent:TranslatePhysBoneToBone(GetConVarNumber("ragdollmover_boneid"))
	RunConsoleCommand("ragdollmover_boneidlabel", ent:GetBoneName(physboneid)) ]]

	local axis = pl.rgm.Axis;
	if IsValid(axis) then
		if axis.localizedpos != tobool(self:GetClientNumber("localpos",1)) then
			axis.localizedpos = tobool(self:GetClientNumber("localpos",1))
		end
		if axis.localizedang != tobool(self:GetClientNumber("localang",1)) then
			axis.localizedang = tobool(self:GetClientNumber("localang",1))
		end
	end
	
	local moving = pl.rgm.Moving or false;
	local rotate = pl.rgm.Rotate or false;
	if moving then
	
		if !IsValid(axis) then return end
		
		local eyepos,eyeang = rgm.EyePosAng(pl)
		
		local apart = pl.rgm.MoveAxis;
		local bone = pl.rgm.PhysBone;
		local ent = pl.rgm.Entity;

		if !IsValid(ent) then
			pl.rgm.Moving = false;
			return
		end
		
		physbonecount = ent:GetPhysicsObjectCount() -1
		if physbonecount == nil then return end

		RunConsoleCommand("ragdollmover_boneidmax", physbonecount)
		
		local isik,iknum = rgm.IsIKBone(self,ent,bone)
		
		local pos,ang = apart:ProcessMovement(pl.rgmOffsetPos,pl.rgmOffsetAng,eyepos,eyeang,ent,bone,pl.rgmISPos,pl.rgmISDir)
		
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

		if postable == nil then return end
		
		local sbik,sbiknum = rgm.IsIKBone(self,ent,bone)
		if !sbik or sbiknum != 2 then
			postable[bone].dontset = true
		end
		for i=0,ent:GetPhysicsObjectCount()-1 do
			if postable[i] and !postable[i].dontset then
				local obj = ent:GetPhysicsObjectNum(i)
				-- postable[i].pos.x = math.Round(postable[i].pos.x,3)
				-- postable[i].pos.y = math.Round(postable[i].pos.y,3)
				-- postable[i].pos.z = math.Round(postable[i].pos.z,3)
				-- postable[i].ang.p = math.Round(postable[i].ang.p,3)
				-- postable[i].ang.y = math.Round(postable[i].ang.y,3)
				-- postable[i].ang.r = math.Round(postable[i].ang.r,3)
				
				local poslen = postable[i].pos:Length();
				local anglen = Vector(postable[i].ang.p,postable[i].ang.y,postable[i].ang.r):Length();
				
				//Temporary solution for INF and NaN decimals crashing the game (Even rounding doesnt fix it)
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
			
			pl.rgm.Moving = false;
			pl:rgmSyncOne("Moving");
		end
		
	end
	
	local tr = pl:GetEyeTrace()
	if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_ragdoll" then
		local b = tr.Entity:TranslatePhysBoneToBone(tr.PhysicsBone);
		pl.rgm.AimedBone = b;
		pl:rgmSyncOne("AimedBone");
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
	return col
end

local function RGM_Update_BoneID(pl,cmd,args,argstr) 
	local num = tostring(args[1])
	RunConsoleCommand("ragdollmover_boneid",num)
end
local function RGMBuildBoneMenu(ent, cpanel)
	if !IsValid(ent) then return end
	local labeltext = GetConVarString("ragdollmover_boneidlabel")
	local num = GetConVarNumber("ragdollmover_boneidmax") 
	for i = 0,num do
		local physbone = ent:TranslatePhysBoneToBone(i)
		local text1 = ent:GetBoneName(physbone)
		local butt = vgui.Create("DButton", cpanel)
		butt:SetText(text1)
		butt:SetConsoleCommand("ragdollmover_updateboneid", i)
		cpanel:AddItem(butt)
		--:AddControl("Button",{text = text1, Command = cmd})
	end
end
concommand.Add( "ragdollmover_updateboneid", RGM_Update_BoneID )


function TOOL.BuildCPanel(CPanel, ent)
	CPanel:AddControl("Header",{Name = "#Tool_ragdollmover_name","#Tool_ragdollmover_desc"})
	
	CPanel:SetSpacing(3)
	
	local Col1 = CCol(CPanel,"Gizmo")
		CCheckBox(Col1,"Localized position gizmo.","ragdollmover_localpos")
		CCheckBox(Col1,"Localized angle gizmo.","ragdollmover_localang")
		CNumSlider(Col1,"Scale","ragdollmover_scale",1.0,50.0,1)
		CCheckBox(Col1,"Fully visible discs.","ragdollmover_fulldisc")
		CCheckBox(Col1,"Manual Bone Picking","ragdollmover_manual")
		CNumSlider(Col1,"BoneID","ragdollmover_boneid",0,GetConVarNumber("ragdollmover_boneidmax"),0)
		
	local Col2 = CCol(CPanel, "Bones")
		RGMBuildBoneMenu(ent, Col2)
		
	local Col3 = CCol(CPanel,"IK Chains")
		CCheckBox(Col3,"Left Hand IK","ragdollmover_ik_hand_L")
		CCheckBox(Col3,"Right Hand IK","ragdollmover_ik_hand_R")
		CCheckBox(Col3,"Left Leg IK","ragdollmover_ik_leg_L")
		CCheckBox(Col3,"Right Leg IK","ragdollmover_ik_leg_R")
	
	local Col4 = CCol(CPanel,"Misc")
		local CB = CCheckBox(Col4,"Unfreeze on release.","ragdollmover_unfreeze")
		CB:SetToolTip("Unfreeze bones that were unfrozen before grabbing the ragdoll.")
		CNumSlider(Col4,"Tool update rate.","ragdollmover_updaterate",0.01,1.0,2)
		-- CCheckBox(Col4, "Use right mouse button.", "ragdollmover_use_rmb");
	
	CPanel:AddControl( "Numpad",	{ Label = "Move/Rotate toggle button",	Command = "ragdollmover_rotatebutton" } )
	-- local B = vgui.Create("DButton", CPanel);
	-- B:SetText("Change button.");
	-- B:SetToolTip("This must be pressed so that the move/rotate button is changed.");
	-- B.DoClick = function() LocalPlayer():ConCommand("ragdollmover_changebutton"); end
	
	//CPanel:SetHeight(500)
end


function TOOL:UpdateFaceControlPanel( index )
	local pl = self:GetOwner()
	local ent = pl.rgm.Entity
	local CPanel = controlpanel.Get( "ragdollmover" )
	if ( !CPanel ) then Msg( "Couldn't find ragdollmover panel!\n" ) return end
	
	CPanel:ClearControls()
	self.BuildCPanel(CPanel, ent)

end

function TOOL:DrawHUD()

	local pl = LocalPlayer()
	if !pl.rgm then pl.rgm = {}; end
	
	-- local ent = pl:GetNWEntity("ragdollmover_ent")
	-- local bone = pl:GetNWInt("ragdollmover_bone",false)
	-- local axis = pl:GetNWEntity("ragdollmover_axis")
	local ent = pl.rgm.Entity;
	local bone = pl.rgm.Bone;
	local axis = pl.rgm.Axis;
	local dodraw = pl.rgm.Draw or false;
	local moving = pl.rgm.Moving or false;
	
	//We don't draw the axis if we don't have the axis entity or the target entity,
	//or if we're not allowed to draw it.
	if IsValid(ent) and IsValid(axis) and bone and dodraw then
		local scale = self:GetClientNumber("scale",10)
		local rotate = pl.rgm.Rotate or false;
		local moveaxis = pl.rgm.MoveAxis;
		if moving and IsValid(moveaxis) then
			moveaxis:DrawLines(true,scale)
			if moveaxis:GetType() == 3 then
				local intersect = moveaxis:GetGrabPos(rgm.EyePosAng(pl))
				local fwd = (intersect-axis:GetPos())
				fwd:Normalize()
				axis:DrawDirectionLine(fwd,scale,false)
				local dirnorm = pl.rgm.DirNorm or Vector(1,0,0);
				axis:DrawDirectionLine(dirnorm,scale,true)
			end
		else
			axis:DrawLines(scale)
		end
		if collision then return end
	end
	
	local tr = pl:GetEyeTrace()
	local aimedbone = pl.rgm.AimedBone or 0;
	if IsValid(tr.Entity) and (tr.Entity:GetClass() == "prop_ragdoll" or tr.Entity:GetClass() == "prop_physics" or tr.Entity:GetClass() == "prop_effect")
	and (!bone or aimedbone != bone) and !moving then
		rgm.DrawBoneName(tr.Entity,aimedbone);
		-- if (!bone or aimedbone != bone) and !pl:GetNWBool("ragdollmover_moving",false) then
			-- local name = tr.Entity:GetBoneName(aimedbone)
			-- local _pos,_ang = tr.Entity:GetBonePosition(aimedbone)
			-- if !_pos or !_ang then
				-- _pos,_ang = tr.Entity:GetPos(),tr.Entity:GetAngles()
			-- end
			-- _pos = _pos:ToScreen()
			-- local textpos = {x = _pos.x+5,y = _pos.y-5}
			-- surface.DrawCircle(_pos.x,_pos.y,2.5,Color(0,0,0,255))
			-- draw.SimpleText(name,"Default",textpos.x,textpos.y,Color(0,0,0,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
		-- end
	end
	
end

end