
RGM.DefaultData = {
	
	Scale = 10,
	Unfreeze = true,
	LocalAxis = true,
	UpdateRate = 0.01,

	SelectedEntity = nil,
	SelectedBone = 0,

	AimedEntity = nil,
	AimedBone = 0,

	GrabbedAxis = 0

};

function RGM.SetupData(player)

	local data = BiValues.New(player, "RGMData", {AutoApply = true, UseSync = true}, RGM.DefaultData);

	return data;

end

if SERVER then
	
hook.Add("PlayerInitialSpawn", "RGMSetup", function(player)

	player.RGMData = RGM.SetupData(player);

end);

else

hook.Add("InitPostEntity", "RGMSetup", function()

	local player = LocalPlayer();

	player.RGMData = RGM.SetupData(player);

end);

end