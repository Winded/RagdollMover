
RGM.CanDraw = false;

function RGM.Draw()

	if not RGM.CanDraw then
		return;
	end

	local player = LocalPlayer();
	local trace = player:GetEyeTrace();
	local entity = player.RGMSelectedEntity;

	if player.RGMGrabbedAxis then
		player.RGMGrabbedAxis:Draw(true);
		return;
	end

	if IsValid(entity) then
		player.RGMGizmo:Draw();
	end

	if IsValid(trace.Entity) and trace.Entity.RGMSkeleton then
		trace.Entity.RGMSkeleton:Draw();
	end

end

--hook.Add("PostDrawEffects", "RgmDraw", RGM.Draw);