
RGM.CanDraw = false;

function RGM.Draw()

	if not RGM.CanDraw then
		return;
	end

	local player = LocalPlayer();
	local entity = player.RGMSelectedEntity;

	if not IsValid(entity) or not entity.RGMSkeleton then
		return;
	end

	cam.Start3D(EyePos(), EyeAngles());
	entity.RGMSkeleton:Draw();
	player.RGMGizmo:Draw();
	cam.End3D();

end

hook.Add("PostDrawEffects", "RgmDraw", RGM.Draw);