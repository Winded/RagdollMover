RGMGIZMOS = {}

local VECTOR_FRONT = Vector(1, 0, 0)
local VECTOR_SIDE = Vector(0, 1, 0)
local COLOR_YELLOW = Color(255, 255, 0, 255)

----------------
-- BASE GIZMO --
----------------
local basepart = {}
do

	basepart.IsDisc = false
	basepart.Parent = nil
	basepart.AngOffset = Angle(0, 0, 0)
	basepart.LocalAng = Angle(0, 0, 0)
	basepart.Color = nil
	basepart.Color2 = nil
	basepart.width = 0
	basepart.scale = 0
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
	function basepart:TestCollision(pl, scale)
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
					col = COLOR_YELLOW
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

	function posarrow:TestCollision(pl, scale)
		local eyepos, eyeang = rgm.EyePosAng(pl)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local localized = self:WorldToLocal(intersect)
		local distmin, distmax

		if self.scale ~= scale or not self.collpositions then
			distmin	= Vector(0.1 * scale, -0.075 * scale, -0.075 * scale)
			distmax = Vector(1 * scale, 0.075 * scale, 0.075 * scale)

			self.scale = scale
			self.collpositions = {distmin, distmax}
		else
			distmin = self.collpositions[1]
			distmax = self.collpositions[2]
		end

		if localized.x >= distmin.x and localized.x <= distmax.x
		and localized.y >= distmin.y and localized.y <= distmax.y
		and localized.z >= distmin.z and localized.z <= distmax.z then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	if SERVER then

		function posarrow:ProcessMovement(offpos, _, eyepos, eyeang, ent, bone, ppos, _, movetype, _, _, nphyspos)
			local intersect = self:GetGrabPos(eyepos, eyeang, ppos)
			local axis = self.Parent
			local parent = ent:GetParent()
			local arrowAng = axis:LocalToWorldAngles(self.AngOffset)
			local localized = WorldToLocal(intersect, angle_zero, axis:GetPos(), arrowAng)
			local offset = axis.Owner.rgm.GizmoOffset
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

			if movetype == 1 then
				local obj = ent:GetPhysicsObjectNum(bone)
				localized = Vector(localized.x, 0, 0)
				intersect = LocalToWorld(localized, angle_zero, axis:GetPos(), arrowAng)
				ang = obj:GetAngles()
				pos = LocalToWorld(Vector(offpos.x, 0, 0), angle_zero, intersect - offset, selfangle)
			elseif movetype == 2 then
				local finalpos, boneang
				local pl = axis.Owner
				local advbones = nil
				if ent:GetClass() == "ent_advbonemerge" then
					advbones = ent.AdvBone_BoneInfo
				end

				if axis.EntAdvMerged then
					if parent.AttachedEntity then parent = parent.AttachedEntity end
					local funang
					if pl.rgm.GizmoParentID ~= -1 then
						local physobj = parent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
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
						if pl.rgm.GizmoParentID ~= -1 then
							local physobj = ent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
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
			elseif movetype == 0 then
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

			if self.width ~= width or not self.linepositions then
				RTable = {
					{Vector(0.1, -0.075 * width, 0), Vector(0.75, -0.075 * width, 0), Vector(0.75, 0.075 * width, 0), Vector(0.1, 0.075 * width, 0)},
					{Vector(0.75, -0.0625 - 0.0625 * width, 0), VECTOR_FRONT, VECTOR_FRONT, Vector(0.75, 0.0625 + 0.0625 * width, 0)}
				}

				self.width = width
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

	function posside:TestCollision(pl, scale)
		local eyepos, eyeang = rgm.EyePosAng(pl)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local localized = self:WorldToLocal(intersect)
		local distmin1, distmax1, distmin2, distmax2

		if self.scale ~= scale or not self.collpositions then
			distmin1 = Vector(-0.15 * scale, scale * 0.2, 0)
			distmax1 = Vector(0.15 * scale, scale * 0.3, scale * 0.3)
			distmin2 = Vector(-0.15 * scale, 0, scale * 0.2)
			distmax2 = Vector(0.15 * scale, scale * 0.3, scale * 0.3)

			self.scale = scale
			self.collpositions = {distmin1, distmax1, distmin2, distmax2}
		else
			distmin1 = self.collpositions[1]
			distmax1 = self.collpositions[2]
			distmin2 = self.collpositions[3]
			distmax2 = self.collpositions[4]
		end

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

	if SERVER then

		function posside:ProcessMovement(offpos, _, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, _, _, nphyspos)
			local intersect = self:GetGrabPos(eyepos, eyeang, ppos, pnorm)
			local axis = self.Parent
			local parent = ent:GetParent()
			local offset = axis.Owner.rgm.GizmoOffset
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

			if movetype == 1 then
				local obj = ent:GetPhysicsObjectNum(bone)
				ang = obj:GetAngles()
				pos = LocalToWorld(offpos, angle_zero, intersect - offset, self:GetAngles())
			elseif movetype == 2 then
				local localized, finalpos, boneang
				local advbones = nil
				if ent:GetClass() == "ent_advbonemerge" then
					advbones = ent.AdvBone_BoneInfo
				end

				if axis.EntAdvMerged then
					if parent.AttachedEntity then parent = parent.AttachedEntity end
					local pl = axis.Owner
					local funang
					if pl.rgm.GizmoParentID ~= -1 then
						local physobj = parent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
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
						local pl = axis.Owner
						if pl.rgm.GizmoParentID ~= -1 then
							local physobj = ent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
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
			elseif movetype == 0 then
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

			if self.width ~= width or not self.linepositions then
				RTable = {
					{Vector(0, 0.25 - 0.05 * width, 0), Vector(0, 0.25 - 0.05 * width, 0.25 - 0.05 * width), Vector(0, 0.25 + 0.05 * width, 0.25 + 0.05 * width), Vector(0, 0.25 + 0.05 * width, 0)},
					{Vector(0, 0, 0.25 - 0.05 * width), Vector(0, 0.25 - 0.05 * width, 0.25 - 0.05 * width), Vector(0, 0.25 + 0.05 * width, 0.25 + 0.05 * width), Vector(0, 0, 0.25 + 0.05 * width)}
				}

				self.width = width
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
					col = COLOR_YELLOW
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

	function omnipos:TestCollision(pl, scale)
		local eyepos, eyeang = rgm.EyePosAng(pl)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local localized = self:WorldToLocal(intersect)
		local distmin1, distmax1

		if self.scale ~= scale or not self.collpositions then
			distmin1 = Vector(-0.075 * scale, scale * (-0.08), scale * (-0.08))
			distmax1 = Vector(0.075 * scale, scale * 0.08, scale * 0.08)

			self.scale = scale
			self.collpositions = {distmin1, distmax1}
		else
			distmin1 = self.collpositions[1]
			distmax1 = self.collpositions[2]
		end

		if (localized.x >= distmin1.x and localized.x <= distmax1.x
		and localized.y >= distmin1.y and localized.y <= distmax1.y
		and localized.z >= distmin1.z and localized.z <= distmax1.z) then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	if SERVER then

		function omnipos:ProcessMovement(offpos, _, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, _, _, nphyspos, _, _, tracepos)
			local intersect = tracepos
			if not intersect then
				intersect = self:GetGrabPos(eyepos, eyeang, ppos, pnorm)
			end

			local axis = self.Parent
			local parent = ent:GetParent()
			local offset = axis.Owner.rgm.GizmoOffset
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

			if movetype == 1 then
				local obj = ent:GetPhysicsObjectNum(bone)
				ang = obj:GetAngles()
				pos = LocalToWorld(offpos, angle_zero, intersect - offset, self:GetAngles())
			elseif movetype == 2 then
				local localized, startmove, finalpos, boneang
				local advbones = nil
				if ent:GetClass() == "ent_advbonemerge" then
					advbones = ent.AdvBone_BoneInfo
				end

				if axis.EntAdvMerged then
					if parent.AttachedEntity then parent = parent.AttachedEntity end
					local pl = axis.Owner
					local funang
					if pl.rgm.GizmoParentID ~= -1 then
						local physobj = parent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
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
						local pl = axis.Owner
						if pl.rgm.GizmoParentID ~= -1 then
							local physobj = ent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
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
			elseif movetype == 0 then
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

			if self.width ~= width or not self.linepositions then
				RTable = {{Vector(0, -0.08 * width, -0.08 * width), Vector(0, -0.08 * width, 0.08 * width), Vector(0, 0.08 * width, 0.08 * width), Vector(0, 0.08 * width, -0.08 * width)}}

				self.width = width
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

	function disc:TestCollision(pl, scale)
		local eyepos, eyeang = rgm.EyePosAng(pl)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local distmin = 0.9 * scale
		local distmax = 1.1 * scale
		local dist = intersect:Distance(self:GetPos())
		if dist >= distmin and dist <= distmax then
			return {axis = self, hitpos = intersect}
		end
		return false
	end

	if SERVER then

		local function ConvertVector(vec, axistype)
			local result

			if axistype == 1 then
				result = Vector(-vec.x, vec.z, 0)
			elseif axistype == 2 then
				result = Vector(vec.x, vec.y, 0)
			elseif axistype == 3 then
				result = Vector(vec.y, vec.z, 0)
			else
				result = vec
			end

			return result
		end

		function disc:ProcessMovement(_, offang, eyepos, eyeang, ent, bone, ppos, pnorm, movetype, snapamount, startangle, _, nphysangle) -- initially i had a table instead of separate things for initial bone pos and angle, but sync command can't handle tables and i thought implementing a way to handle those would be too much hassle
			local intersect = self:GetGrabPos(eyepos, eyeang, ppos, pnorm)
			local localized = self:WorldToLocal(intersect)
			local _p, _a
			local axis = self.Parent
			local pl = axis.Owner

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

			local mfmod = math.fmod

			if movetype == 1 then
				local offset = axis.Owner.rgm.GizmoOffset
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
					local localAng = mfmod(localized.y, 360)
					if localAng > 181 then localAng = localAng - 360 end
					if localAng < -181 then localAng = localAng + 360 end

					local localStart = mfmod(startangle.y, 360)
					if localStart > 181 then localStart = localStart - 360 end
					if localStart < -181 then localStart = localStart + 360 end

					local diff = mfmod(localStart - localAng, 360)
					if diff > 181 then diff = diff - 360 end
					if diff < -181 then diff = diff + 360 end

					local mathfunc = nil
					if diff >= 0 then
						mathfunc = math.floor
					else
						mathfunc = math.ceil
					end

					rotationangle = startangle.y - (mathfunc(diff / snapamount) * snapamount)
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
			elseif movetype == 2 then
				local rotateang, axisangle
				local parent = ent:GetParent()
				axisangle = axistable[self.axistype]

				local _, boneang = ent:GetBonePosition(bone)
				if axis.EntAdvMerged then
					if parent.AttachedEntity then parent = parent.AttachedEntity end
					if pl.rgm.GizmoParentID ~= -1 then
						local physobj = parent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
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
				local startlocal = LocalToWorld(startangle, startangle:Angle(), vector_origin, axisangle) -- first we get our vectors into world coordinates, relative to the axis angles
				localized = LocalToWorld(localized, localized:Angle(), vector_origin, axisangle)
				localized = WorldToLocal(localized, localized:Angle(), vector_origin, boneang) -- then convert that vector to the angles of the bone
				startlocal = WorldToLocal(startlocal, startlocal:Angle(), vector_origin, boneang)

				localized = ConvertVector(localized, self.axistype)
				startlocal = ConvertVector(startlocal, self.axistype)

				localized = localized:Angle() - startlocal:Angle()

				local rotationangle = localized.y
				if snapamount ~= 0 then
					local localAng = mfmod(localized.y, 360)
					if localAng > 181 then localAng = localAng - 360 end
					if localAng < -181 then localAng = localAng + 360 end

					local mathfunc = math.floor
					if localAng < 0 then mathfunc = math.ceil end

					rotationangle = mathfunc(localAng / snapamount) * snapamount
				end

				if self.axistype == 4 then
					rotateang = nphysangle + localized
					_a = rotateang
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
						offset = -pl.rgm.GizmoOffset
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

			elseif movetype == 0 then
				local offset = axis.Owner.rgm.GizmoOffset
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
					local localAng = mfmod(localized.y, 360)
					if localAng > 181 then localAng = localAng - 360 end
					if localAng < -181 then localAng = localAng + 360 end

					local localStart = mfmod(startangle.y, 360)
					if localStart > 181 then localStart = localStart - 360 end
					if localStart < -181 then localStart = localStart + 360 end

					local diff = mfmod(localStart - localAng, 360)
					if diff > 181 then diff = diff - 360 end
					if diff < -181 then diff = diff + 360 end

					local mathfunc = nil
					if diff >= 0 then
						mathfunc = math.floor
					else
						mathfunc = math.ceil
					end

					rotationangle = startangle.y - (mathfunc(diff / snapamount) * snapamount)
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

			if self.width ~= width or not self.linepositions then
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
			local largedisc = parent.DiscLarge
			if not largedisc then return end

			local borderpos = largedisc:GetPos()
			local color = self:GetColor()
			color = Color(color[1], color[2], color[3], color[4])

			local moving = pl.rgm.Moving or false

			for i,v in ipairs(linetable) do
				local points = self:PointsToWorld(v, scale)
				local col = color
				if yellow then
					col = COLOR_YELLOW
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

	function disclarge:TestCollision(pl, scale)
		local eyepos, eyeang = rgm.EyePosAng(pl)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local distmin = 1.15 * scale
		local distmax = 1.35 * scale
		local dist = intersect:Distance(self:GetPos())
		if dist >= distmin and dist <= distmax then
			return {axis = self, hitpos = intersect}
		end
		return false
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
					col = COLOR_YELLOW
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

	function scalearrow:TestCollision(pl, scale)
		local eyepos, eyeang = rgm.EyePosAng(pl)
		local intersect = self:GetGrabPos(eyepos, eyeang)
		local localized = self:WorldToLocal(intersect)
		local distmin, distmax

		if self.scale ~= scale or not self.collpositions then
			distmin = Vector(0, -0.075 * scale, -0.075 * scale)
			distmax = Vector(1 * scale, 0.075 * scale, 0.075 * scale)

			self.scale = scale
			self.collpositions = {distmin, distmax}
		else
			distmin = self.collpositions[1]
			distmax = self.collpositions[2]
		end

		if localized.x >= distmin.x and localized.x <= distmax.x
		and localized.y >= distmin.y and localized.y <= distmax.y
		and localized.z >= distmin.z and localized.z <= distmax.z then
			return {axis = self, hitpos = intersect}
		end
		return false
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

			if self.width ~= width or not self.linepositions then
				RTable = {
					{Vector(0.075 * width, -0.075 * width, 0), Vector(0.97, -0.075 * width, 0), Vector( 0.97, 0.075 * width, 0), Vector(0.075 * width, 0.075 * width, 0)},
					{Vector(0.97, -0.0625 - 0.0625 * width, 0), Vector(1, -0.0625 - 0.0625 * width, 0), Vector(1, 0.0625 + 0.0625 * width, 0), Vector(0.97, 0.0625 + 0.0625 * width, 0)}
				}

				self.width = width
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
			local pl = axis.Owner

			local localized, finalpos, boneang
			if axis.EntAdvMerged then
				local parent = ent:GetParent()
				if parent.AttachedEntity then parent = parent.AttachedEntity end
				local funang
				if pl.rgm.GizmoParentID ~= -1 then
					local physobj = parent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
					_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, physobj:GetPos(), physobj:GetAngles())
				else
					_, boneang = LocalToWorld(vector_origin, axis.GizmoAng, parent:GetPos(), parent:GetAngles())
				end
				if axis.EntAdvMerged then
					_, boneang = LocalToWorld(vector_origin, ent:GetManipulateBoneAngles(bone), vector_origin, boneang)
				end
			elseif ent:GetBoneCount() ~= 0 then
				if axis.GizmoAng then
					if pl.rgm.GizmoParentID ~= -1 then
						local physobj = ent:GetPhysicsObjectNum(pl.rgm.GizmoParentID)
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


---------------
-- FUNCTIONS --
---------------
RGMGIZMOS.CreateGizmo = function(gizmotype, id, parent, color, offset, color2)
	local gizmo
	if not offset then offset = Angle(0, 0, 0) end

	if gizmotype == 0 then -- POS OMNI
		gizmo = table.Copy(omnipos)
	elseif gizmotype == 1 then -- POS ARROW
		gizmo = table.Copy(posarrow)
	elseif gizmotype == 2 then -- POS SIDE
		gizmo = table.Copy(posside)
	elseif gizmotype == 3 then -- ROT DISC
		gizmo = table.Copy(disc)
	elseif gizmotype == 4 then -- ROT DISC BIG
		gizmo = table.Copy(disclarge)
	elseif gizmotype == 5 then -- SCALE ARROW
		gizmo = table.Copy(scalearrow)
	elseif gizmotype == 6 then -- SCALE SIDE
		gizmo = table.Copy(scaleside)
	end

	gizmo.id = id
	gizmo.Parent = parent
	gizmo.AngOffset = offset
	gizmo.LocalAng = offset
	gizmo:SetColor(color)
	if color2 then
		gizmo:SetColor(color2, 2)
	end

	return gizmo
end

RGMGIZMOS.GizmoTable = {
	"ArrowOmni",
	"ArrowX", "ArrowY", "ArrowZ",
	"ArrowXY", "ArrowXZ", "ArrowYZ",
	"DiscP", "DiscY", "DiscR", "DiscLarge",
	"ScaleX", "ScaleY", "ScaleZ",
	"ScaleXY", "ScaleXZ", "ScaleYZ"
}
