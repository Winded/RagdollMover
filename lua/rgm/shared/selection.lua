
function RGM.GetSelectedEntity(player)
	if CLIENT then
		player = LocalPlayer();
	end
	local data = player.RGMData;

	if IsValid(data.SelectedEntity) and data.SelectedBone > 0 then
		return data.SelectedEntity;
	else
		return nil;
	end

end

function RGM.GetSelectedBone(player)

	if CLIENT then
		player = LocalPlayer();
	end
	local data = player.RGMData;
	local entity = data.SelectedEntity;
	local bone = data.SelectedBone;

	if not IsValid(entity) or not entity.RGMSkeleton or bone == 0 then
		return nil;
	end

	if not player.RGMSelectedBone or player.RGMSelectedBone.ID ~= bone then
		player.RGMSelectedBone = table.First(entity.RGMSkeleton.Bones, function(item) return item.ID == bone; end);
	end

	return player.RGMSelectedBone;

end

function RGM.SelectBone(player, entity, bone)

	local data = player.RGMData;

	if not IsValid(entity) then
		data.SelectedEntity = Entity(-1);
		data.SelectedBone = 0;
		return;
	end

	local axis = RGM.GetGrabbedAxis(player);
	if axis then
		RGM.ReleaseAxis(player);
	end

	data.SelectedEntity = entity;
	data.SelectedBone = bone.ID;

end

function RGM.GetGrabbedAxis(player)

	if CLIENT then
		player = LocalPlayer();
	end
	local data = player.RGMData;
	local axis = data.GrabbedAxis;

	if not player.RGMGizmo or axis == 0 then
		return nil;
	end

	if not player.RGMGrabbedAxis or player.RGMGrabbedAxis.ID ~= axis then
		player.RGMGrabbedAxis = table.First(player.RGMGizmo.Axes, function(item) return item.ID == axis; end);
	end

	return player.RGMGrabbedAxis;

end

function RGM.GrabAxis(player, axis)

	if player.RGMData.GrabbedAxis > 0 then
		RGM.ReleaseAxis(player);
	end

	local entity = RGM.GetSelectedEntity(player);
	local bone = RGM.GetSelectedBone(player);
	if not IsValid(entity) or not bone then
		return;
	end

	player.RGMData.GrabbedAxis = axis.ID;

	entity.RGMSkeleton:OnGrab(player, bone);
	axis:OnGrab();

end

function RGM.ReleaseAxis(player)
	local entity = RGM.GetSelectedEntity(player);
	local bone = RGM.GetSelectedBone(player);
	local axis = RGM.GetGrabbedAxis(player);
	if axis then
		entity.RGMSkeleton:OnRelease(player, bone);
		axis:OnRelease();
	end
	player.RGMData.GrabbedAxis = 0;
end