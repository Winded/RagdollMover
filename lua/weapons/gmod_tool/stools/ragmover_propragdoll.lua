TOOL.Name = "#tool.ragmover_propragdoll.name2"
TOOL.Category = "Poser"
TOOL.Command = nil
TOOL.ConfigName = ""

if SERVER then
	duplicator.RegisterEntityModifier("Ragdoll Mover Prop Ragdoll", function(pl, ent, data)

		ent.rgmPRenttoid = table.Copy(data.enttoid)
		ent.rgmPRidtoent = table.Copy(data.idtoent)
		ent.rgmPRparent = data.parent

		ent.rgmOldPostEntityPaste = ent.PostEntityPaste

		ent.PostEntityPaste = function(self, pl, ent, crtEnts)
			if ent.rgmOldPostEntityPaste then
				ent:rgmOldPostEntityPaste(pl, ent, crtEnts)
			end

			if not ent.rgmPRenttoid or not ent.rgmPRidtoent then return end

			for oldent, newent in pairs(crtEnts) do
				local id = ent.rgmPRenttoid[oldent]
				if not id then continue end

				ent.rgmPRidtoent[id] = newent
				ent.rgmPRenttoid[oldent] = nil
				ent.rgmPRenttoid[newent] = id
			end

			local newdata = {}
			newdata.enttoid = {}
			for e, id in pairs(ent.rgmPRenttoid) do
				newdata.enttoid[e:EntIndex()] = id
			end
			newdata.idtoent = table.Copy(ent.rgmPRidtoent)
			newdata.parent = ent.rgmPRparent

			duplicator.ClearEntityModifier(ent, "Ragdoll Mover Prop Ragdoll")
			duplicator.StoreEntityModifier(ent, "Ragdoll Mover Prop Ragdoll", newdata)

			for id, e in pairs(ent.rgmPRidtoent) do
				if type(e) ~= "Entity" or (type(e) == "Entity" and not IsValid(e)) then -- if some of those entities don't exist, then we gotta dissolve the "ragdoll"
					ent.rgmPRidtoent = nil
					ent.rgmPRenttoid = nil
					ent.rgmPRparent = nil
					duplicator.ClearEntityModifier(ent, "Ragdoll Mover Prop Ragdoll")
					break
				end
			end
		end
	end)
end

function TOOL:LeftClick(tr)
	local stage = self:GetStage()
	local ent = tr.Entity

	if ent:GetClass() ~= "prop_physics" then return false end

	if stage == 0 then
		ent.rgmPRidtoent = {}
		ent.rgmPRenttoid = {}
		ent.rgmPRidtoent[0] = ent
		ent.rgmPRenttoid[ent] = 0

		self.idtoent = ent.rgmPRidtoent
		self.enttoid = ent.rgmPRenttoid
		print("One")
		self:SetStage(1)
		return true
	elseif stage == 1 then
		if self.enttoid[ent] then return false end
		self.idtoent[1] = ent
		self.enttoid[ent] = 1

		ent.rgmPRidtoent = self.idtoent
		ent.rgmPRenttoid = self.enttoid
		ent.rgmPRparent = 0
		print("Two")
		self:SetStage(2)
		return true
	
	elseif stage == 2 then
		if self.enttoid[ent] then return false end
		self.idtoent[2] = ent
		self.enttoid[ent] = 2

		ent.rgmPRidtoent = self.idtoent
		ent.rgmPRenttoid = self.enttoid
		ent.rgmPRparent = 1
		print("Three")
		self:SetStage(3)
		return true

	else
		if self.enttoid[ent] then return false end
		self.idtoent[3] = ent
		self.enttoid[ent] = 3

		ent.rgmPRidtoent = self.idtoent
		ent.rgmPRenttoid = self.enttoid
		ent.rgmPRparent = 2
		print("Four")
		self:SetStage(0)

		if SERVER then
			for id, ent in pairs(ent.rgmPRidtoent) do
				local data = {}
				data.idtoent = table.Copy(ent.rgmPRidtoent)
				data.enttoid = {}
				for e, id in pairs(ent.rgmPRenttoid) do
					data.enttoid[e:EntIndex()] = id
				end
				data.parent = ent.rgmPRparent
				duplicator.StoreEntityModifier(ent, "Ragdoll Mover Prop Ragdoll", data)
			end
		end
		self.idtoent = nil
		self.enttoid = nil

		return true
	end

	return false
end

if CLIENT then



end
