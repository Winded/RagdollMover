include("shared.lua");

AddCSLuaFile("shared.lua");
AddCSLuaFile("cl_init.lua");

---
-- Lock the square axis; this stops the axis from rotating towards the player.
---
function ENT:Lock()
	self:SetNWBool("Locked", true);
end

---
-- Allow the square axis to move.
---
function ENT:Unlock()
	self:SetNWBool("Locked", false);
end

function ENT:Update()

	self.BaseClass.Update(self);

	if not self:IsLocked() then

		local pl = self:GetPlayer();
		local epos, eang = rgm.EyePosAng(pl);

		self:SetAngles(eang);

	end

end

function ENT:UpdatePosition()

	local intersect = self:GetIntersect(self:GetAngles():Forward());

	local offset = self:GetGrabOffset();
	local target = self:GetTarget();

	local localized = self:WorldToLocal(intersect);
	localized.y -= offset.y;
	localized.z -= offset.z;

	local pos = self:LocalToWorld(localized);

	target:SetPos(pos);

end