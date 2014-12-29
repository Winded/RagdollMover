
-- Ragdoll Mover entry point

include("bivalues/bivalues.lua");

if SERVER then
	include("rgm/server.lua");
else
	include("rgm/client.lua");
end