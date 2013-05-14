
AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");
include("shared.lua");

function ENT:Initialize()

	self:SharedInitialize();

end