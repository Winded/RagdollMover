
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

--To be overwritten
function ENT:ProcessMovement(offpos, offang, eyepos, eyeang, norm)
end
