
-- Because clientside tracing fucks up PhysicsBone result, we need to send the aimed bone to the client. Constant network traffic, yay!

function RGM.GetAimedEntity(player)

	if CLIENT then
		player = LocalPlayer();
	end
	local data = player.RGMData;

	if IsValid(data.AimedEntity) and data.AimedBone > 0 then
		return data.AimedEntity;
	else
		return nil;
	end

end

function RGM.GetAimedBone(player)

	if CLIENT then
		player = LocalPlayer();
	end
	local data = player.RGMData;
	local entity = data.AimedEntity;
	local bone = data.AimedBone;

	if not IsValid(entity) or not entity.RGMSkeleton or bone == 0 then
		return nil;
	end

	if not player.RGMAimedBone or player.RGMAimedBone.ID ~= bone then
		player.RGMAimedBone = table.First(entity.RGMSkeleton.Bones, function(item) return item.ID == bone; end);
	end

	return player.RGMAimedBone;

end

if SERVER then
	
function RGM.PlayerAimTick(player, movedata)

	local trace = RGM.Trace(player);
	local data = player.RGMData;

	if not data then
		return;
	end

	if not trace.Bone then
		data.AimedEntity = Entity(-1);
		data.AimedBone = 0;
	elseif data.AimedBone ~= trace.Bone.ID then
		data.AimedEntity = trace.Entity;
		data.AimedBone = trace.Bone.ID;
	end

end

hook.Add("PlayerTick", "RGMPlayerAimTick", RGM.PlayerAimTick);

end
