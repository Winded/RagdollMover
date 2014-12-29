
hook.Add("EntityRemoved", "RGMEntityRemoved", function(entity)

	for _, player in pairs(player.GetAll()) do
		local selected = RGM.GetSelectedEntity(player);
		if IsValid(selected) and selected == entity then
			RGM.SelectBone(player, nil);
		end
	end

	if entity.RGMSkeleton then
		entity.RGMSkeleton:Remove();
	end

end);