RGMGIZMOS = {}

RGMGIZMOS.AxisTypeEnum = {
	Pitch = 1,
	Yaw = 2,
	Roll = 3,
	Large = 4,
	X = 1,
	Y = 2,
	Z = 3,
}

local VECTOR_FRONT = RGM_Constants.VECTOR_FRONT
local VECTOR_SIDE = RGM_Constants.VECTOR_LEFT
local COLOR_BRIGHT_YELLOW = RGM_Constants.COLOR_BRIGHT_YELLOW
local COLOR_BRIGHT_YELLOW2 = ColorAlpha(COLOR_BRIGHT_YELLOW, 6)

local PARENTED_BONE = 0
local PHYSICAL_BONE = 1
local NONPHYSICAL_BONE = 2

local AxisType = RGMGIZMOS.AxisTypeEnum

local function isnan(num)
	return num == num
end

local function getBoneAngle(ent, parent, bone, axis, plTable)
	local _, boneang = ent:GetBonePosition(bone)
	if axis.EntAdvMerged then
		if parent.AttachedEntity then parent = parent.AttachedEntity end
		if plTable.GizmoParentID ~= -1 then
			local physobj = parent:GetPhysicsObjectNum(plTable.GizmoParentID)
			_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
		else
			_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, parent:GetPos(), parent:GetAngles())
		end
	elseif ent:GetClass() == "prop_physics" then
		local manang = ent:GetManipulateBoneAngles(bone)*1
		manang:Normalize()

		_, boneang = LocalToWorld(vector_origin, Angle(0, 0, -manang[3]), vector_origin, boneang)
		_, boneang = LocalToWorld(vector_origin, Angle(-manang[1], 0, 0), vector_origin, boneang)
		_, boneang = LocalToWorld(vector_origin, Angle(0, -manang[2], 0), vector_origin, boneang)
	else
		if ent:GetBoneParent(bone) ~= -1 then
			local _ , pang = ent:GetBonePosition(ent:GetBoneParent(bone))

			local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
			_, boneang = LocalToWorld(vector_origin, diff, vector_origin, axis.GizmoParent)
		else
			boneang = axis.LocalAngles
		end
	end

	return boneang
end

----------------
-- BASE GIZMO --
----------------
local basepart = {}
do

	basepart.IsDisc = false
	basepart.IsBall = false
	basepart.Parent = nil
	basepart.AngOffset = Angle(0, 0, 0)
	basepart.LocalAng = Angle(0, 0, 0)
	basepart.Color = nil
	basepart.Color2 = nil
	basepart.linepositions = nil
	basepart.collpositions = nil

	function basepart:GetPos()
		return self.Parent:GetPos()
	end

	function basepart:GetAngles()
		local _, ang = LocalToWorld(vector_origin, self.LocalAng, vector_origin, self.Parent:GetAngles())
		return ang
	end

	function basepart:WorldToLocal(vec)
		local v = WorldToLocal(vec, angle_zero, self:GetPos(), self:GetAngles())
		return v
	end

	function basepart:LocalToWorld(vec)
		local v = LocalToWorld(vec, angle_zero, self:GetPos(), self:GetAngles())
		return v
	end

	function basepart:WorldToLocalAngles(ang)
		local _, a = WorldToLocal(vector_origin, ang, vector_origin, self:GetAngles())
		return a
	end

	function basepart:LocalToWorldAngles(ang)
		local _, a = LocalToWorld(vector_origin, ang, vector_origin, self:GetAngles())
		return a
	end

	function basepart:SetColor(color, num)
		if num == 2 then
			self.Color2 = color:ToTable()
		else
			self.Color = color:ToTable()
		end
	end

	function basepart:GetColor(num)
		local color

		if num == 2 then
			color = table.Copy(self.Color2)
		else
			color = table.Copy(self.Color)
		end

		return color
	end

	function basepart:GetGrabPos(eyepos, eyeang, ppos, pnorm)
		local pos = eyepos
		local norm = eyeang:Forward()
		local planepos = self:GetPos()
		local planenorm = self:GetAngles():Forward()
		if ppos then planepos = ppos*1 end
		if pnorm then planenorm = pnorm*1 end
		local intersect = rgm.IntersectRayWithPlane(planepos, planenorm, pos, norm)
		return intersect
	end

	--To be overwritten
	function basepart:TestCollision(pl)
	end

	function basepart:CalculateGizmo(scale)
	end

	if SERVER then

		--To be overwritten
		function basepart:ProcessMovement(offpos, offang, eyepos, eyeang, norm)
		end

	end

	if CLIENT then

		--To be overwritten
		function basepart:GetLinePositions()
		end

		function basepart:PointsToWorld(vectors, scale)
			local translated = {}
			for k, vec in ipairs(vectors) do
				table.insert(translated, self:LocalToWorld(vec * scale))
			end
			return translated
		end

		function basepart:DrawLines(yellow, scale, width)
			local toscreen = {}
			local linetable = self:GetLinePositions(width)
			local color = self:GetColor()
			color = Color(color[1], color[2], color[3], color[4])

			for i, v in ipairs(linetable) do
				local points = self:PointsToWorld(v, scale)
				local col = color
				if yellow then
					col = COLOR_BRIGHT_YELLOW
				end
				table.insert(toscreen, {points, col})
			end

			for i, v in ipairs(toscreen) do
				render.DrawQuad(v[1][1], v[1][2], v[1][3], v[1][4], v[2])
			end
		end

	end

end


--------------------
-- POSITION ARROW --
--------------------
local posarrow = table.Copy(basepart)

do

	function posarrow:GetGrabPos(eyepos, eyeang, ppos)
		local pos = eyepos
		local norm = eyeang:Forward()
		local planepos = self:GetPos()
		if ppos then planepos = ppos*1 end
		local planenorm = self:WorldToLocalAngles(self:GetAngles():Up():Angle())
		planenorm = Angle(planenorm.p, self:WorldToLocalAngles((self:GetPos() - eyepos):Angle()).y, planenorm.r)
		planenorm = self:LocalToWorldAngles(planenorm):Forward()
		--local planenorm = self:GetAngles():Up()
		local intersect = rgm.IntersectRayWithPlane(planepos, planenorm, pos, norm)
		return intersect
	end

	function posarrow:TestCollision(pl)
		local plTable = RAGDOLLMOVER[pl]
		local plviewent = plTable.always_use_pl_view == 1 and pl or (plTable.PlViewEnt ~= 0 and Entity(plTable.PlViewEnt) or nil)
		local eyepos, eyeang = rgm.EyePosAng(pl, plviewent)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local localized = self:WorldToLocal(intersect)
		local distmin, distmax

		distmin = self.collpositions[1]
		distmax = self.collpositions[2]

		if localized.x >= distmin.x and localized.x <= distmax.x
		and localized.y >= distmin.y and localized.y <= distmax.y
		and localized.z >= distmin.z and localized.z <= distmax.z then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	function posarrow:CalculateGizmo(scale)
		local distmin, distmax

		distmin	= Vector(0.1 * scale, -0.075 * scale, -0.075 * scale)
		distmax = Vector(1 * scale, 0.075 * scale, 0.075 * scale)

		self.collpositions = {distmin, distmax}
	end

	if SERVER then

		function posarrow:ProcessMovement(offpos, _, eyepos, eyeang, ent, bone, ppos, _, movetype, _, _, nphyspos)
			local intersect = self:GetGrabPos(eyepos, eyeang, ppos)
			local axis = self.Parent
			local plTable = RAGDOLLMOVER[axis.Owner]
			local parent = ent:GetParent()
			local arrowAng = axis:LocalToWorldAngles(self.AngOffset)
			local localized = WorldToLocal(intersect, angle_zero, axis:GetPos(), arrowAng)
			local offset = plTable.GizmoOffset
			local entoffset = vector_origin
			if axis.localoffset then
				offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
				offset =  offset - axis:GetPos()
			end
			if ent.rgmPRoffset then
				entoffset = LocalToWorld(ent.rgmPRoffset, angle_zero, axis:GetPos(), axis.LocalAngles)
				entoffset = entoffset - axis:GetPos()
				offset = offset + entoffset
			end
			local pos, ang
			local _, selfangle = LocalToWorld(vector_origin, self.AngOffset, vector_origin, axis:GetAngles()) --self:GetAngles()

			if movetype == PHYSICAL_BONE then
				local obj = ent:GetPhysicsObjectNum(bone)
				localized = Vector(localized.x, 0, 0)
				intersect = LocalToWorld(localized, angle_zero, axis:GetPos(), arrowAng)
				ang = obj:GetAngles()
				pos = LocalToWorld(Vector(offpos.x, 0, 0), angle_zero, intersect - offset, selfangle)
			elseif movetype == NONPHYSICAL_BONE then
				local finalpos, boneang
				local advbones = nil
				if ent:GetClass() == "ent_advbonemerge" then
					advbones = ent.AdvBone_BoneInfo
				end

				if axis.EntAdvMerged then
					if parent.AttachedEntity then parent = parent.AttachedEntity end
					local funang
					if plTable.GizmoParentID ~= -1 then
						local physobj = parent:GetPhysicsObjectNum(plTable.GizmoParentID)
						_, funang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
					else
						_, funang = LocalToWorld(vector_origin, axis.GizmoAng, parent:GetPos(), parent:GetAngles())
					end

					local pbone = parent:LookupBone(advbones[bone].parent) -- may need to make an exception if the bone doesn't exist for some reason, but i think adv bonemerge would handle that already
					local matrix = parent:GetBoneMatrix(pbone)
					boneang = matrix:GetAngles()

					local _ , pang = parent:GetBonePosition(pbone)

					local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
					_, boneang = LocalToWorld(vector_origin, diff, vector_origin, funang)
				elseif ent:GetBoneParent(bone) ~= -1 then
					local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
					boneang = matrix:GetAngles()
					if not (ent:GetClass() == "prop_physics") then
						local _ , pang = ent:GetBonePosition(ent:GetBoneParent(bone))

						local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
						_, boneang = LocalToWorld(vector_origin, diff, vector_origin, axis.GizmoParent)
					end
				else
					if ent:GetClass() == "ent_advbonemerge" and parent:GetClass() == "prop_ragdoll" then
						boneang = angle_zero -- bone has no parent and isn't physical
					else
						if plTable.GizmoParentID ~= -1 then
							local physobj = ent:GetPhysicsObjectNum(plTable.GizmoParentID)
							boneang = physobj:GetAngles()
						else
							boneang = ent:GetAngles()
						end
					end
				end

				intersect = self:LocalToWorld(Vector(localized.x, 0, 0))
				localized = LocalToWorld(Vector(offpos.x, 0, 0), angle_zero, intersect, self:GetAngles())
				localized = WorldToLocal(localized, angle_zero, self:GetPos(), boneang)

				finalpos = nphyspos + localized
				ang = ent:GetManipulateBoneAngles(bone)
				pos = finalpos
			elseif movetype == PARENTED_BONE then
				localized = Vector(localized.x, 0, 0)
				intersect = self:LocalToWorld(localized)
				ang = ent:GetLocalAngles()
				pos = LocalToWorld(Vector(offpos.x, 0, 0), angle_zero, intersect - offset, selfangle)
				pos = parent:WorldToLocal(pos)
			end
			return pos, ang
		end

	end

	if CLIENT then

		function posarrow:GetLinePositions(width)
			local RTable

			if self.Parent.width ~= width or not self.linepositions then
				RTable = {
					{Vector(0.1, -0.075 * width, 0), Vector(0.75, -0.075 * width, 0), Vector(0.75, 0.075 * width, 0), Vector(0.1, 0.075 * width, 0)},
					{Vector(0.75, -0.0625 - 0.0625 * width, 0), VECTOR_FRONT, VECTOR_FRONT, Vector(0.75, 0.0625 + 0.0625 * width, 0)}
				}

				self.linepositions = RTable
			else
				RTable = self.linepositions
			end

			return RTable
		end
		
	end

end


-------------------
-- POSITION SIDE --
-------------------
local posside = table.Copy(basepart)

do

	function posside:TestCollision(pl)
		local plTable = RAGDOLLMOVER[pl]
		local plviewent = plTable.always_use_pl_view == 1 and pl or (plTable.PlViewEnt ~= 0 and Entity(plTable.PlViewEnt) or nil)
		local eyepos, eyeang = rgm.EyePosAng(pl, plviewent)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local localized = self:WorldToLocal(intersect)
		local distmin1, distmax1, distmin2, distmax2

		distmin1 = self.collpositions[1]
		distmax1 = self.collpositions[2]
		distmin2 = self.collpositions[3]
		distmax2 = self.collpositions[4]

		if (localized.x >= distmin1.x and localized.x <= distmax1.x
		and localized.y >= distmin1.y and localized.y <= distmax1.y
		and localized.z >= distmin1.z and localized.z <= distmax1.z)
		or (localized.x >= distmin2.x and localized.x <= distmax2.x
		and localized.y >= distmin2.y and localized.y <= distmax2.y
		and localized.z >= distmin2.z and localized.z <= distmax2.z) then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	function posside:CalculateGizmo(scale)
		local distmin1, distmax1, distmin2, distmax2

		distmin1 = Vector(-0.15 * scale, scale * 0.2, 0)
		distmax1 = Vector(0.15 * scale, scale * 0.3, scale * 0.3)
		distmin2 = Vector(-0.15 * scale, 0, scale * 0.2)
		distmax2 = Vector(0.15 * scale, scale * 0.3, scale * 0.3)

		self.collpositions = {distmin1, distmax1, distmin2, distmax2}
	end

	if SERVER then

		function posside:ProcessMovement(offpos, _, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, _, _, nphyspos)
			local intersect = self:GetGrabPos(eyepos, eyeang, ppos, pnorm)
			local axis = self.Parent
			local parent = ent:GetParent()
			local plTable = RAGDOLLMOVER[axis.Owner]
			local offset = plTable.GizmoOffset
			local entoffset = vector_origin
			if axis.localoffset then
				offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
				offset =  offset - axis:GetPos()
			end
			if ent.rgmPRoffset then
				entoffset = LocalToWorld(ent.rgmPRoffset, angle_zero, axis:GetPos(), axis.LocalAngles)
				entoffset = entoffset - axis:GetPos()
				offset = offset + entoffset
			end
			local pos, ang

			if movetype == PHYSICAL_BONE then
				local obj = ent:GetPhysicsObjectNum(bone)
				ang = obj:GetAngles()
				pos = LocalToWorld(offpos, angle_zero, intersect - offset, self:GetAngles())
			elseif movetype == NONPHYSICAL_BONE then
				local localized, finalpos, boneang
				local advbones = nil
				if ent:GetClass() == "ent_advbonemerge" then
					advbones = ent.AdvBone_BoneInfo
				end

				if axis.EntAdvMerged then
					if parent.AttachedEntity then parent = parent.AttachedEntity end
					local funang
					if plTable.GizmoParentID ~= -1 then
						local physobj = parent:GetPhysicsObjectNum(plTable.GizmoParentID)
						_, funang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
					else
						_, funang = LocalToWorld(vector_origin, axis.GizmoAng, parent:GetPos(), parent:GetAngles())
					end

					local pbone = parent:LookupBone(advbones[bone].parent) -- may need to make an exception if the bone doesn't exist for some reason, but i think adv bonemerge would handle that already
					local matrix = parent:GetBoneMatrix(pbone)
					boneang = matrix:GetAngles()

					local _ , pang = parent:GetBonePosition(pbone)

					local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
					_, boneang = LocalToWorld(vector_origin, diff, vector_origin, funang)
				elseif ent:GetBoneParent(bone) ~= -1 then
					local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
					boneang = matrix:GetAngles()
					if not (ent:GetClass() == "prop_physics") then
						local _ , pang = ent:GetBonePosition(ent:GetBoneParent(bone))

						local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
						_, boneang = LocalToWorld(vector_origin, diff, vector_origin, axis.GizmoParent)
					end
				else
					if ent:GetClass() == "ent_advbonemerge" and parent:GetClass() == "prop_ragdoll" then
						boneang = angle_zero -- bone has no parent and isn't physical
					else
						if plTable.GizmoParentID ~= -1 then
							local physobj = ent:GetPhysicsObjectNum(plTable.GizmoParentID)
							boneang = physobj:GetAngles()
						else
							boneang = ent:GetAngles()
						end
					end
				end

				localized = LocalToWorld(offpos, angle_zero, intersect, self:GetAngles())
				localized = WorldToLocal(localized, angle_zero, self:GetPos(), boneang)

				finalpos = nphyspos + localized
				ang = ent:GetManipulateBoneAngles(bone)
				pos = finalpos
			elseif movetype == PARENTED_BONE then
				ang = ent:GetLocalAngles()
				pos = LocalToWorld(offpos, angle_zero, intersect - offset, self:GetAngles())
				pos = parent:WorldToLocal(pos)
			end

			return pos, ang
		end

	end

	if CLIENT then

		function posside:GetLinePositions(width)
			local RTable

			if self.Parent.width ~= width or not self.linepositions then
				RTable = {
					{Vector(0, 0.25 - 0.05 * width, 0), Vector(0, 0.25 - 0.05 * width, 0.25 - 0.05 * width), Vector(0, 0.25 + 0.05 * width, 0.25 + 0.05 * width), Vector(0, 0.25 + 0.05 * width, 0)},
					{Vector(0, 0, 0.25 - 0.05 * width), Vector(0, 0.25 - 0.05 * width, 0.25 - 0.05 * width), Vector(0, 0.25 + 0.05 * width, 0.25 + 0.05 * width), Vector(0, 0, 0.25 + 0.05 * width)}
				}

				self.linepositions = RTable
			else
				RTable = self.linepositions
			end

			return RTable
		end

		function posside:DrawLines(yellow, scale, width)
			local toscreen = {}
			local linetable = self:GetLinePositions(width)
			local color = self:GetColor()
			color = Color(color[1], color[2], color[3], color[4])

			local color2 = self:GetColor(2)
			if color2 then
				color2 = Color(color2[1], color2[2], color2[3], color2[4])
			end

			for i, v in ipairs(linetable) do
				local points = self:PointsToWorld(v, scale)
				local col = color
				if yellow then
					col = COLOR_BRIGHT_YELLOW
				elseif i == 2 then
					col = color2
				end
				table.insert(toscreen, {points, col})
			end
			for i, v in ipairs(toscreen) do
				render.DrawQuad(v[1][1], v[1][2], v[1][3], v[1][4], v[2])
			end
		end

	end

end


-------------------
-- POSITION OMNI --
-------------------
local omnipos = table.Copy(posside)

do

	function omnipos:TestCollision(pl)
		local plTable = RAGDOLLMOVER[pl]
		local plviewent = plTable.always_use_pl_view == 1 and pl or (plTable.PlViewEnt ~= 0 and Entity(plTable.PlViewEnt) or nil)
		local eyepos, eyeang = rgm.EyePosAng(pl, plviewent)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local localized = self:WorldToLocal(intersect)
		local distmin1, distmax1

		distmin1 = self.collpositions[1]
		distmax1 = self.collpositions[2]

		if (localized.x >= distmin1.x and localized.x <= distmax1.x
		and localized.y >= distmin1.y and localized.y <= distmax1.y
		and localized.z >= distmin1.z and localized.z <= distmax1.z) then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	function omnipos:CalculateGizmo(scale)
		local distmin1, distmax1

		distmin1 = Vector(-0.075 * scale, scale * (-0.08), scale * (-0.08))
		distmax1 = Vector(0.075 * scale, scale * 0.08, scale * 0.08)

		self.collpositions = {distmin1, distmax1}
	end

	if SERVER then

		function omnipos:ProcessMovement(offpos, _, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, _, _, nphyspos, _, _, tracepos)
			local intersect = tracepos
			if not intersect then
				intersect = self:GetGrabPos(eyepos, eyeang, ppos, pnorm)
			end

			local axis = self.Parent
			local parent = ent:GetParent()
			local plTable = RAGDOLLMOVER[axis.Owner]
			local offset = plTable.GizmoOffset
			local entoffset = vector_origin
			if axis.localoffset then
				offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
				offset =  offset - axis:GetPos()
			end
			if ent.rgmPRoffset then
				entoffset = LocalToWorld(ent.rgmPRoffset, angle_zero, axis:GetPos(), axis.LocalAngles)
				entoffset = entoffset - axis:GetPos()
				offset = offset + entoffset
			end
			local pos, ang

			if movetype == PHYSICAL_BONE then
				local obj = ent:GetPhysicsObjectNum(bone)
				ang = obj:GetAngles()
				pos = LocalToWorld(offpos, angle_zero, intersect - offset, self:GetAngles())
			elseif movetype == NONPHYSICAL_BONE then
				local localized, startmove, finalpos, boneang
				local advbones = nil
				if ent:GetClass() == "ent_advbonemerge" then
					advbones = ent.AdvBone_BoneInfo
				end

				if axis.EntAdvMerged then
					if parent.AttachedEntity then parent = parent.AttachedEntity end
					local funang
					if plTable.GizmoParentID ~= -1 then
						local physobj = parent:GetPhysicsObjectNum(plTable.GizmoParentID)
						_, funang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
					else
						_, funang = LocalToWorld(vector_origin, axis.GizmoAng, parent:GetPos(), parent:GetAngles())
					end

					local pbone = parent:LookupBone(advbones[bone].parent) -- may need to make an exception if the bone doesn't exist for some reason, but i think adv bonemerge would handle that already
					local matrix = parent:GetBoneMatrix(pbone)
					boneang = matrix:GetAngles()

					local _ , pang = parent:GetBonePosition(pbone)

					local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
					_, boneang = LocalToWorld(vector_origin, diff, vector_origin, funang)
				elseif ent:GetBoneParent(bone) ~= -1 then
					local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
					boneang = matrix:GetAngles()
					if not (ent:GetClass() == "prop_physics") then
						local _ , pang = ent:GetBonePosition(ent:GetBoneParent(bone))

						local _, diff = WorldToLocal(vector_origin, boneang, vector_origin, pang)
						_, boneang = LocalToWorld(vector_origin, diff, vector_origin, axis.GizmoParent)
					end
				else
					if ent:GetClass() == "ent_advbonemerge" and parent:GetClass() == "prop_ragdoll" then
						boneang = angle_zero -- bone has no parent and isn't physical
					else
						if plTable.GizmoParentID ~= -1 then
							local physobj = ent:GetPhysicsObjectNum(plTable.GizmoParentID)
							boneang = physobj:GetAngles()
						else
							boneang = ent:GetAngles()
						end
					end
				end

				localized = LocalToWorld(offpos, angle_zero, intersect, self:GetAngles())
				localized = WorldToLocal(localized, angle_zero, self:GetPos(), boneang)

				finalpos = nphyspos + localized
				ang = ent:GetManipulateBoneAngles(bone)
				pos = finalpos
			elseif movetype == PARENTED_BONE then
				ang = ent:GetLocalAngles()
				pos = LocalToWorld(offpos, angle_zero, intersect - offset, self:GetAngles())
				pos = parent:WorldToLocal(pos)
			end

			return pos, ang
		end

	end

	if CLIENT then

		function omnipos:GetLinePositions(width)
			local RTable

			if self.Parent.width ~= width or not self.linepositions then
				RTable = {{Vector(0, -0.08 * width, -0.08 * width), Vector(0, -0.08 * width, 0.08 * width), Vector(0, 0.08 * width, 0.08 * width), Vector(0, 0.08 * width, -0.08 * width)}}

				self.linepositions = RTable
			else
				RTable = self.linepositions
			end

			return RTable
		end

	end

end


-------------------
-- ROTATION DISC --
-------------------
local disc = table.Copy(basepart)

do

	disc.IsDisc = true

	function disc:TestCollision(pl)
		local plTable = RAGDOLLMOVER[pl]
		local plviewent = plTable.always_use_pl_view == 1 and pl or (plTable.PlViewEnt ~= 0 and Entity(plTable.PlViewEnt) or nil)
		local eyepos, eyeang = rgm.EyePosAng(pl, plviewent)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local distmin = self.collpositions[1]
		local distmax = self.collpositions[2]
		local dist = intersect:Distance(self:GetPos())
		if dist >= distmin and dist <= distmax then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	function disc:CalculateGizmo(scale)
		self.collpositions = { 0.9 * scale, 1.1 * scale }
	end

	if SERVER then

		local function ConvertVector(vec, axistype)
			local result

			if axistype == AxisType.Pitch then
				result = Vector(-vec.x, vec.z, 0)
			elseif axistype == AxisType.Yaw then
				result = Vector(vec.x, vec.y, 0)
			elseif axistype == AxisType.Roll then
				result = Vector(vec.y, vec.z, 0)
			else
				result = vec
			end

			return result
		end

		local snapAngle do

			local floor = math.floor
			local ceil = math.ceil

			-- Accumulate delta angles per frame until startangle is different (stopped rotating)
			-- Allows for correct snapped angles set by the rotation delta
			function snapAngle(self, localized, startangle, snapamount, nonphys)
				local parent = self.Parent
				if not parent.Accumulated then
					parent.Accumulated = 0
					parent.LastStartAngle = 0
					parent.OldLocalAngle = 0
				end

				local localAng = localized.y
	
				if parent.LastStartAngle ~= startangle.y then
					parent.Accumulated = 0
					parent.OldLocalAngle = localAng
					parent.LastStartAngle = startangle.y
				end

				-- https://discussions.unity.com/t/can-i-read-from-a-rotation-that-doesnt-wrap-from-360-to-zero/621621/7
				while (localAng < parent.OldLocalAngle - 180) do
					localAng = localAng + 360
				end
				while (localAng > parent.OldLocalAngle + 180) do
					localAng = localAng - 360
				end

				local delta = parent.OldLocalAngle - localAng
				parent.Accumulated = parent.Accumulated + delta
				parent.OldLocalAngle = localAng
	
				local mathfunc = nil
				if parent.Accumulated >= 0 then
					mathfunc = floor
				else
					mathfunc = ceil
				end

	
				if nonphys then
					return -mathfunc(parent.Accumulated / snapamount) * snapamount
				else
					return startangle.y - (mathfunc(parent.Accumulated / snapamount) * snapamount)
				end
			end
		end

		function disc:ProcessMovement(_, offang, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, snapamount, startangle, _, nphysangle) -- initially i had a table instead of separate things for initial bone pos and angle, but sync command can't handle tables and i thought implementing a way to handle those would be too much hassle
			local intersect = self:GetGrabPos(eyepos, eyeang, ppos, pnorm)
			local localized = self:WorldToLocal(intersect)
			local _p, _a
			local axis = self.Parent
			local pl = axis.Owner
			local plTable = RAGDOLLMOVER[pl]

			local axistable = {
				(axis:LocalToWorld(VECTOR_SIDE) - self:GetPos()):Angle(),
				(axis:LocalToWorld(vector_up) - self:GetPos()):Angle(),
				(axis:LocalToWorld(VECTOR_FRONT) - self:GetPos()):Angle(),
				(self:GetPos() - pl:EyePos()):Angle()
			}
			axistable[1]:Normalize()
			axistable[2]:Normalize()
			axistable[3]:Normalize()
			axistable[4]:Normalize()

			if movetype == PHYSICAL_BONE then
				local offset = plTable.GizmoOffset
				local entoffset = vector_origin
				if axis.localoffset and not axis.relativerotate then
					offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
					offset = offset - axis:GetPos()
				end
				if ent.rgmPRoffset then
					entoffset = LocalToWorld(ent.rgmPRoffset, angle_zero, axis:GetPos(), axis.LocalAngles)
					entoffset = entoffset - axis:GetPos()
					offset = offset + entoffset
				end

				localized = Vector(localized.y, localized.z, 0):Angle()
				startangle = Vector(startangle.y, startangle.z, 0):Angle()

				local rotationangle = localized.y
				if snapamount ~= 0 then
					rotationangle = snapAngle(self, localized, startangle, snapamount)
				end

				local pos = self:GetPos()
				local ang = self:LocalToWorldAngles(Angle(0, 0, rotationangle))

				if axis.relativerotate then
					offset = WorldToLocal(axis.BonePos, angle_zero, axis:GetPos(), axis.LocalAngles)
					_p, _a = LocalToWorld(vector_origin, offang, pos, ang)
					_p = LocalToWorld(offset, _a, pos, _a)
				else
					_p, _a = LocalToWorld(vector_origin, offang, pos, ang)
					_p = pos - offset
				end
			elseif movetype == NONPHYSICAL_BONE then
				local rotateang, axisangle
				local parent = ent:GetParent()
				axisangle = axistable[self.axistype]

				local boneang = getBoneAngle(ent, parent, bone, axis, plTable)
				
				local startlocal = LocalToWorld(startangle, startangle:Angle(), vector_origin, axisangle) -- first we get our vectors into world coordinates, relative to the axis angles
				localized = LocalToWorld(localized, localized:Angle(), vector_origin, axisangle)
				localized = WorldToLocal(localized, localized:Angle(), vector_origin, boneang) -- then convert that vector to the angles of the bone
				startlocal = WorldToLocal(startlocal, startlocal:Angle(), vector_origin, boneang)

				localized = ConvertVector(localized, self.axistype)
				startlocal = ConvertVector(startlocal, self.axistype)

				localized = localized:Angle() - startlocal:Angle()

				local rotationangle = localized.y
				if snapamount ~= 0 then
					rotationangle = snapAngle(self, localized, startangle, snapamount, true)
				end

				if self.axistype == AxisType.Large then
					_a = nphysangle
				else
					_a = ent:GetManipulateBoneAngles(bone)
					_a = _a*1 -- do this to copy angle in case if we're rotating advanced bonemerged stuff
					rotateang = nphysangle[self.axistype] + rotationangle
					_a[self.axistype] = rotateang
				end

				if axis.relativerotate then
					local pos = axis:GetPos()
					local offset

					local worldang
					_p, worldang = LocalToWorld(vector_origin, _a, pos, boneang)
					if axis.localoffset then
						offset = -plTable.GizmoOffset
						_p = LocalToWorld(offset, axis.LocalAngles, _p, worldang)
					else
						local _, oldang = LocalToWorld(vector_origin, nphysangle, vector_origin, axis.LocalAngles)
						offset = WorldToLocal(axis.BonePos, angle_zero, axis:GetPos(), oldang)
						_p = LocalToWorld(offset, angle_zero, _p, worldang)
					end
					_p = WorldToLocal(_p, angle_zero, axis.BonePos, axis.GizmoParent)
					local nonphyspos = WorldToLocal(axis.BonePos, angle_zero, axis.NMBonePos, axis.GizmoParent)
					_p = _p + nonphyspos
				else
					_p = ent:GetManipulateBonePosition(bone)
				end

			elseif movetype == PARENTED_BONE then
				local offset = plTable.GizmoOffset
				local entoffset = vector_origin
				if axis.localoffset and not axis.relativerotate then
					offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
					offset = offset - axis:GetPos()
				end
				if ent.rgmPRoffset then
					entoffset = LocalToWorld(ent.rgmPRoffset, angle_zero, axis:GetPos(), axis.LocalAngles)
					entoffset = entoffset - axis:GetPos()
					offset = offset + entoffset
				end

				localized = Vector(localized.y, localized.z, 0):Angle()
				startangle = Vector(startangle.y, startangle.z, 0):Angle()

				local rotationangle = localized.y
				if snapamount ~= 0 then
					rotationangle = snapAngle(self, localized, startangle, snapamount)
				end

				local pos = self:GetPos()
				local ang = self:LocalToWorldAngles(Angle(0, 0, rotationangle))
				if axis.relativerotate then
					offset = WorldToLocal(axis.BonePos, angle_zero, axis:GetPos(), axis.LocalAngles)
					_p, _a = LocalToWorld(vector_origin, offang, pos, ang)
					_p = LocalToWorld(offset, _a, pos, _a)
					_a = ent:GetParent():WorldToLocalAngles(_a)
					_p = ent:GetParent():WorldToLocal(_p)
				else
					_p, _a = LocalToWorld(vector_origin, offang, pos, ang)
					_p = pos - offset
					_a = ent:GetParent():WorldToLocalAngles(_a)
					_p = ent:GetParent():WorldToLocal(_p)
				end
			end

			return _p, _a
		end

	end

	if CLIENT then

		local ANG = Angle(0, 0, 11.25)

		function disc:GetLinePositions(width)
			local RTable = {}
			local ang = ANG
			local startposmin
			local startposmax

			if self.Parent.width ~= width or not self.linepositions then
				startposmin = Vector(0, 0,1 - 0.1 * width)
				startposmax = Vector(0, 0,1 + 0.1 * width)

				self.linepositions = {startposmin, startposmax}
			else
				startposmin = self.linepositions[1]
				startposmax = self.linepositions[2]
			end

			for i = 1, 32 do
				local pos1 = startposmin*1
				local pos2 = startposmin*1
				local pos3 = startposmax*1
				local pos4 = startposmax*1
				pos1:Rotate(ang * (i - 1))
				pos2:Rotate(ang * (i))
				pos3:Rotate(ang * (i))
				pos4:Rotate(ang * (i - 1))
				RTable[i] = {pos1, pos2, pos3, pos4}
			end
			return RTable
		end

		function disc:DrawLines(yellow, scale, width)
			local pl = LocalPlayer()
			local parent = self.Parent
			local toscreen = {}
			local linetable = self:GetLinePositions(width)
			local eyepos = pl:EyePos()

			local viewent = pl:GetViewEntity()
			if IsValid(viewent) and viewent ~= pl then
				eyepos = viewent:GetPos()
			end

			local largedisc = parent.DiscLarge
			if not largedisc then return end

			local borderpos = largedisc:GetPos()
			local color = self:GetColor()
			color = Color(color[1], color[2], color[3], color[4])

			local moving = RAGDOLLMOVER[pl].Moving or false

			for i,v in ipairs(linetable) do
				local points = self:PointsToWorld(v, scale)
				local col = color
				if yellow then
					col = COLOR_BRIGHT_YELLOW
				end
				if parent.fulldisc or (moving or
				(points[1]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos) and points[2]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos) and 
				points[3]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos) and points[4]:DistToSqr(eyepos) <= borderpos:DistToSqr(eyepos))) then
					table.insert(toscreen, {points, col})
				end
			end
			for i,v in ipairs(toscreen) do
				render.DrawQuad(v[1][1], v[1][2], v[1][3], v[1][4], v[2])
			end
		end

	end

end


-----------------------
-- ROTATION DISC BIG --
-----------------------
local disclarge = table.Copy(disc)

do

	function disclarge:TestCollision(pl)
		local plTable = RAGDOLLMOVER[pl]
		local plviewent = plTable.always_use_pl_view == 1 and pl or (plTable.PlViewEnt ~= 0 and Entity(plTable.PlViewEnt) or nil)
		local eyepos, eyeang = rgm.EyePosAng(pl, plviewent)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local distmin = self.collpositions[1]
		local distmax = self.collpositions[2]
		local dist = intersect:Distance(self:GetPos())
		if dist >= distmin and dist <= distmax then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	function disclarge:CalculateGizmo(scale)
		self.collpositions = { 1.15 * scale, 1.35 * scale }
	end

	if CLIENT then

		function disclarge:DrawLines(yellow, scale, width)
			local toscreen = {}
			local linetable = self:GetLinePositions(width)
			local color = self:GetColor()
			color = Color(color[1], color[2], color[3], color[4])

			for i, v in ipairs(linetable) do
				local col = color
				if yellow then
					col = COLOR_BRIGHT_YELLOW
				end
				local points = self:PointsToWorld(v, scale * 1.25)
				table.insert(toscreen, {points, col})
			end
			for i, v in ipairs(toscreen) do
				render.DrawQuad(v[1][1], v[1][2], v[1][3], v[1][4], v[2])
			end
		end

	end

end

-------------------
-- ROTATION BALL --
-------------------
local ball = table.Copy(basepart)

do
	ball.IsBall = true

	function ball:GetGrabPos(eyepos, eyeang)
		local pos = eyepos
		local planepos = self:GetPos()
		local norm = (eyepos - planepos):GetNormalized()
		local intersect = rgm.IntersectRayWithPlane(planepos, -norm, pos, eyeang:Forward())
		return intersect
	end

	function ball:TestCollision(pl)
		if GetConVar("ragdollmover_drawsphere"):GetInt() <= 0 then return end 

		local plTable = RAGDOLLMOVER[pl]
		local plviewent = plTable.always_use_pl_view == 1 and pl or (plTable.PlViewEnt ~= 0 and Entity(plTable.PlViewEnt) or nil)
		local eyepos, eyeang = rgm.EyePosAng(pl, plviewent)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local distmin, distmax = self.collpositions[1], self.collpositions[2]
		local dist = intersect:Distance(self:GetPos())
		if dist >= distmin and dist <= distmax then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	function ball:CalculateGizmo(scale)
		self.collpositions = { 0, scale }
	end

	if SERVER then

		do
			function ball:ProcessMovement(_, offang, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, snapamount, startangle, _, nphysangle)
				local intersect = self:GetGrabPos(eyepos, eyeang)
				local localized = self:WorldToLocal(intersect)
				local _p, _a
				local axis = self.Parent
				local pl = axis.Owner
				local plTable = RAGDOLLMOVER[pl]

				local planeNormal = self:WorldToLocal(eyepos)

				local startpoint = startangle
				local delta = localized - startpoint

				local rotationAngle = delta:Length()
				rotationAngle = isnan(rotationAngle) and rotationAngle or 0
				if snapamount ~= 0 then
					rotationAngle = math.floor(rotationAngle / snapamount) * snapamount
				end
				local rotationAxis = planeNormal:Cross(delta):GetNormalized()
				rotationAxis = rotationAxis:IsZero() and vector_origin or rotationAxis

				if self.LastStartAngle ~= startangle then
					
					local _, lastAngle = ent:GetBonePosition(bone)
					if movetype == PHYSICAL_BONE then
						local physObj = ent:GetPhysicsObjectNum(bone)
						if IsValid(physObj) then
							lastAngle = physObj:GetAngles()
						end
					elseif movetype == NONPHYSICAL_BONE then
						lastAngle = ent:GetManipulateBoneAngles(bone)
					elseif movetype == PARENTED_BONE then
						lastAngle = ent:GetAngles()
					end
					self.LastAngle = lastAngle
					self.LastStartAngle = startangle
				end

				local ang = angle_zero * 1
				
				if movetype == PHYSICAL_BONE or movetype == PARENTED_BONE then
					ang:RotateAroundAxis(rotationAxis, rotationAngle)
					local pos = self:GetPos()

					local offset = plTable.GizmoOffset
					local entoffset = vector_origin
					if axis.localoffset and not axis.relativerotate then
						offset = LocalToWorld(offset, angle_zero, axis:GetPos(), axis.LocalAngles)
						offset = offset - axis:GetPos()
					end
					if ent.rgmPRoffset then
						entoffset = LocalToWorld(ent.rgmPRoffset, angle_zero, axis:GetPos(), axis.LocalAngles)
						entoffset = entoffset - axis:GetPos()
						offset = offset + entoffset
					end

					ang = self:LocalToWorldAngles(ang)
	
					_p, _a = LocalToWorld(vector_origin, self:WorldToLocalAngles(self.LastAngle), pos, ang)
					if axis.relativerotate then
						offset = WorldToLocal(axis.BonePos, angle_zero, axis:GetPos(), axis.LocalAngles)
						_p = LocalToWorld(offset, _a, pos, _a)
					else
						_p = pos - offset
					end
					if movetype == PARENTED_BONE then
						_a = ent:GetParent():WorldToLocalAngles(_a)
						_p = ent:GetParent():WorldToLocal(_p)
					end
				elseif movetype == NONPHYSICAL_BONE then
					local parent = ent:GetParent()
					local boneang = getBoneAngle(ent, parent, bone, axis, plTable)

					-- debugoverlay.Line(self:LocalToWorld(startangle), self:LocalToWorld(startangle + rotationAxis * 10), 0.1, Color(255, 0, 0), true)
					-- TODO: Find a rotation axis equivalent in bone manipulation space
					local _, rotationAxisAngle = WorldToLocal(vector_origin, rotationAxis:Angle(), vector_origin, self.LocalAng)
					local boneAxis = rotationAxisAngle:Forward()
					-- debugoverlay.Line(self:LocalToWorld(startangle), self:LocalToWorld(startangle + boneAxis * 10), 0.1, Color(0, 255, 0), true)

					ang:RotateAroundAxis(boneAxis, rotationAngle)
					_a = self.LastAngle - ang

					if axis.relativerotate then
						local pos = axis:GetPos()
						local offset

						local worldang
						_p, worldang = LocalToWorld(vector_origin, _a, pos, boneang)
						if axis.localoffset then
							offset = -plTable.GizmoOffset
							_p = LocalToWorld(offset, axis.LocalAngles, _p, worldang)
						else
							local _, oldang = LocalToWorld(vector_origin, nphysangle, vector_origin, axis.LocalAngles)
							offset = WorldToLocal(axis.BonePos, angle_zero, axis:GetPos(), oldang)
							_p = LocalToWorld(offset, angle_zero, _p, worldang)
						end
						_p = WorldToLocal(_p, angle_zero, axis.BonePos, axis.GizmoParent)
						local nonphyspos = WorldToLocal(axis.BonePos, angle_zero, axis.NMBonePos, axis.GizmoParent)
						_p = _p + nonphyspos
					else
						_p = ent:GetManipulateBonePosition(bone)
					end
				end

				return _p, _a
			end
		end
	end

	if CLIENT then
		function ball:DrawLines(yellow, scale)
			if GetConVar("ragdollmover_drawsphere"):GetInt() <= 0 then return end 

			local color = self:GetColor()
			color = Color(color[1], color[2], color[3], color[4])
			if yellow then
				color = COLOR_BRIGHT_YELLOW2
			end

			render.DrawSphere(self:GetPos(), scale, 50, 50, color)
		end
	end
end


-----------------
-- SCALE ARROW --
-----------------
local scalearrow = table.Copy(basepart)

do

	function scalearrow:GetGrabPos(eyepos, eyeang, ppos)
		local pos = eyepos
		local norm = eyeang:Forward()
		local planepos = self:GetPos()
		if ppos then planepos = ppos*1 end
		local planenorm = self:WorldToLocalAngles(self:GetAngles():Up():Angle())
		planenorm = Angle(planenorm.p, self:WorldToLocalAngles((self:GetPos() - eyepos):Angle()).y, planenorm.r)
		planenorm = self:LocalToWorldAngles(planenorm):Forward()
		local intersect = rgm.IntersectRayWithPlane(planepos, planenorm, pos, norm)
		return intersect
	end

	function scalearrow:TestCollision(pl)
		local plTable = RAGDOLLMOVER[pl]
		local plviewent = plTable.always_use_pl_view == 1 and pl or (plTable.PlViewEnt ~= 0 and Entity(plTable.PlViewEnt) or nil)
		local eyepos, eyeang = rgm.EyePosAng(pl, plviewent)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local localized = self:WorldToLocal(intersect)
		local distmin, distmax

		distmin = self.collpositions[1]
		distmax = self.collpositions[2]

		if localized.x >= distmin.x and localized.x <= distmax.x
		and localized.y >= distmin.y and localized.y <= distmax.y
		and localized.z >= distmin.z and localized.z <= distmax.z then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	function scalearrow:CalculateGizmo(scale)
		local distmin, distmax

		distmin = Vector(0, -0.075 * scale, -0.075 * scale)
		distmax = Vector(1 * scale, 0.075 * scale, 0.075 * scale)

		self.collpositions = {distmin, distmax}
	end

	if SERVER then

		function scalearrow:ProcessMovement(offpos, offang, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, _, startgrab, _, _, nphysscale)
			local intersect = self:GetGrabPos(eyepos, eyeang, ppos)
			local localized = self:WorldToLocal(intersect)
			local pos, ang

			pos = ent:GetManipulateBoneScale(bone)
			pos = pos*1 -- multiply by 1 to make a copy of the vector, in case if we scale advanced bonemerged item - those currently use modified ManipulateBoneX functions which seem to cause a bug if I keep altering vector given from GetManipulateBoneX stuff
			localized = Vector(localized.x - startgrab.x, 0, 0)
			local posadd = nphysscale[self.axistype] + localized.x
			ang = ent:GetManipulateBoneAngles(bone)
			pos[self.axistype] = posadd
			return pos, ang
		end

	end

	if CLIENT then

		function scalearrow:GetLinePositions(width)
			local RTable

			if self.Parent.width ~= width or not self.linepositions then
				RTable = {
					{Vector(0.075 * width, -0.075 * width, 0), Vector(0.97, -0.075 * width, 0), Vector( 0.97, 0.075 * width, 0), Vector(0.075 * width, 0.075 * width, 0)},
					{Vector(0.97, -0.0625 - 0.0625 * width, 0), Vector(1, -0.0625 - 0.0625 * width, 0), Vector(1, 0.0625 + 0.0625 * width, 0), Vector(0.97, 0.0625 + 0.0625 * width, 0)}
				}

				self.linepositions = RTable
			else
				RTable = self.linepositions
			end

			return RTable
		end

	end

end


----------------
-- SCALE SIDE --
----------------
local scaleside = table.Copy(posside)

do

	if SERVER then

		function scaleside:ProcessMovement(offpos, offang, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, _, startgrab, _, _, nphysscale)
			local intersect = self:GetGrabPos(eyepos, eyeang, ppos, pnorm)
			local pos, ang
			local axis = self.Parent
			local plTable = RAGDOLLMOVER[axis.Owner]

			local localized, finalpos, boneang
			if axis.EntAdvMerged then
				local parent = ent:GetParent()
				if parent.AttachedEntity then parent = parent.AttachedEntity end
				local funang
				if plTable.GizmoParentID ~= -1 then
					local physobj = parent:GetPhysicsObjectNum(plTable.GizmoParentID)
					_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, parent:GetPos(), parent:GetAngles())
				end
				if axis.EntAdvMerged then
					_, boneang = LocalToWorld(vector_origin, ent:GetManipulateBoneAngles(bone), vector_origin, boneang)
				end
			elseif ent:GetBoneCount() ~= 0 then
				if axis.GizmoAng then
					if plTable.GizmoParentID ~= -1 then
						local physobj = ent:GetPhysicsObjectNum(plTable.GizmoParentID)
						_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
					else
						_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, ent:GetPos(), ent:GetAngles())
					end
				else
					local matrix = ent:GetBoneMatrix(ent:GetBoneParent(bone))
					boneang = matrix:GetAngles()
				end
			else
				if IsValid(ent) then
					boneang = ent:GetAngles()
				else
					boneang = angle_zero
				end
			end

			localized = LocalToWorld(offpos, angle_zero, intersect, self:GetAngles())
			localized = WorldToLocal(localized, angle_zero, self:GetPos(), boneang)

			finalpos = nphysscale + localized
			ang = ent:GetManipulateBoneAngles(bone)
			pos = finalpos

			return pos, ang
		end

	end

end

local GIZMO_TYPES = {
	omnipos, -- POS OMNI [0]
	posarrow, -- POS ARROW [1]
	posside, -- POS SIDE [2]
	disc, -- ROT DISC [3]
	disclarge, -- ROT DISC BIG [4]
	ball, -- ROT BALL [5]
	scalearrow, -- SCALE ARROW [6]
	scaleside, -- SCALE SIDE [7]
}

-- Items that map to the gizmo classes in GIZMO_TYPES, so users who `CreateGizmo` can simply reference a name instead of a number 
RGMGIZMOS.GizmoTypeEnum = {
	OmniPos = 0,
	PosArrow = 1,
	PosSide = 2,
	Disc = 3,
	DiscLarge = 4,
	Ball = 5,
	ScaleArrow = 6,
	ScaleSide = 7
}

-- Nonphysical bones don't fare well with free rotations because of gimbal lock, so we disable certain gizmos that may cause them
local GimbalLockProne = {
	[RGMGIZMOS.GizmoTypeEnum.DiscLarge] = true,
	[RGMGIZMOS.GizmoTypeEnum.Ball] = true,
}

---------------
-- FUNCTIONS --
---------------
RGMGIZMOS.CreateGizmo = function(gizmotype, parent, color, offset, color2)
	local gizmo
	if not offset then offset = Angle(0, 0, 0) end

	gizmo = table.Copy(GIZMO_TYPES[gizmotype+1])
	gizmo.gizmotype = gizmotype
	gizmo.Parent = parent
	gizmo.AngOffset = offset
	gizmo.LocalAng = offset
	gizmo:SetColor(color)
	if color2 then
		gizmo:SetColor(color2, 2)
	end

	return gizmo
end

-- Check if the specified gizmo type can potentially cause gimbal locks for a certain condition
RGMGIZMOS.CanGimbalLock = function(gizmotype, condition)
	condition = Either(condition ~= nil, condition, true)
	return GimbalLockProne[gizmotype] and condition
end

-- Instead of explicitly making calls to CreateGizmo, create them using repeated calls to this
-- function, which automatically ids a gizmo in increasing order. This is an alternative to say,
-- storing the gizmo id per player
RGMGIZMOS.GizmoFactory = function()
	local id = 0
	local CreateGizmo = RGMGIZMOS.CreateGizmo
	return function(gizmotype, parent, color, offset, color2)
		id = id + 1
		local gizmo = CreateGizmo(gizmotype, parent, color, offset, color2)
		gizmo.id = id

		return gizmo
	end
end

RGMGIZMOS.GizmoTable = {
	"ArrowOmni",
	"ArrowX", "ArrowY", "ArrowZ",
	"ArrowXY", "ArrowXZ", "ArrowYZ",
	"Ball",
	"DiscP", "DiscY", "DiscR", "DiscLarge",
	"ScaleX", "ScaleY", "ScaleZ",
	"ScaleXY", "ScaleXZ", "ScaleYZ",
}
