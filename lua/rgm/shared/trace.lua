
-- Basically same as player:EyePos() and player:EyeAngles() but supports cursor aiming
function RGM.GetEyePosAng(player)
	local eyePos = player:EyePos();
	local aimVector = player:GetAimVector();
	return eyePos, aimVector:Angle();
end

-- Used to trace through gizmo, skeletons and bones
function RGM.Trace(player)

	local results = {};
	local eyePos, eyeAngles = RGM.GetEyePosAng(player);
	local trace = player:GetEyeTrace();

	local entity = trace.Entity;
	if IsValid(entity) then
		results.Entity = entity;
	end

	local gizmo = player.RGMGizmo;
	if not gizmo then
		return results;
	end
	local axis = gizmo:Trace(eyePos, eyeAngles);
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