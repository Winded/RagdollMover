
TOOL.Name = "Ragdoll Mover"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

TOOL.ClientConVar["scale"] = 10;

TOOL.ClientConVar["unfreeze"] = 1;
TOOL.ClientConVar["updaterate"] = 0.01;

TOOL.ClientConVar["rotatebutton"] = MOUSE_MIDDLE;

function TOOL:LeftClick(tr)

	-- Grab the aimed axis

	if CLIENT then return false; end

	local pl = self:GetOwner();

	local m = pl:GetRgmManipulator();

	if m:IsGrabbed() then
		m:Release();
	end

	local grabbed = m:Grab();

	return false;

end

function TOOL:RightClick(tr)

	-- Select bone

	if CLIENT then return false; end

	local pl = self:GetOwner();

	local m = pl:GetRgmManipulator();

	if not m:IsGrabbed() then

		local ent = tr.Entity;
		if not IsValid(ent) then return false; end
		local bone = tr.PhysicsBone;
		if not bone or bone < 0 then return false; end

		local s = ent:GetRgmSkeleton();
		if not IsValid(s) then return false; end
		local n = s:GetNodeForPhysBone(bone);
		if not n then return false; end

		m:SetTarget(n);

	end

	return false;

end

function TOOL:Reload()

	-- Set target to none; hides gizmo

	if CLIENT then return false; end

	self:GetOwner():GetRgmManipulator():ClearTarget();

	return false;

end

function TOOL:Deploy()

	-- Ensure the player has a manipulator,
	-- and enable it.

	if CLIENT then return true; end

	local p = self:GetOwner();
	local m = p:GetRgmManipulator();
	if not IsValid(m) then
		p:CreateRgmManipulator();
	end

	m:Enable();

	return true;

end

function TOOL:Holster()

	-- Disable the manipulator

	if CLIENT then return true; end

	self:GetOwner():GetRgmManipulator():Disable();

	return true;

end

if SERVER then

function TOOL:Think()

	-- Update

	local pl = self:GetOwner();

	local m = pl:GetRgmManipulator();
	if not IsValid(m) then return; end

	m:Update();

	if not pl:KeyDown(IN_ATTACK) then

		m:Release();

	end
	
end

end

if CLIENT then

language.Add("tool.ragdollmover.name", "Ragdoll Mover");
language.Add("tool.ragdollmover.desc", "Allows advanced movement of ragdolls.");
language.Add("tool.ragdollmover.0", "Check the tool menu for instructions.");

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

function TOOL.BuildCPanel(CPanel)
	
	CPanel:AddControl("Header",{Name = "#Tool_ragdollmover_name", "#Tool.ragdollmover.desc"})
	
	CPanel:SetSpacing(3);

	local Colgate = CCol(CPanel, "Instructions");
		local iText =
		[[Help todo.]];
		CLabel(Colgate, iText);
	
	local ColGizmo = CCol(CPanel, "Gizmo");
		CNumSlider(ColGizmo, "Scale", "ragdollmover_scale", 1.0,50.0,1);
	
	local ColMisc = CCol(CPanel, "Misc");
		local CB = CCheckBox(ColMisc, "Unfreeze on release.", "ragdollmover_unfreeze");
		CB:SetToolTip("Unfreeze bones that were unfrozen before grabbing the ragdoll.");
		CNumSlider(ColMisc, "Tool update rate.", "ragdollmover_updaterate", 0.01, 1.0, 2);
	
	CPanel:AddControl( "Numpad", { Label = "Move/Rotate toggle button",	Command = "ragdollmover_rotatebutton" } );

end

function TOOL:DrawHUD()

	-- Render manipulator

	local pl = LocalPlayer();

	local m = pl:GetRgmManipulator();
	if not IsValid(m) then return; end

	m:Render();
	
end

end