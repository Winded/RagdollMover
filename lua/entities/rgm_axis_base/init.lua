
include("shared.lua");
AddCSLuaFile("cl_init.lua");
AddCSLuaFile("shared.lua");

function ENT:Initialize()

	self:SharedInitialize();

	self:SetNetworkedBool("ShouldDraw", false);
	self:SetNetworkedBool("ShouldDrawYellow", false);

end