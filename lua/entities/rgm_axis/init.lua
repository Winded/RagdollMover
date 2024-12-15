
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

local VECTOR_ORIGIN = vector_origin
local VECTOR_FRONT = RGM_Constants.VECTOR_FRONT
local ANGLE_DISC = Angle(0, 90, 0)
local ANGLE_ARROW_OFFSET = Angle(0, 90, 90)

-- How much player's velocity should influence collision bound
local PLAYER_WEIGHT = 0.5
-- How much gizmo's own velocity should influence collision bound
local GIZMO_WEIGHT = 1000

function ENT:Think()
	local pl = self.Owner
	local size = self.DefaultMinMax
	-- Extend the collision bounds to include us, with some velocity tracking to ensure that the gizmo updates as much as possible outside of the world
	if not util.IsInWorld(self:GetPos()) then
		local velocity = (self:GetPos() - self.LastPos) / CurTime()
		size = 2 * (pl:GetPos() - self:GetPos()) + (PLAYER_WEIGHT * pl:GetVelocity() + GIZMO_WEIGHT * velocity)
	end
	-- Only set the collision bounds if it differs from our last size.
	if self.LastSize ~= size then
		self:SetCollisionBounds(-1 * size, size)
		self.LastSize = size
	end
	self.LastPos = self:GetPos()

	if not IsValid(pl) then return end

	local plTable = RAGDOLLMOVER[pl]
	local ent = plTable.Entity
	local bone = plTable.PhysBone
	if not IsValid(ent) or not plTable.Bone or not self.Axises then return end
	local parent = ent:GetParent()

	if plTable.GizmoParentID and plTable.GizmoParentID ~= -1 and plTable.GizmoParent then
		local ent = ent
		if self.EntAdvMerged then
			if not IsValid(parent) then return end
			ent = parent
			if ent.AttachedEntity then ent = ent.AttachedEntity end
		end
		local physobj = ent:GetPhysicsObjectNum(plTable.GizmoParentID)
		if physobj then
			_, self.GizmoParent = LocalToWorld(vector_origin, plTable.GizmoParent, physobj:GetPos(), physobj:GetAngles())
		else
			return
		end
	elseif plTable.GizmoParent then
		_, self.GizmoParent = LocalToWorld(vector_origin, plTable.GizmoParent, ent:GetPos(), ent:GetAngles())
	else
		self.GizmoParent = angle_zero
	end

	local advbones = nil
	if ent:GetClass() == "ent_advbonemerge" then
		advbones = ent.AdvBone_BoneInfo
	end

	local pos, ang
	local rotate = plTable.Rotate or false
	local scale = plTable.Scale or false
	local offset, offsetlocal = plTable.GizmoOffset, self.localoffset

	if IsValid(parent) and plTable.Bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not ent:IsEffectActive(EF_FOLLOWBONE) and not (ent:GetClass() == "prop_ragdoll") then
		pos = parent:LocalToWorld(ent:GetLocalPos())
	elseif plTable.IsPhysBone then

		local physobj = ent:GetPhysicsObjectNum(bone)
		if physobj == nil then return end
		pos = physobj:GetPos()

	else
		bone = plTable.Bone
		if not self.GizmoPos or not self.GizmoAng then
			return
		else
			if self.EntAdvMerged then
				local parent = parent
				if parent.AttachedEntity then parent = parent.AttachedEntity end

				if plTable.GizmoParentID ~= -1 then
					local physobj = parent:GetPhysicsObjectNum(plTable.GizmoParentID)
					pos = LocalToWorld(self.GizmoPos, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					pos = LocalToWorld(self.GizmoPos, self.GizmoAng, parent:GetPos(), parent:GetAngles())
				end
			elseif plTable.GizmoParentID then
				if plTable.GizmoParentID ~= -1 then
					local physobj = ent:GetPhysicsObjectNum(plTable.GizmoParentID)
					pos = LocalToWorld(self.GizmoPos, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					pos = LocalToWorld(self.GizmoPos, self.GizmoAng, ent:GetPos(), ent:GetAngles())
				end
			else
				pos = self.GizmoPos
			end
			
		end
	end


	if IsValid(parent) and plTable.Bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not ent:IsEffectActive(EF_FOLLOWBONE) and not (ent:GetClass() == "prop_ragdoll") and not scale then
		ang = parent:LocalToWorldAngles(ent:GetLocalAngles())
	elseif plTable.IsPhysBone and not scale then

		local physobj = ent:GetPhysicsObjectNum(bone)
		if physobj == nil then return end
		ang = physobj:GetAngles()

	else
		if rotate then
			if self.EntAdvMerged then
				local parent = parent
				if parent.AttachedEntity then parent = parent.AttachedEntity end
				if plTable.GizmoParentID ~= -1 then
					local physobj = parent:GetPhysicsObjectNum(plTable.GizmoParentID)
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, parent:GetPos(), parent:GetAngles())
				end
			elseif ent:GetBoneParent(bone) ~= -1 then
				if not plTable.GizmoParent then -- dunno if there is a need for these failsafes
					_ , ang = ent:GetBonePosition(bone)
				else
					if not (ent:GetClass() == "prop_physics") then -- for some reason physics props update their angles serverside on nonphys bones, ragdolls and dynamic props don't. do any other entities do that?
						local _ , pang = ent:GetBonePosition(ent:GetBoneParent(bone))
						_ , ang = ent:GetBonePosition(bone)

						local _, diff = WorldToLocal(vector_origin, ang, vector_origin, pang)
						_, ang = LocalToWorld(vector_origin, diff, vector_origin, self.GizmoParent)
					else
						local manang = ent:GetManipulateBoneAngles(bone)*1
						manang:Normalize()
						_, ang = ent:GetBonePosition(bone)

						_, ang = LocalToWorld(vector_origin, Angle(0, 0, -manang[3]), vector_origin, ang)
						_, ang = LocalToWorld(vector_origin, Angle(-manang[1], 0, 0), vector_origin, ang)
						_, ang = LocalToWorld(vector_origin, Angle(0, -manang[2], 0), vector_origin, ang)
					end
				end
			else
				if plTable.GizmoParentID ~= -1 then
					local physobj = ent:GetPhysicsObjectNum(plTable.GizmoParentID)
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, ent:GetPos(), ent:GetAngles())
				end

				local manang = ent:GetManipulateBoneAngles(bone)*1
				manang:Normalize()

				_, ang = LocalToWorld(vector_origin, Angle(0, 0, -manang[3]), vector_origin, ang)
				_, ang = LocalToWorld(vector_origin, Angle(-manang[1], 0, 0), vector_origin, ang)
				_, ang = LocalToWorld(vector_origin, Angle(0, -manang[2], 0), vector_origin, ang)
			end
		elseif scale then
			if plTable.GizmoParentID then
				local funent = ent
				if self.EntAdvMerged then
					funent = parent
					if funent.AttachedEntity then funent = funent.AttachedEntity end
				end
				if plTable.GizmoParentID ~= -1 then
					local physobj = funent:GetPhysicsObjectNum(plTable.GizmoParentID)
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, funent:GetPos(), funent:GetAngles())
				end
				if self.EntAdvMerged then
					_, ang = LocalToWorld(vector_origin, ent:GetManipulateBoneAngles(bone), vector_origin, ang)
				end
			else
				ang = self.GizmoAng
			end
		else
			if self.EntAdvMerged then
				local parent = parent
				if parent.AttachedEntity then parent = parent.AttachedEntity end
				if plTable.GizmoParentID ~= -1 then
					local physobj = parent:GetPhysicsObjectNum(plTable.GizmoParentID)
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, parent:GetPos(), parent:GetAngles())
				end
			elseif ent:GetBoneParent(bone) ~= -1 then
				if not plTable.GizmoParent then
					local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone)) -- never would have guessed that when moving bones they use angles of their parent bone rather than their own angles. happened to get to know that after looking at vanilla bone manipulator!
					ang = matrix:GetAngles()
				else
					ang = self.GizmoParent
				end
			else
				if IsValid(ent) then
					if plTable.GizmoParentID ~= -1 then
						local physobj = ent:GetPhysicsObjectNum(plTable.GizmoParentID)
						_, ang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
					else
						_, ang = LocalToWorld(vector_origin, self.GizmoAng, ent:GetPos(), ent:GetAngles())
					end
				end
			end
		end
	end

	if not plTable.Moving or not rotate then
		local entoffset = VECTOR_ORIGIN
		if not scale and ent.rgmPRoffset and plTable.IsPhysBone then
			entoffset = ent.rgmPRoffset
		end

		if offsetlocal then 
			if IsValid(parent) and plTable.Bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not ent:IsEffectActive(EF_FOLLOWBONE) and not (ent:GetClass() == "prop_ragdoll") then
				self:SetPos(LocalToWorld(offset + entoffset, angle_zero, pos, parent:LocalToWorldAngles(ent:GetLocalAngles())))
			else
				if self.EntAdvMerged then
					local funent = parent
					if funent.AttachedEntity then funent = funent.AttachedEntity end
					local offsetang

					if plTable.GizmoParentID ~= -1 then
						local physobj = funent:GetPhysicsObjectNum(plTable.GizmoParentID)
						_, offsetang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
					else
						_, offsetang = LocalToWorld(vector_origin, self.GizmoAng, funent:GetPos(), funent:GetAngles())
					end

					_, offsetang = LocalToWorld(vector_origin, ent:GetManipulateBoneAngles(bone), vector_origin, offsetang)

					self:SetPos(LocalToWorld(offset + entoffset, angle_zero, pos, offsetang))
				elseif plTable.IsPhysBone then
					self:SetPos(LocalToWorld(offset + entoffset, angle_zero, pos, ang))
				else
					local offsetang
					if plTable.GizmoParentID then
						local ent = ent
						if self.EntAdvMerged then
							ent = parent
							if ent.AttachedEntity then ent = ent.AttachedEntity end
						end
						if plTable.GizmoParentID ~= -1 then
							local physobj = ent:GetPhysicsObjectNum(plTable.GizmoParentID)
							_, offsetang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
						else
							_, offsetang = LocalToWorld(vector_origin, self.GizmoAng, ent:GetPos(), ent:GetAngles())
						end
					else
						offsetang = self.GizmoAng
					end
					self:SetPos(LocalToWorld(offset + entoffset, angle_zero, pos, offsetang))
				end
			end
		else
			if ent.rgmPRoffset then
				entoffset = LocalToWorld(entoffset, angle_zero, pos, ang)
				entoffset = entoffset - pos
			end
			self:SetPos(pos + offset + entoffset)
		end
	end

	local localstate = self.localpos
	if rotate then 
		localstate = self.localang
	end

	if not plTable.Moving then -- Prevent whole thing from rotating when we do localized rotation - needed for proper angle reading
		if localstate or scale or (not plTable.IsPhysBone and rotate) then -- Non phys bones don't go well with world coordinates.
			local moveang = ang
			if not scale and ent.rgmPRaoffset and plTable.IsPhysBone then
				_, moveang = LocalToWorld(vector_origin, ent.rgmPRaoffset, vector_origin, ang or angle_zero)
			end
			self:SetAngles(moveang)
			if not plTable.IsPhysBone then
				local manipang = ent:GetManipulateBoneAngles(bone)
				self.DiscP.LocalAng = Angle(0, 90 + manipang.y, 0) -- Pitch follows Yaw angles
				self.DiscR.LocalAng = Angle(0 + manipang.x, 0 + manipang.y, 0) -- Roll follows Pitch and Yaw angles
			else
				self.DiscP.LocalAng = ANGLE_DISC
				self.DiscR.LocalAng = angle_zero
			end
		else
			self:SetAngles(angle_zero)
			self.DiscP.LocalAng = ANGLE_DISC
			self.DiscR.LocalAng = angle_zero
		end
		self.LocalAngles = ang
		self.BonePos = pos
		self.NMBonePos = LocalToWorld(-ent:GetManipulateBonePosition(bone), angle_zero, pos, self.GizmoParent)
	end

	local viewent = pl:GetViewEntity()
	local pos, poseye = self:GetPos(), pl:EyePos()

	if IsValid(viewent) and viewent ~= pl then
		poseye = viewent:GetPos()
	end

	local disc = self.DiscLarge
	local ang = (pos - poseye):Angle()
	ang = self:WorldToLocalAngles(ang)
	disc.LocalAng = ang
	self.ArrowOmni.LocalAng = ang

	if not plTable.Moving then
		pos, poseye = self:WorldToLocal(pos), self:WorldToLocal(poseye)
		local xangle, yangle = (Vector(pos.y, pos.z, 0) - Vector(poseye.y, poseye.z, 0)):Angle(), (Vector(pos.x, pos.z, 0) - Vector(poseye.x, poseye.z, 0)):Angle()
		local XAng, YAng, ZAng = Angle(0, 0, xangle.y + 90) + VECTOR_FRONT:Angle(), ANGLE_ARROW_OFFSET - Angle(0, 0, yangle.y), Angle(0, ang.y, 0) + vector_up:Angle()
		self.ArrowX.LocalAng = XAng
		self.ScaleX.LocalAng = XAng
		self.ArrowY.LocalAng = YAng
		self.ScaleY.LocalAng = YAng
		self.ArrowZ.LocalAng = ZAng
		self.ScaleZ.LocalAng = ZAng
	end

	self:NextThink(CurTime() + 0.001)
	return true
end
