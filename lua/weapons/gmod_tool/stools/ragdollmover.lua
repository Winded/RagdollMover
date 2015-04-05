
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

	local entity = RGM.GetSelectedEntity(player);
	local bone = RGM.GetSelectedBone(player);
	local axis = RGM.GetGrabbedAxis(player);
	if IsValid(entity) and bone and axis then
		
		axis:OnGrabUpdate();
		entity.RGMSkeleton:OnMoveUpdate(bone);

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

function TOOL.BuildCPanel(cpanel)

	local data = LocalPlayer().RGMData;

	local scaleLabel = vgui.Create("DLabel", cpanel);
	scaleLabel:SetText("Scale");
	scaleLabel:SizeToContents();
	cpanel:AddItem(scaleLabel);
	local scaleSlider = vgui.Create("Slider", cpanel);
	scaleSlider:SetMinMax(5, 100);
	scaleSlider:SetDecimals(2);
	scaleSlider:SetValue(data.Scale);
	scaleSlider:Bind(data, "Scale", "Number");
	cpanel:AddItem(scaleSlider);

	local unfreezeCB = vgui.Create("DCheckBoxLabel", cpanel);
	unfreezeCB:SetText("Unfreeze on release");
	--unfreezeCB:SizeToContents();
	unfreezeCB:SetChecked(data.Unfreeze);
	unfreezeCB:Bind(data, "Unfreeze", "CheckBox");
	cpanel:AddItem(unfreezeCB);

	local localAxisCB = vgui.Create("DCheckBoxLabel", cpanel);
	localAxisCB:SetText("Local axis");
	--localAxisCB:SizeToContents();
	localAxisCB:SetChecked(data.LocalAxis);
	localAxisCB:Bind(data, "LocalAxis", "CheckBox");
	cpanel:AddItem(localAxisCB);

	local updateRateLabel = vgui.Create("DLabel", cpanel);
	updateRateLabel:SetText("Update rate");
	updateRateLabel:SizeToContents();
	cpanel:AddItem(updateRateLabel);
	local updateRateSlider = vgui.Create("Slider", cpanel);
	updateRateSlider:SetMinMax(0.01, 1);
	updateRateSlider:SetDecimals(2);
	updateRateSlider:SetValue(data.UpdateRate);
	updateRateSlider:Bind(data, "UpdateRate", "Number");
	cpanel:AddItem(updateRateSlider);

end

function TOOL:DrawHUD()
	RGM.Draw();
end

end