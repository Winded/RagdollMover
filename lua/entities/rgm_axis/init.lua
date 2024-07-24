
include("shared.lua")
AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

ENT.DisableDuplicator = true
ENT.DoNotDuplicate = true

local VECTOR_ORIGIN = Vector(0, 0, 0)
local VECTOR_FRONT = Vector(1, 0, 0)
local ANGLE_DISC = Angle(0, 90, 0)
local ANGLE_ARROW_OFFSET = Angle(0, 90, 90)

function ENT:Think()
	local pl = self.Owner
	if not IsValid(pl) then return end

	local ent = RAGDOLLMOVER[pl].Entity
	local bone = RAGDOLLMOVER[pl].PhysBone
	if not IsValid(ent) or not RAGDOLLMOVER[pl].Bone or not self.Axises then return end
	local parent = ent:GetParent()

	if RAGDOLLMOVER[pl].GizmoParentID and RAGDOLLMOVER[pl].GizmoParentID ~= -1 and RAGDOLLMOVER[pl].GizmoParent then
		local ent = ent
		if self.EntAdvMerged then
			if not IsValid(parent) then return end
			ent = parent
			if ent.AttachedEntity then ent = ent.AttachedEntity end
		end
		local physobj = ent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
		if physobj then
			_, self.GizmoParent = LocalToWorld(vector_origin, RAGDOLLMOVER[pl].GizmoParent, physobj:GetPos(), physobj:GetAngles())
		else
			return
		end
	elseif RAGDOLLMOVER[pl].GizmoParent then
		_, self.GizmoParent = LocalToWorld(vector_origin, RAGDOLLMOVER[pl].GizmoParent, ent:GetPos(), ent:GetAngles())
	else
		self.GizmoParent = angle_zero
	end

	local advbones = nil
	if ent:GetClass() == "ent_advbonemerge" then
		advbones = ent.AdvBone_BoneInfo
	end

	local pos, ang
	local rotate = RAGDOLLMOVER[pl].Rotate or false
	local scale = RAGDOLLMOVER[pl].Scale or false
	local offset, offsetlocal = RAGDOLLMOVER[pl].GizmoOffset, self.localoffset

	if IsValid(parent) and RAGDOLLMOVER[pl].Bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not ent:IsEffectActive(EF_FOLLOWBONE) and not (ent:GetClass() == "prop_ragdoll") then
		pos = parent:LocalToWorld(ent:GetLocalPos())
	elseif RAGDOLLMOVER[pl].IsPhysBone then

		local physobj = ent:GetPhysicsObjectNum(bone)
		if physobj == nil then return end
		pos = physobj:GetPos()

	else
		bone = RAGDOLLMOVER[pl].Bone
		if not self.GizmoPos or not self.GizmoAng then
			return
		else
			if self.EntAdvMerged then
				local parent = parent
				if parent.AttachedEntity then parent = parent.AttachedEntity end

				if RAGDOLLMOVER[pl].GizmoParentID ~= -1 then
					local physobj = parent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
					pos = LocalToWorld(self.GizmoPos, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					pos = LocalToWorld(self.GizmoPos, self.GizmoAng, parent:GetPos(), parent:GetAngles())
				end
			elseif RAGDOLLMOVER[pl].GizmoParentID then
				if RAGDOLLMOVER[pl].GizmoParentID ~= -1 then
					local physobj = ent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
					pos = LocalToWorld(self.GizmoPos, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					pos = LocalToWorld(self.GizmoPos, self.GizmoAng, ent:GetPos(), ent:GetAngles())
				end
			else
				pos = self.GizmoPos
			end
			
		end
	end


	if IsValid(parent) and RAGDOLLMOVER[pl].Bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not ent:IsEffectActive(EF_FOLLOWBONE) and not (ent:GetClass() == "prop_ragdoll") and not scale then
		ang = parent:LocalToWorldAngles(ent:GetLocalAngles())
	elseif RAGDOLLMOVER[pl].IsPhysBone and not scale then

		local physobj = ent:GetPhysicsObjectNum(bone)
		if physobj == nil then return end
		ang = physobj:GetAngles()

	else
		if rotate then
			if self.EntAdvMerged then
				local parent = parent
				if parent.AttachedEntity then parent = parent.AttachedEntity end
				if RAGDOLLMOVER[pl].GizmoParentID ~= -1 then
					local physobj = parent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, parent:GetPos(), parent:GetAngles())
				end
			elseif ent:GetBoneParent(bone) ~= -1 then
				if not RAGDOLLMOVER[pl].GizmoParent then -- dunno if there is a need for these failsafes
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
				if RAGDOLLMOVER[pl].GizmoParentID ~= -1 then
					local physobj = ent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
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
			if RAGDOLLMOVER[pl].GizmoParentID then
				local funent = ent
				if self.EntAdvMerged then
					funent = parent
					if funent.AttachedEntity then funent = funent.AttachedEntity end
				end
				if RAGDOLLMOVER[pl].GizmoParentID ~= -1 then
					local physobj = funent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
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
				if RAGDOLLMOVER[pl].GizmoParentID ~= -1 then
					local physobj = parent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					_, ang = LocalToWorld(vector_origin, self.GizmoAng, parent:GetPos(), parent:GetAngles())
				end
			elseif ent:GetBoneParent(bone) ~= -1 then
				if not RAGDOLLMOVER[pl].GizmoParent then
					local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone)) -- never would have guessed that when moving bones they use angles of their parent bone rather than their own angles. happened to get to know that after looking at vanilla bone manipulator!
					ang = matrix:GetAngles()
				else
					ang = self.GizmoParent
				end
			else
				if IsValid(ent) then
					if RAGDOLLMOVER[pl].GizmoParentID ~= -1 then
						local physobj = ent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
						_, ang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
					else
						_, ang = LocalToWorld(vector_origin, self.GizmoAng, ent:GetPos(), ent:GetAngles())
					end
				end
			end
		end
	end

	if not RAGDOLLMOVER[pl].Moving or not rotate then
		local entoffset = VECTOR_ORIGIN
		if not scale and ent.rgmPRoffset and RAGDOLLMOVER[pl].IsPhysBone then
			entoffset = ent.rgmPRoffset
		end

		if offsetlocal then 
			if IsValid(parent) and RAGDOLLMOVER[pl].Bone == 0 and not ent:IsEffectActive(EF_BONEMERGE) and not ent:IsEffectActive(EF_FOLLOWBONE) and not (ent:GetClass() == "prop_ragdoll") then
				self:SetPos(LocalToWorld(offset + entoffset, angle_zero, pos, parent:LocalToWorldAngles(ent:GetLocalAngles())))
			else
				if self.EntAdvMerged then
					local funent = parent
					if funent.AttachedEntity then funent = funent.AttachedEntity end
					local offsetang

					if RAGDOLLMOVER[pl].GizmoParentID ~= -1 then
						local physobj = funent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
						_, offsetang = LocalToWorld(vector_origin, self.GizmoAng, physobj:GetPos(), physobj:GetAngles())
					else
						_, offsetang = LocalToWorld(vector_origin, self.GizmoAng, funent:GetPos(), funent:GetAngles())
					end

					_, offsetang = LocalToWorld(vector_origin, ent:GetManipulateBoneAngles(bone), vector_origin, offsetang)

					self:SetPos(LocalToWorld(offset + entoffset, angle_zero, pos, offsetang))
				elseif RAGDOLLMOVER[pl].IsPhysBone then
					self:SetPos(LocalToWorld(offset + entoffset, angle_zero, pos, ang))
				else
					local offsetang
					if RAGDOLLMOVER[pl].GizmoParentID then
						local ent = ent
						if self.EntAdvMerged then
							ent = parent
							if ent.AttachedEntity then ent = ent.AttachedEntity end
						end
						if RAGDOLLMOVER[pl].GizmoParentID ~= -1 then
							local physobj = ent:GetPhysicsObjectNum(RAGDOLLMOVER[pl].GizmoParentID)
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

	if not RAGDOLLMOVER[pl].Moving then -- Prevent whole thing from rotating when we do localized rotation - needed for proper angle reading
		if localstate or scale or (not RAGDOLLMOVER[pl].IsPhysBone and rotate) then -- Non phys bones don't go well with world coordinates.
			local moveang = ang
			if not scale and ent.rgmPRaoffset and RAGDOLLMOVER[pl].IsPhysBone then
				_, moveang = LocalToWorld(vector_origin, ent.rgmPRaoffset, vector_origin, ang or angle_zero)
			end
			self:SetAngles(moveang)
			if not RAGDOLLMOVER[pl].IsPhysBone then
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

	local pos, poseye = self:GetPos(), pl:EyePos()
	local disc = self.DiscLarge
	local ang = (pos - poseye):Angle()
	ang = self:WorldToLocalAngles(ang)
	disc.LocalAng = ang
	self.ArrowOmni.LocalAng = ang

	if not RAGDOLLMOVER[pl].Moving then
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
