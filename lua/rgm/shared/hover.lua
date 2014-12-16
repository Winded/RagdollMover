
-- Because clientside tracing fucks up PhysicsBone result, we need to send the aimed bone to the client. Constant network traffic, yay!

RGM.AimedEntity = nil;
RGM.AimedBone = nil;

if SERVER then
	
function RGM.PlayerAimTick(player, movedata)

	local trace = RGM.Trace(player);

	if RGM.AimedBone ~= trace.Bone then

		local bone;
		if trace.Bone then
			bone = trace.Bone.ID;
		else
			bone = 0;
		end

		net.Start("RGMPlayerAimChange");
		net.WriteTable({
			Entity = trace.Entity,
			Bone = bone
		});
		net.Send(player);

		RGM.AimedBone = trace.Bone;

	end

end

util.AddNetworkString("RGMPlayerAimChange");
hook.Add("PlayerTick", "RGMPlayerAimTick", RGM.PlayerAimTick);

else

function RGM.PlayerAimChange()

	local data = net.ReadTable();

	if data.Bone == 0 then
		RGM.AimedEntity = nil;
		RGM.AimedBone = nil;
		return;
	end

	local skeleton = data.Entity.RGMSkeleton;
	local bone = table.First(skeleton.Bones, function(item) return item.ID == data.Bone; end);
	RGM.AimedEntity = data.Entity;
	RGM.AimedBone = bone;

end

net.Receive("RGMPlayerAimChange", RGM.PlayerAimChange);

end
