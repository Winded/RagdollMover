
hook.Add("EntityRemoved", "RGMEntityRemoved", function(entity)
	RGM.Bone.RemoveBones(entity);
end);