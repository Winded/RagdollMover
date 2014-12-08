
hook.Add("OnEntityCreated", "RGMEntitySetup", function(entity)
	if entity:GetClass() == "prop_ragdoll" or entity:GetClass() == "prop_physics" then
		RGM.Bone.BuildBones(entity);
	end
end);

hook.Add("EntityRemoved", "RGMEntityRemoved", function(entity)
	RGM.Bone.RemoveBones(entity);
end);