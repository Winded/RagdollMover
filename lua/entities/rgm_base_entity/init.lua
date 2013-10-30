
include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");
	
util.AddNetworkString("rgmEntityMessage");

function ENT:Initialize()

	self:SharedInitialize();

end