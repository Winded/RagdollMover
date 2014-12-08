
-- Ragdoll Mover entry point

if SERVER then
	include("rgm/server.lua");
else
	include("rgm/client.lua");
end