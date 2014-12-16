

function RGM.SelectBone(player, entity, bone)

	if not IsValid(entity) then
		player.RGMSelectedEntity = nil;
		player.RGMSelectedBone = nil;
		return;
	end

	local axis = player.RGMGrabbedAxis;
	if axis then
		RGM.ReleaseAxis(player);
	end

	player.RGMSelectedEntity = entity;
	player.RGMSelectedBone = bone;

	net.Start("RGMSelectBone");
	net.WriteEntity(entity);
	net.WriteInt(bone.ID, 32);
	net.Send(player);

end

function RGM.SelectBoneClient()

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

function RGM.GrabAxis(player, axis)

	if player.RGMGrabbedAxis then
		player.RGMGrabbedAxis:OnRelease();
		player.RGMGrabbedAxis = nil;
	end

	axis:OnGrab();
	player.RGMGrabbedAxis = axis;

	net.Start("RGMGrabAxis");
	net.WriteInt(axis.ID, 32);
	net.Send(player);

end

function RGM.GrabAxisClient()

	local player = LocalPlayer();
	local gizmo = player.RGMGizmo;
	local axisId = net.ReadInt(32);

	local axis = table.First(gizmo.Axes, function(item) return item.ID == axisId; end);
	player.RGMGrabbedAxis = axis;

end

function RGM.ReleaseAxis(player)
	if player.RGMGrabbedAxis then
		player.RGMGrabbedAxis:OnRelease();
		player.RGMGrabbedAxis = nil;
	end
	net.Start("RGMReleaseAxis");
	net.Send(player);
end

function RGM.ReleaseAxisClient()
	local player = LocalPlayer();
	player.RGMGrabbedAxis = nil;
end

if SERVER then
	util.AddNetworkString("RGMSelectBone");
	util.AddNetworkString("RGMGrabAxis");
	util.AddNetworkString("RGMReleaseAxis");
else
	net.Receive("RGMSelectBone", RGM.SelectBoneClient);
	net.Receive("RGMGrabAxis", RGM.GrabAxisClient);
	net.Receive("RGMReleaseAxis", RGM.ReleaseAxisClient);
end