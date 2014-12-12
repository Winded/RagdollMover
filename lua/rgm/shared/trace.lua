
-- Used to trace through gizmo, skeletons and bones
function RGM.Trace(player)

	local results = {};
	local trace = player:GetEyeTrace();

	local entity = trace.Entity;
	if IsValid(entity) then
		results.Entity = entity;
	end

	local gizmo = player.RGMGizmo;
	local axis = gizmo:Trace(trace);
	if axis then
		results.Axis = axis;
		return results;
	end

	if IsValid(entity) and entity.RGMSkeleton then
		results.Entity = entity;
		results.Skeleton = entity.RGMSkeleton;
		results.Bone = results.Skeleton:Trace(trace);
		return results;
	end

	return results;

end