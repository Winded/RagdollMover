
hook.Add("EntityRemoved", "RGMEntityRemoved", function(entity)
	if entity.RGMSkeleton then
		RGM.Skeleton.Remove(entity.RGMSkeleton);
	end
end);