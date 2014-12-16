
TOOL.Name = "Ragdoll Mover";
TOOL.Category = "Poser";
TOOL.Command = nil;
TOOL.ConfigName = "";

function TOOL:LeftClick(tr)

	if CLIENT then
		return false;
	end

	local player = self:GetOwner();
	local trace = RGM.Trace(player);

	if trace.Axis then
		RGM.GrabAxis(player, trace.Axis);
		return false;
	end

	if not trace.Bone then
		return false;
	end

	local entity = trace.Entity;
	local bone = trace.Bone;
	RGM.SelectBone(player, entity, bone);

	return false;

end

function TOOL:RightClick(tr)
	local player = self:GetOwner();
	player.RGMGizmo:NextMode();
end

function TOOL:Reload()

	if CLIENT then 
		return false; 
	end

	RGM.Select(nil);

	return false;

end

function TOOL:Deploy()

	-- Since we're not using the tool's own DrawHUD function, we need to let the draw hook know when to draw

	if SERVER then
		return true;
	end

	RGM.CanDraw = true;

	return true;

end

function TOOL:Holster()

	if SERVER then
		return true;
	end

	RGM.CanDraw = false;

	return true;

end

if SERVER then

function TOOL:Think()

	local player = self:GetOwner();

	local trace = self:GetOwner():GetEyeTrace();
	if IsValid(trace.Entity) and not trace.Entity.RGMSkeleton and RGM.Skeleton.CanCreate(trace.Entity) then
		RGM.Skeleton.Create(trace.Entity);
	end

	-- Call update for gizmo

	if not player.RGMGizmo then
		RGM.Gizmo.Create(player);
	end

	if player.RGMGrabbedAxis then
		
		player.RGMGrabbedAxis:OnGrabUpdate();

		if not player:KeyDown(IN_ATTACK) then
			RGM.ReleaseAxis(player);
		end

	end

end

else

function TOOL:Think()
	RGM.CanDraw = true;
end

language.Add("tool.ragdollmover.name", "Ragdoll Mover");
language.Add("tool.ragdollmover.desc", "Allows advanced movement of ragdolls.");
language.Add("tool.ragdollmover.0", "Press 'Help' from tool menu for instructions.");

local function CLabel(cpanel, text)
	local L = vgui.Create("DLabel", cpanel);
	L:SetText(text);
	cpanel:AddItem(L);
	return L;
end
local function CCheckBox(cpanel,text,cvar)
	local CB = vgui.Create("DCheckBoxLabel", cpanel);
	CB:SetText(text);
	CB:SetConVar(cvar);
	cpanel:AddItem(CB);
	return CB;
end
local function CNumSlider(cpanel,text,cvar,min,max,dec)
	local SL = vgui.Create("DNumSlider", cpanel);
	SL:SetText(text);
	SL:SetDecimals(dec);
	SL:SetMinMax(min,max);
	SL:SetConVar(cvar);
	cpanel:AddItem(SL);
	return SL;
end
local function CCol(cpanel,text)
	local cat = vgui.Create("DCollapsibleCategory", cpanel);
	cat:SetExpanded(1);
	cat:SetLabel(text);
	cpanel:AddItem(cat);
	local col = vgui.Create("DPanelList");
	col:SetAutoSize(true);
	col:SetSpacing(5);
	col:EnableHorizontal(false);
	col:EnableVerticalScrollbar(true);
	col.Paint = function()
		surface.SetDrawColor(100, 100, 100, 255);
		surface.DrawRect(0, 0, 500, 500);
	end;
	cat:SetContents(col);
	return col;
end

function TOOL.BuildCPanel(cpanel)

	cpanel:AddControl("Slider", {
		Label = "Scale",
		Command = "rgm_scale",
		Type = "Float",
		Min = 5,
		Max = 100,
		Value = 10
	});

	cpanel:AddControl("CheckBox", {
		Label = "Unfreeze on release",
		Command = "rgm_unfreeze"
	});

	cpanel:AddControl("CheckBox", {
		Label = "Local axis",
		Command = "rgm_local_axis"
	});

	cpanel:AddControl("Slider", {
		Label = "Update rate",
		Command = "rgm_updaterate",
		Type = "Float",
		Min = 0.05,
		Max = 1,
		Value = 0.05
	});

end

function TOOL:DrawHUD()
	RGM.Draw();
end

end