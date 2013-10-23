
ENT.Type = "anim";
ENT.Base = "rgm_axis_base";

function ENT:IsLocked()
	return self:GetNWBool("Locked", false);
end