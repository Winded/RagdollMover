

function RGM.Select(player, entity, bone)

	if not IsValid(entity) then
		player.RGMSelectedEntity = nil;
		player.RGMSelectedBone = nil;
	end

	-- if not player.RGMGizmo then
	-- 	RGM.Gizmo.Create(player);
	-- end
	if not entity.Skeleton then
		RGM.Skeleton.Create(entity);
	end

	local axis = player.RGMGrabbedAxis;
	if axis then
		axis:Release();
	end

	player.RGMSelectedEntity = entity;
	player.RGMSelectedBone = bone;

	net.Start("RGMSelect");
	net.WriteEntity(entity);
	net.WriteInt(bone.ID, 32);
	net.Send(player);

end

function RGM.SelectClient()

	local player = LocalPlayer();
	local entity = net.ReadEntity();
	local boneId = net.ReadInt(32);

	local skeleton = entity.RGMSkeleton;
	local bone = table.First(skeleton.Bones, function(item) return item.ID == boneId; end);
	if not bone then
		error("fuck");
	end

	player.RGMSelectedEntity = entity;
	player.RGMSelectedBone = bone;

end

if SERVER then
	util.AddNetworkString("RGMSelect");
else
	net.Receive("RGMSelect", RGM.SelectClient);
end