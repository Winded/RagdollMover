
function RGM.Draw(ignoreGizmo)

	local player = LocalPlayer();
	local trace = player:GetEyeTrace();
	local rTrace = RGM.Trace(player);

	local axis = RGM.GetGrabbedAxis(player);
	if axis then
		axis:Draw(true);
		return;
	end

	if not rTrace.Axis and IsValid(trace.Entity) and trace.Entity.RGMSkeleton then
		trace.Entity.RGMSkeleton:Draw();
	end

	local entity = RGM.GetSelectedEntity(player);
	if IsValid(entity) and not ignoreGizmo then
		player.RGMGizmo:Draw();
	end

end