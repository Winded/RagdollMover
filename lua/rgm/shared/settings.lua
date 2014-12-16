
function RGM.GetSettings(player)
	player.RGMSettings = player.RGMSettings or {};
	return player.RGMSettings;
end

if SERVER then

function RGM.SetSetting(player, name, value)

	local settings = RGM.GetSettings(player);
	settings[name] = value;

	net.Start("RGMSettings");
	net.WriteTable({Name = name, Value = value});
	net.Send(player);

end

local function SetScale(player, cmd, args)

	local settings = RGM.GetSettings(player);

	local scale = tonumber(args[1]);
	RGM.SetSetting(player, "Scale", scale);

end

local function SetUnfreeze(player, cmd, args)

	local settings = RGM.GetSettings(player);

	local unfreeze = tobool(args[1]);
	RGM.SetSetting(player, "Unfreeze", unfreeze);

end

local function SetLocalAxis(player, cmd, args)

	local settings = RGM.GetSettings(player);

	local localAxis = tobool(args[1]);
	RGM.SetSetting(player, "LocalAxis", localAxis);

end

local function SetUpdateRate(player, cmd, args)

	local settings = RGM.GetSettings(player);

	local updateRate = tonumber(args[1]);
	RGM.SetSetting(player, "UpdateRate", updateRate);

end

concommand.Add("rgm_scale", SetScale);
concommand.Add("rgm_unfreeze", SetUnfreeze);
concommand.Add("rgm_local_axis", SetLocalAxis);
concommand.Add("rgm_updaterate", SetUpdateRate);
util.AddNetworkString("RGMSettings");

else

net.Receive("RGMSettings", function()

	local player = LocalPlayer();
	local kv = net.ReadTable();

	local settings = RGM.GetSettings(player);
	settings[kv.Name] = kv.Value;

end);

end