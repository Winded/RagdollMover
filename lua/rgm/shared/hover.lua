
-- Because clientside tracing fucks up PhysicsBone result, we need to send the aimed bone to the client. Constant network traffic, yay!

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
		RGM.AimedBone = nil;
		return;
	end

	local skeleton = data.Entity.RGMSkeleton;
	local bone = table.First(skeleton.Bones, function(item) return item.ID == data.Bone; end);
	RGM.AimedBone = bone;

end

net.Receive("RGMPlayerAimChange", RGM.PlayerAimChange);

end
