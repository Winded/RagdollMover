-- load gizmos library
include("ragdollmover/rgm_gizmos.lua")
AddCSLuaFile("ragdollmover/rgm_gizmos.lua")

--[[
	rgm module
	Various functions used by Ragdoll Mover tool, and the axis entities.
]]

module("rgm", package.seeall)

--[[	Line-Plane intersection, and return the result vector
	I honestly cannot explain this at all. I just followed this tutorial:
	http://www.wiremod.com/forum/expression-2-discussion-help/19008-line-plane-intersection-tutorial.html
	Lots of cookies for the guy who made it]]
function IntersectRayWithPlane(planepoint, norm, line, linenormal)
	local linepoint = line*1
	local linepoint2 = linepoint + linenormal
	local x = (norm:Dot(planepoint - linepoint)) / (norm:Dot(linepoint2 - linepoint))
	local vec = linepoint + x * (linepoint2 - linepoint)
	return vec
end

local VECTOR_ONE = Vector(1, 1, 1)

--Receives player eye position and eye angles.
--If cursor is visible, eye angles are based on cursor position.
function EyePosAng(pl)
	local eyepos = pl:EyePos()
	local viewent = pl:GetViewEntity()
	if IsValid(viewent) and viewent ~= pl then
		eyepos = viewent:GetPos()
	end
	local cursorvec = pl:GetAimVector()
	--local cursorvec = pl:EyeAngles()
	return eyepos, cursorvec:Angle()
end

function AbsVector(vec)
	return Vector(math.abs(vec.x), math.abs(vec.y), math.abs(vec.z))
end

--Default IK chain tables

local DefaultIK = {}

table.insert(DefaultIK,{
	hip = "ValveBiped.Bip01_L_Thigh",
	knee = "ValveBiped.Bip01_L_Calf",
	foot = "ValveBiped.Bip01_L_Foot",
	type = 1
})
table.insert(DefaultIK,{
	hip = "bip_hip_L",
	knee = "bip_knee_L",
	foot = "bip_foot_L",
	type = 1
})
table.insert(DefaultIK,{
	hip = "LeftHip",
	knee = "LeftKnee",
	foot = "LeftAnkle",
	type = 1
})

table.insert(DefaultIK,{
	hip = "ValveBiped.Bip01_R_Thigh",
	knee = "ValveBiped.Bip01_R_Calf",
	foot = "ValveBiped.Bip01_R_Foot",
	type = 2
})
table.insert(DefaultIK,{
	hip = "bip_hip_R",
	knee = "bip_knee_R",
	foot = "bip_foot_R",
	type = 2
})
table.insert(DefaultIK,{
	hip = "RightHip",
	knee = "RightKnee",
	foot = "RightAnkle",
	type = 2
})

--For simplicity, we'll just call the arm IK parts hip, knee and foot aswell.
table.insert(DefaultIK,{
	hip = "ValveBiped.Bip01_L_UpperArm",
	knee = "ValveBiped.Bip01_L_Forearm",
	foot = "ValveBiped.Bip01_L_Hand",
	type = 3
})
table.insert(DefaultIK,{
	hip = "bip_upperArm_L",
	knee = "bip_lowerArm_L",
	foot = "bip_hand_L",
	type = 3
})
table.insert(DefaultIK,{
	hip = "LeftShoulder",
	knee = "LeftElbow",
	foot = "ValveBiped.Bip01_L_Hand",
	type = 3
})

table.insert(DefaultIK,{
	hip = "ValveBiped.Bip01_R_UpperArm",
	knee = "ValveBiped.Bip01_R_Forearm",
	foot = "ValveBiped.Bip01_R_Hand",
	type = 4
})
table.insert(DefaultIK,{
	hip = "bip_upperArm_R",
	knee = "bip_lowerArm_R",
	foot = "bip_hand_R",
	type = 4
})
table.insert(DefaultIK,{
	hip = "RightShoulder",
	knee = "RightElbow",
	foot = "ValveBiped.Bip01_R_Hand",
	type = 4
})

-----
--Bone Movement library (functions to make ragdoll bones move relatively to their parent bones, or with IK chains)
-----

function BoneToPhysBone(ent, bone)
	for i = 0, ent:GetPhysicsObjectCount() - 1 do
		local b = ent:TranslatePhysBoneToBone(i)
		if bone == b then return i end
	end
	return nil
end

function GetPhysBoneParent(ent, bone)
	if not bone then return nil end
	local b = ent:TranslatePhysBoneToBone(bone)
	local cont = false
	local i = 1
	while not cont do
		b = ent:GetBoneParent(b)
		local parent = BoneToPhysBone(ent, b)
		if parent and parent ~= bone then
			return parent
		end
		i = i + 1
		if i > 256 then
			cont = true
		end
	end
	return nil
end

local DefIKnames = {
	"ik_leg_L",
	"ik_leg_R",
	"ik_hand_L",
	"ik_hand_R",
	"ik_chain_1",
	"ik_chain_2",
	"ik_chain_3",
	"ik_chain_4",
	"ik_chain_5",
	"ik_chain_6"
}


--Functions for offset table generation
local function GetRootBones(parent, physobj, obj1, obj2, RTable)
	RTable[physobj] = {}
	if parent then
		local pos1, ang1 = obj1:GetPos(), obj1:GetAngles()
		local pos2, ang2 = obj2:GetPos(), obj2:GetAngles()
		local pos3, ang3 = WorldToLocal(pos1, ang1, pos2, ang2)
		RTable[physobj] = {pos = pos3, ang = ang3, parent = parent.id}
	else
		local pos, ang = obj1:GetPos(), obj1:GetAngles()

		RTable[physobj].pos = pos
		RTable[physobj].ang = ang
		RTable[physobj].root = true
	end
	RTable[physobj].moving = obj1:IsMoveable()
end

local function GetBones(bonelock, parent, pb, obj1, obj2, RTable)
	local pos1, ang1 = obj1:GetPos(), obj1:GetAngles()
	local pos2, ang2 = obj2:GetPos(), obj2:GetAngles()
	local pos3, ang3 = WorldToLocal(pos1, ang1, pos2, ang2)
	local mov = obj1:IsMoveable()

	RTable[pb] = {pos = pos3, ang = ang3, moving = mov, parent = parent, lock = bonelock and true or nil}
end

--Get bone offsets from parent bones, and update IK data.
function GetOffsetTable(tool, ent, rotate, bonelocks, entlocks)
	local RTable = {}
	local physcount = ent:GetPhysicsObjectCount() - 1
	local propragdoll = false
	if ent.rgmPRidtoent then
		physcount = #ent.rgmPRidtoent
		propragdoll = true
	end

	if not ent.rgmIKChains then
		CreateDefaultIKs(tool, ent)
	end

	for a = 0, physcount do -- getting all "root" bones - so it'll work for ragdoll with detached bones.
		if not propragdoll then

			local Bone = ent:TranslatePhysBoneToBone(a)
			local Parent = ent:GetBoneParent(Bone)
			if ent:TranslateBoneToPhysBone(Parent) == -1 or not GetPhysBoneParent(ent, a) then -- root physbones seem to be "parented" to the -1. and the physboneparent function will not find its parent either.
				local obj1 = ent:GetPhysicsObjectNum(a)
				local obj2 = nil
				if bonelocks[ent][a] then
					obj2 = ent:GetPhysicsObjectNum(bonelocks[ent][a].id)
				end
				GetRootBones(bonelocks[ent][a], a, obj1, obj2, RTable)
			end

		else

			local thisent = ent.rgmPRidtoent[a]
			if not thisent.rgmPRparent then
				local obj1 = thisent:GetPhysicsObjectNum(0)
				local obj2 = nil
				local ent2 = nil
				if bonelocks[thisent][a] then
					ent2 = bonelocks[thisent][a].ent
					obj2 = ent2:GetPhysicsObjectNum(0)
				end
				GetRootBones(bonelocks[thisent][a], a, obj1, obj2, RTable, ent, ent2)
				RTable[a].ent = thisent
			end

		end
	end

	for pb = 0, physcount do
		if not propragdoll then

			local parent = GetPhysBoneParent(ent, pb)
			if bonelocks[ent][pb] then
				parent = bonelocks[ent][pb].id
			end

			if pb and parent and not RTable[pb] then
				local obj1 = ent:GetPhysicsObjectNum(pb)
				local obj2 = ent:GetPhysicsObjectNum(parent)
				GetBones(bonelocks[ent][pb], parent, pb, obj1, obj2, RTable)
				local iktable = IsIKBone(tool, ent, pb)
				if iktable then
					RTable[pb].isik = true
				end
			end

		else

			local thisent = ent.rgmPRidtoent[pb]
			local parent = thisent.rgmPRparent
			if bonelocks[thisent][pb] then
				parent = bonelocks[thisent][pb].id
			end

			if pb and parent and not RTable[pb] then
				local obj1 = thisent:GetPhysicsObjectNum(0)
				local obj2 = ent.rgmPRidtoent[parent]:GetPhysicsObjectNum(0)
				GetBones(bonelocks[thisent][pb], parent, pb, obj1, obj2, RTable)
				RTable[pb].ent = thisent
				local iktable = IsIKBone(tool, ent, pb)
				if iktable then
					RTable[pb].isik = true
				end
			end

		end
	end

	for k, v in pairs(ent.rgmIKChains) do

		local obj1, obj2, obj3 = nil, nil, nil
		local ent1, ent2, ent3 = nil, nil, nil

		if not propragdoll then
			obj1 = ent:GetPhysicsObjectNum(v.hip)
			obj2 = ent:GetPhysicsObjectNum(v.knee)
			obj3 = ent:GetPhysicsObjectNum(v.foot)
		else
			ent1 = ent.rgmPRidtoent[v.hip]
			ent2 = ent.rgmPRidtoent[v.knee]
			ent3 = ent.rgmPRidtoent[v.foot]

			obj1 = ent1:GetPhysicsObjectNum(0)
			obj2 = ent2:GetPhysicsObjectNum(0)
			obj3 = ent3:GetPhysicsObjectNum(0)
		end

		local pos1, pos2, pos3 = obj1:GetPos(), obj2:GetPos(), obj3:GetPos()
		local hippos = RTable[v.hip].pos*1

		if ent1 and ent1.rgmPRoffset then
			local parent = RTable[v.hip].parent
			local offset = ent1.rgmPRoffset
			if parent and RTable[parent].ent then
				local pent = RTable[parent].ent
				offset = LocalToWorld(offset, angle_zero, pos1, obj1:GetAngles())
				offset = WorldToLocal(offset, obj1:GetAngles(), pent:GetPos(), pent:GetAngles())
				hippos = offset
			else
				hippos = LocalToWorld(offset, angle_zero, pos1, obj1:GetAngles())
			end
			pos1 = LocalToWorld(ent1.rgmPRoffset, angle_zero, pos1, obj1:GetAngles())
		end
		if ent2 and ent2.rgmPRoffset then
			pos2 = LocalToWorld(ent2.rgmPRoffset, angle_zero, pos2, obj2:GetAngles())
		end
		if ent3 and ent3.rgmPRoffset then
			pos3 = LocalToWorld(ent3.rgmPRoffset, angle_zero, pos3, obj3:GetAngles())
		end

		ent.rgmIKChains[k].rotate = rotate

		local kneedir = GetKneeDir(ent, v.hip, v.knee, v.foot)

		ent.rgmIKChains[k].ikhippos = hippos
		if RTable[v.hip].parent then
			ent.rgmIKChains[k].ikhipparent = RTable[v.hip].parent*1
		end
		local ang, offang = GetAngleOffset(ent, v.hip, v.knee)
		ent.rgmIKChains[k].ikhipang = ang*1
		ent.rgmIKChains[k].ikhipoffang = offang*1

		ent.rgmIKChains[k].ikkneedir = kneedir
		ang, offang = GetAngleOffset(ent, v.knee, v.foot)
		ent.rgmIKChains[k].ikkneeang = ang*1
		ent.rgmIKChains[k].ikkneeoffang = offang*1

		ent.rgmIKChains[k].ikfootpos = pos3
		ent.rgmIKChains[k].ikfootang = obj3:GetAngles()

		ent.rgmIKChains[k].thighlength = pos1:Distance(pos2)
		ent.rgmIKChains[k].shinlength = pos2:Distance(pos3)

		ent.rgmIKChains[k].nphyship = nil

	end

	for lockent, pb in pairs(entlocks) do -- getting offsets from physical entities that are locked to our bones
		if not RTable[pb.id].locked then
			RTable[pb.id].locked = {}
		end

		local locktable = {}

		for i=0, lockent:GetPhysicsObjectCount() - 1 do
			local obj1 = lockent:GetPhysicsObjectNum(i)
			local obj2 = pb.ent:GetPhysicsObjectNum(propragdoll and 0 or pb.id)
			local pos1, ang1 = obj1:GetPos(), obj1:GetAngles()
			local pos2, ang2 = obj2:GetPos(), obj2:GetAngles()
			local pos3, ang3 = WorldToLocal(pos1, ang1, pos2, ang2)
			local mov = obj1:IsMoveable()

			locktable[i] = {pos = pos3, ang = ang3, moving = mov, parent = -1}
		end

		RTable[pb.id].locked[lockent] = locktable
	end

	return RTable
end

function GetNPOffsetTable(tool, ent, rotate, nphysinfo, nphyschildren, bonelocks, entlocks)
	local RTable = {}
	local physcount = ent:GetPhysicsObjectCount() - 1

	if not ent.rgmIKChains then
		CreateDefaultIKs(tool, ent)
	end

	for a = 0, physcount do -- getting all "root" bones - so it'll work for ragdoll with detached bones.
		local Bone = ent:TranslatePhysBoneToBone(a)
		local Parent = ent:GetBoneParent(Bone)
		if ent:TranslateBoneToPhysBone(Parent) == -1 or not GetPhysBoneParent(ent, a) then -- root physbones seem to be "parented" to the -1. and the physboneparent function will not find its parent either.
			local obj1 = ent:GetPhysicsObjectNum(a)
			local obj2 = nil
			if bonelocks[ent][a] then
				obj2 = ent:GetPhysicsObjectNum(bonelocks[ent][a].id)
			end
			GetRootBones(bonelocks[ent][a], a, obj1, obj2, RTable)
		end
	end

	for pb = 0, physcount do
		local parent = GetPhysBoneParent(ent, pb)
		if bonelocks[ent][pb] then
			parent = bonelocks[ent][pb].id
		end

		if pb and parent and not RTable[pb] then
			local obj1 = ent:GetPhysicsObjectNum(pb)
			local obj2 = ent:GetPhysicsObjectNum(parent)
			GetBones(bonelocks[ent][pb], parent, pb, obj1, obj2, RTable)
			local iktable = IsIKBone(tool, ent, pb)
			if iktable then
				RTable[pb].isik = true
			end
		end
	end

	do
		local parent = nphysinfo.p
		local obj = ent:GetPhysicsObjectNum(parent)
		local npos, nang = LocalToWorld(nphysinfo.pos, nphysinfo.ang, obj:GetPos(), obj:GetAngles())
		RTable[parent].nppos, RTable[parent].npang = nphysinfo.pos, nphysinfo.ang
		for physbone, data in pairs(nphyschildren) do
			if data.depth == 1 and not RTable[physbone].lock then
				RTable[physbone].nphysbone = true
				local obj = ent:GetPhysicsObjectNum(physbone)
				local pos, ang = WorldToLocal(obj:GetPos(), obj:GetAngles(), npos, nang)
				RTable[physbone].pos = pos
				RTable[physbone].ang = ang
			end
		end
	end

	for k, v in pairs(ent.rgmIKChains) do

		local obj1, obj2, obj3 = ent:GetPhysicsObjectNum(v.hip), ent:GetPhysicsObjectNum(v.knee), ent:GetPhysicsObjectNum(v.foot)

		local pos1, pos2, pos3 = obj1:GetPos(), obj2:GetPos(), obj3:GetPos()
		local hippos = RTable[v.hip].pos*1

		ent.rgmIKChains[k].rotate = rotate

		local kneedir = GetKneeDir(ent, v.hip, v.knee, v.foot)

		ent.rgmIKChains[k].ikhippos = hippos
		if RTable[v.hip].parent then
			ent.rgmIKChains[k].ikhipparent = RTable[v.hip].parent*1
		end
		local ang, offang = GetAngleOffset(ent, v.hip, v.knee)
		ent.rgmIKChains[k].ikhipang = ang*1
		ent.rgmIKChains[k].ikhipoffang = offang*1

		ent.rgmIKChains[k].ikkneedir = kneedir
		ang, offang = GetAngleOffset(ent, v.knee, v.foot)
		ent.rgmIKChains[k].ikkneeang = ang*1
		ent.rgmIKChains[k].ikkneeoffang = offang*1

		ent.rgmIKChains[k].ikfootpos = pos3
		ent.rgmIKChains[k].ikfootang = obj3:GetAngles()

		ent.rgmIKChains[k].thighlength = pos1:Distance(pos2)
		ent.rgmIKChains[k].shinlength = pos2:Distance(pos3)

		ent.rgmIKChains[k].nphyship = RTable[v.hip].nphysbone

	end

	for lockent, pb in pairs(entlocks) do -- getting offsets from physical entities that are locked to our bones
		if not RTable[pb.id].locked then
			RTable[pb.id].locked = {}
		end

		local locktable = {}

		for i=0, lockent:GetPhysicsObjectCount() - 1 do
			local obj1 = lockent:GetPhysicsObjectNum(i)
			local obj2 = pb.ent:GetPhysicsObjectNum(pb.id)
			local pos1, ang1 = obj1:GetPos(), obj1:GetAngles()
			local pos2, ang2 = obj2:GetPos(), obj2:GetAngles()
			local pos3, ang3 = WorldToLocal(pos1, ang1, pos2, ang2)
			local mov = obj1:IsMoveable()

			locktable[i] = {pos = pos3, ang = ang3, moving = mov, parent = -1}
		end

		RTable[pb.id].locked[lockent] = locktable
	end

	return RTable
end

local function RecursiveSetParent(ostable, sbone, ent, rlocks, plocks, RTable, bone, nphysinfo)

	local parent = ostable[bone].parent
	local nphys = nil
	if not RTable[parent] then RecursiveSetParent(ostable, sbone, ent, rlocks, plocks, RTable, parent, nphysinfo) end
	if ostable[bone].ent then
		ent = ostable[bone].ent
	end

	local ppos, pang
	if not ostable[bone].nphysbone then
		ppos, pang = RTable[parent].pos, RTable[parent].ang
	else
		ppos = nphysinfo.pos
		pang = nphysinfo.ang
		nphys = true
	end
	local pos, ang = LocalToWorld(ostable[bone].pos, ostable[bone].ang, ppos, pang)
	if bone == sbone.b then
		pos = sbone.p
		ang = sbone.a
	else
		if rlocks[ent] and IsValid(rlocks[ent][bone]) then
			ang = rlocks[ent][bone]:GetAngles()
		end
		if plocks[ent] and IsValid(plocks[ent][bone]) then
			pos = plocks[ent][bone]:GetPos()
		end
	end
	RTable[bone] = {}
	RTable[bone].pos = pos*1
	RTable[bone].ang = ang*1
	RTable[bone].nphys = nphys
end

--Set bone positions from the local positions on the offset table.
--And process IK chains.
function SetOffsets(tool, ent, ostable, sbone, rlocks, plocks, nphysinfo)
	local RTable = {}

	local propragdoll = false
	local physcount = ent:GetPhysicsObjectCount() - 1
	if ent.rgmPRidtoent then
		propragdoll = true
		physcount = #ent.rgmPRidtoent
	end

	for id, value in pairs(ostable) do
		if value.root then
			RTable[id] = {}
			RTable[id].pos = value.pos
			RTable[id].ang = value.ang
			if sbone.b == id then
				RTable[id].pos = sbone.p
				RTable[id].ang = sbone.a
			end
		end
	end

	for k, v in pairs(ent.rgmIKChains) do
		if tool:GetClientNumber(DefIKnames[v.type]) ~= 0 then
			if v.ikhipparent then
				if not RTable[v.ikhipparent] then RecursiveSetParent(ostable, sbone, ent, rlocks, plocks, RTable, v.ikhipparent, nphysinfo) end
			end

			local footdata = ostable[v.foot]
			if footdata ~= nil and (footdata.parent ~= v.knee and footdata.parent ~= v.hip) and not RTable[footdata.parent] and footdata.lock then 
				RecursiveSetParent(ostable, sbone, ent, rlocks, plocks, RTable, footdata.parent, nphysinfo)
			end

			local RT = ProcessIK(ent, v, sbone, RTable, footdata, nphysinfo)
			table.Merge(RTable, RT)
		end
	end

	for k, v in pairs(ent.rgmIKChains) do -- calculating IKs twice for proper bone locking stuff to IKs, perhaps there is a simpler way to do these
		if tool:GetClientNumber(DefIKnames[v.type]) ~= 0 then

			local footdata = ostable[v.foot]
			if not RTable[footdata.parent] then
				RecursiveSetParent(ostable, sbone, ent, rlocks, plocks, RTable, footdata.parent, nphysinfo)
			end

			local RT = ProcessIK(ent, v, sbone, RTable, footdata, nphysinfo)
			table.Merge(RTable, RT)
		end
	end

	for pb = 0, physcount do
		if ostable[pb] and not RTable[pb] then
			RecursiveSetParent(ostable, sbone, ent, rlocks, plocks, RTable, pb, nphysinfo)
		end
	end

	if propragdoll then
		for pb = 0, physcount do
			value = ostable[pb]
			if value.ent and value.ent.rgmPRoffset and not value.isik then
				local offset = value.ent.rgmPRoffset
				local _p, _a = LocalToWorld(-offset, value.ent:GetAngles(), RTable[pb].pos, RTable[pb].ang)
				_p = LocalToWorld(offset, angle_zero, _p, value.ent:GetAngles())
				RTable[pb].pos = _p
			end
		end
	end

	for i = 0, physcount do
		if not ostable[i].locked then continue end

		for lockent, bones in pairs(ostable[i].locked) do
			if not RTable[i].locked then
				RTable[i].locked = {}
			end
			RTable[i].locked[lockent] = {}
			RTable[i].locked[lockent][-1] = {pos = RTable[i].pos, ang = RTable[i].ang}

			for j = 0, lockent:GetPhysicsObjectCount() - 1 do
				if bones[j] and not RTable[i].locked[lockent][j] then
					RecursiveSetParent(bones, {}, ent, {}, {}, RTable[i].locked[lockent], j)
				end
			end
		end
	end

	return RTable
end

local function RecursiveSetScale(ostable, sbone, ent, plocks, slocks, RTable, bone, scale, scalechildren, nphysinfo, childrenbones)

	local npbone = ent:TranslatePhysBoneToBone(bone)
	local npparent = ent:GetBoneParent(npbone)
	local parent = ostable[bone].parent
	local nphys = nil
	if not RTable[parent] then RecursiveSetScale(ostable, sbone, ent, plocks, slocks, RTable, parent, scale, scalechildren, nphysinfo, childrenbones) end

	local ppos, pang = RTable[parent].pos, RTable[parent].ang
	local bsc = RTable[parent].sc

	local pos, ang, sc
	if scalechildren then
		sc = RTable[parent].sc
	else
		local scaleorig
		if ostable[bone].nphysbone then
			scaleorig = nphysinfo.b
		elseif sbone.b then
			scaleorig = ent:TranslatePhysBoneToBone(sbone.b)
		else
			scaleorig = -2
		end
		sc = (npparent == scaleorig) and scale or VECTOR_ONE
	end

	if ostable[bone].nphysbone then
		ppos = nphysinfo.pos
		pang = nphysinfo.ang
		bsc = scale
	end

	if childrenbones and childrenbones[npparent] and childrenbones[npparent][npbone] and childrenbones[npparent][npbone].wpos then
		pos, ang = LocalToWorld(ostable[bone].pos, ostable[bone].ang, ppos, pang)
		pos = childrenbones[npparent][npbone].wpos
	else
		pos, ang = LocalToWorld(ostable[bone].pos * sc, ostable[bone].ang, ppos, pang)
	end

	if bone == sbone.b then
		bsc = scale
		pos = sbone.p
		ang = sbone.a
	else
		if plocks[ent] and IsValid(plocks[ent][bone]) then
			pos = plocks[ent][bone]:GetPos()
		end
		if slocks[ent] and slocks[ent][npbone] then
			bsc = VECTOR_ONE
		end
	end
	RTable[bone] = {}
	RTable[bone].pos = pos*1
	RTable[bone].ang = ang*1
	RTable[bone].sc = bsc
end

function SetScaleOffsets(tool, ent, ostable, sbone, scale, plocks, slocks, scalechildren, nphysinfo, childrenbones)
	local RTable = {}

	local physcount = ent:GetPhysicsObjectCount() - 1

	for id, value in pairs(ostable) do
		if value.root then
			RTable[id] = {}
			RTable[id].pos = value.pos
			RTable[id].ang = value.ang
			RTable[id].sc = VECTOR_ONE
			if sbone.b == id then
				RTable[id].pos = sbone.p
				RTable[id].ang = sbone.a
				RTable[id].sc = scale
			end
		end
	end

	for pb = 0, physcount do
		if ostable[pb] and not RTable[pb] then
			RecursiveSetScale(ostable, sbone, ent, plocks, slocks, RTable, pb, scale, scalechildren, nphysinfo, childrenbones)
		end
	end

	for i = 0, physcount do
		if not ostable[i].locked then continue end

		for lockent, bones in pairs(ostable[i].locked) do
			if not RTable[i].locked then
				RTable[i].locked = {}
			end
			RTable[i].locked[lockent] = {}
			RTable[i].locked[lockent][-1] = {pos = RTable[i].pos, ang = RTable[i].ang, sc = VECTOR_ONE}

			for j = 0, lockent:GetPhysicsObjectCount() - 1 do
				if bones[j] and not RTable[i].locked[lockent][j] then
					RecursiveSetScale(bones, {}, ent, {}, {}, RTable[i].locked[lockent], j, scale, scalechildren)
				end
			end
		end
	end

	return RTable
end


-----
--Inverse kinematics library
-----

--[[	Key function for IK chains: finding the knee position (in case of arms, it's elbow position)
	Once again, a math function, which I didn't fully make myself, and cannot explain much.
	Only that the arguments in order are: hip position, ankle position, thigh length, shin length, knee vector direction.

	Got the math from this thread:
	http://forum.unity3d.com/threads/40431-IK-Chain
]]
function FindKnee(pHip, pAnkle, fThigh, fShin, vKneeDir)
	local vB = pAnkle - pHip
    local LB = vB:Length()
    local aa = (LB * LB + fThigh * fThigh - fShin * fShin) / 2 / LB
    local bb = math.sqrt(math.abs(fThigh * fThigh - aa * aa))
    local vF = vB:Cross(vKneeDir:Cross(vB))
	vB:Normalize()
	vF:Normalize()
    return pHip + (aa * vB) + (bb * vF)
end

--Process one IK chain, and set it's positions.
function ProcessIK(ent, IKTable, sbone, RT, footlock, nphysinfo)

	local propragdoll = ent.rgmPRidtoent and true or false

	local RTable = {}

	local hippos = IKTable.ikhippos
	local hipang = IKTable.ikhipang
	local hipoffang = IKTable.ikhipoffang
	local kneedir = IKTable.ikkneedir
	local kneeang = IKTable.ikkneeang
	local kneeoffang = IKTable.ikkneeoffang
	local footpos = IKTable.ikfootpos
	local footang = IKTable.ikfootang
	local thighlength = IKTable.thighlength
	local shinlength = IKTable.shinlength

	local hpos, hang

	if IKTable.ikhipparent then
		obj = RT[IKTable.ikhipparent]
		if not IKTable.nphyship then
			hpos, hang = LocalToWorld(hippos, angle_zero, obj.pos, obj.ang)
		else
			hpos, hang = LocalToWorld(hippos, angle_zero, nphysinfo.pos, nphysinfo.ang)
		end
	else
		hpos, hang = LocalToWorld(hippos, angle_zero, vector_origin, angle_zero)
	end
	hippos = hpos*1

	local anklepos, ankleang
	if IKTable.foot == sbone.b then
		anklepos, ankleang = sbone.p, sbone.a

		if propragdoll then
			local ent3 = ent.rgmPRidtoent[IKTable.foot]
			if ent3 and ent3.rgmPRoffset then
				anklepos = LocalToWorld(ent3.rgmPRoffset, angle_zero, anklepos, ankleang)
			end
		end

	elseif footlock ~= nil and footlock.lock and IKTable.knee ~= footlock.parent and IKTable.hip ~= footlock.parent then
		anklepos, ankleang = LocalToWorld(footlock.pos, footlock.ang, RT[footlock.parent].pos, RT[footlock.parent].ang)
	else
		anklepos, ankleang = footpos*1, footang*1
	end
	local ankledist = anklepos:Distance(hippos)
	if ankledist > (thighlength + shinlength) then
		local anklenorm = (anklepos - hippos)
		anklenorm:Normalize()
		anklepos = hippos + (anklenorm * (thighlength + shinlength))
	end

	local kneepos = FindKnee(hippos, anklepos, thighlength, shinlength, kneedir)
	hang = SetAngleOffset(ent, hippos, (kneepos - hippos):Angle(), hipang, hipoffang)
	hipang = hang*1
	hang = SetAngleOffset(ent, kneepos, (anklepos - kneepos):Angle(), kneeang, kneeoffang)
	kneeang = hang*1

	if propragdoll then
		local ent1, ent2, ent3 = ent.rgmPRidtoent[IKTable.hip], ent.rgmPRidtoent[IKTable.knee], ent.rgmPRidtoent[IKTable.foot]

		if ent1 and ent1.rgmPRoffset then
			hippos = LocalToWorld(-ent1.rgmPRoffset, angle_zero, hippos, hipang)
		end
		if ent2 and ent2.rgmPRoffset then
			kneepos = LocalToWorld(-ent2.rgmPRoffset, angle_zero, kneepos, kneeang)
		end
		if ent3 and ent3.rgmPRoffset then
			anklepos = LocalToWorld(-ent3.rgmPRoffset, angle_zero, anklepos, ankleang)
		end
	end

	RTable[IKTable.hip] = {pos = hippos, ang = hipang}
	RTable[IKTable.knee] = {pos = kneepos, ang = kneeang}
	if IKTable.rotate and sbone.b == IKTable.hip then
		RTable[IKTable.hip].dontset = true
	elseif IKTable.rotate and sbone.b == IKTable.knee then
		RTable[IKTable.knee].dontset = true
	end
	RTable[IKTable.foot] = {pos = anklepos, ang = ankleang}

	return RTable

end

function NormalizeAngle(ang)
	local RAng = Angle()
	RAng.p = math.NormalizeAngle(ang.p)
	RAng.y = math.NormalizeAngle(ang.y)
	RAng.r = math.NormalizeAngle(ang.r)
	return RAng
end

function GetAngleOffset(ent, b1, b2)
	local obj1, obj2 = nil, nil
	local ent1, ent2 = nil, nil

	if not ent.rgmPRidtoent then
		obj1 = ent:GetPhysicsObjectNum(b1)
		obj2 = ent:GetPhysicsObjectNum(b2)
	else
		ent1 = ent.rgmPRidtoent[b1]
		ent2 = ent.rgmPRidtoent[b2]

		obj1 = ent1:GetPhysicsObjectNum(0)
		obj2 = ent2:GetPhysicsObjectNum(0)
	end

	local pos1, pos2 = obj1:GetPos(), obj2:GetPos()

	if ent1 and ent1.rgmPRoffset then
		pos1 = LocalToWorld(ent1.rgmPRoffset, angle_zero, pos1, obj1:GetAngles())
	end
	if ent2 and ent2.rgmPRoffset then
		pos2 = LocalToWorld(ent2.rgmPRoffset, angle_zero, pos2, obj2:GetAngles())
	end

	local ang = (pos2 - pos1):Angle()
	local p, offang = WorldToLocal(pos1, obj1:GetAngles(), pos1, ang)
	return ang, offang
end

function SetAngleOffset(ent, pos, ang, ang2, offang)
	local _p, _a = WorldToLocal(pos, ang2, pos, ang)
	_a.p = 0
	_a.y = 0
	_p, _a = LocalToWorld(vector_origin, _a, pos, ang)
	_p, _a = LocalToWorld(vector_origin, offang, pos, _a)
	return _a
end

--Get IK chain's knee direction.
function GetKneeDir(ent, bHip, bKnee, bAnkle)
	local obj1, obj2, obj3 = nil, nil, nil
	local ent1, ent2, ent3 = nil, nil, nil

	if not ent.rgmPRidtoent then
		obj1 = ent:GetPhysicsObjectNum(bHip)
		obj2 = ent:GetPhysicsObjectNum(bKnee)
		obj3 = ent:GetPhysicsObjectNum(bAnkle)
	else
		ent1 = ent.rgmPRidtoent[bHip]
		ent2 = ent.rgmPRidtoent[bKnee]
		ent3 = ent.rgmPRidtoent[bAnkle]

		obj1 = ent1:GetPhysicsObjectNum(0)
		obj2 = ent2:GetPhysicsObjectNum(0)
		obj3 = ent3:GetPhysicsObjectNum(0)
	end

	local pos1, pos2, pos3 = obj1:GetPos(), obj2:GetPos(), obj3:GetPos()

	if ent1 and ent1.rgmPRoffset then
		pos1 = LocalToWorld(ent1.rgmPRoffset, angle_zero, pos1, obj1:GetAngles())
	end
	if ent2 and ent2.rgmPRoffset then
		pos2 = LocalToWorld(ent2.rgmPRoffset, angle_zero, pos2, obj2:GetAngles())
	end
	if ent3 and ent3.rgmPRoffset then
		pos3 = LocalToWorld(ent3.rgmPRoffset, angle_zero, pos3, obj3:GetAngles())
	end

	-- print(( obj2:GetPos()- ( obj3:GetPos() + ( ( obj1:GetPos() - obj3:GetPos() ) / 2 ) ) ):Normalize())
	local r = (pos2 - (pos3 + ((pos1 - pos3) / 2)))
	r:Normalize()
	return r
end

--Create the default IK chains for a ragdoll.
function CreateDefaultIKs(tool, ent)
	if not ent.rgmIKChains then ent.rgmIKChains = {} end
	for k, v in pairs(DefaultIK) do
		local b = BoneToPhysBone(ent, ent:LookupBone(v.hip))
		local b2 = BoneToPhysBone(ent, ent:LookupBone(v.knee))
		local b3 = BoneToPhysBone(ent, ent:LookupBone(v.foot))
		if (b and b > -1) and (b2 and b2 > -1) and (b3 and b3 > -1) then
			table.insert(ent.rgmIKChains, {hip = b, knee = b2, foot = b3, type = v.type})
		end
	end
end

--Returns true if given bone is part of an active IK chain. Also returns it's position on the chain.
function IsIKBone(tool, ent, bone)
	if not ent.rgmIKChains then return false end
	if ent.rgmPRenttoid then
		bone = ent.rgmPRenttoid[ent]
	end

	for k, v in pairs(ent.rgmIKChains) do
		if tool:GetClientNumber(DefIKnames[v.type]) ~= 0 then
			if bone == v.hip then
				return true, 1
			elseif bone == v.knee then
				return true, 2
			elseif bone == v.foot then
				return true, 3
			end
		end
	end
	return false
end

if CLIENT then

local COLOR_RGMGREEN = Color(0, 200, 0, 255)
local COLOR_RGMBLACK = Color(0, 0, 0, 255)
local OUTLINE_WIDTH = 1

function DrawBoneName(ent, bone, name)
	if not name then
		name = ent:GetBoneName(bone)
	end

	local _pos = ent:GetBonePosition(bone)
	if not _pos then
		_pos = ent:GetPos()
	end
	_pos = _pos:ToScreen()
	local textpos = {x = _pos.x + 5, y = _pos.y - 5}
	surface.DrawCircle(_pos.x, _pos.y, 3.5, COLOR_RGMGREEN)
	draw.SimpleTextOutlined(name, "Default", textpos.x, textpos.y, COLOR_RGMGREEN, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)
end

function DrawEntName(ent)
	local name = ent:GetClass()
	local pos

	if name == "prop_ragdoll" then
		pos = ent:GetBonePosition(0)
		if not pos then pos = ent:GetPos() end
	elseif IsValid(ent:GetParent()) then
		local parent = ent:GetParent()
		pos = parent:LocalToWorld(ent:GetLocalPos())
	else
		pos = ent:GetPos()
	end

	pos = pos:ToScreen()
	local textpos = {x = pos.x + 5, y = pos.y - 5}
	surface.DrawCircle(pos.x, pos.y, 3.5, COLOR_RGMGREEN)
	draw.SimpleTextOutlined(name, "Default", textpos.x, textpos.y, COLOR_RGMGREEN, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)
end

local RGM_CIRCLE = {
	{ x = -3, y = -3 },

	{ x = 0, y = -4 },
	{ x = 3, y = -3 },
	{ x = 4, y = 0 },
	{ x = 3, y = 3 },
	{ x = 0, y = 4 },
	{ x = -3, y = 3 },
	{ x = -4, y = 0 }
}

function AdvBoneSelectRender(ent)
	local mx, my = input.GetCursorPos() -- possible bug on mac https://wiki.facepunch.com/gmod/input.GetCursorPos

	local selectedBones = {}
	for i = 0, ent:GetBoneCount() do
		local selected = false
		local name = ent:GetBoneName(i)
		if name == "__INVALIDBONE__" then continue end
		local pos = ent:GetBonePosition(i)
		pos = pos:ToScreen()

		local dist = math.abs((mx - pos.x)^2 + (my - pos.y)^2)

		local circ = table.Copy(RGM_CIRCLE)
		for k, v in ipairs(circ) do
			v.x = v.x + pos.x
			v.y = v.y + pos.y
		end

		if dist < 576 then -- 24 pixels
			surface.SetDrawColor(255, 255, 0, 255)
			table.insert(selectedBones, name)
		else
			surface.SetDrawColor(0, 200, 0, 255)
		end

		draw.NoTexture()
		surface.DrawPoly(circ)
	end

	for i = 1, #selectedBones do
		local listItemPos = {x = mx + 5, y = my + i * 15}
		draw.SimpleTextOutlined(selectedBones[i], "Default", listItemPos.x, listItemPos.y, COLOR_RGMGREEN, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)
	end
end

function AdvBoneSelectPick(ent)
	local selected = {}
	local mx, my = input.GetCursorPos()

	cam.Start3D()
	for i = 0, ent:GetBoneCount() do
		if ent:GetBoneName(i) == "__INVALIDBONE__" then continue end

		local pos = ent:GetBonePosition(i)
		pos = pos:ToScreen()
		local dist = math.abs((mx - pos.x)^2 + (my - pos.y)^2)
		if dist < 576 then
			table.insert(selected, i)
		end
	end
	cam.End3D()

	return selected
end

local COLOR_WHITE = Color(255, 255, 255, 255)
local COLOR_YELLOW = Color(255, 255, 0, 255)
local SelectedBone = nil

function AdvBoneSelectRadialRender(ent, bones)
	local mx, my = input.GetCursorPos()
	local midw, midh = ScrW()/2, ScrH()/2
	local count = #bones
	local angborder = (360 / count) / 2

	for k, bone in ipairs(bones) do
		local name = ent:GetBoneName(bone)
		local thisang = (360 / count * (k - 1))
		local thisrad = thisang / 180 * math.pi
		local uix, uiy = (math.sin(thisrad) * 250), (math.cos(thisrad) * -250)
		local color = COLOR_WHITE
		uix, uiy = uix + midw, uiy + midh

		local selangle = 360 - (math.deg(math.atan2(mx - midw, my - midh)) + 180) -- took this one from overhauled radial menu, which took some of the inspiration from wiremod

		local diff = math.abs((thisang - selangle + 180) % 360 - 180)
		local isselected = diff < angborder and true or false

		local pos = ent:GetBonePosition(bone)
		pos = pos:ToScreen()

		local circ = table.Copy(RGM_CIRCLE)
		for k, v in ipairs(circ) do
			v.x = v.x + pos.x
			v.y = v.y + pos.y
		end

		if isselected then
			surface.SetDrawColor(255, 255, 0, 255)
			color = COLOR_YELLOW
			SelectedBone = bone
		else
			surface.SetDrawColor(0, 200, 0, 255)
		end

		draw.NoTexture()
		surface.DrawPoly(circ)

		surface.DrawCircle(uix, uiy, 3.5, color)
		draw.SimpleTextOutlined(name, "Default", uix, uiy - 14, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)
	end
end

function AdvBoneSelectRadialPick()
	if not SelectedBone then return 0 end
	return SelectedBone
end

function DrawBoneConnections(ent, bone)
	local mainpos = ent:GetBonePosition(bone)
	if not mainpos then
		mainpos = ent:GetPos()
	end
	mainpos = mainpos:ToScreen()

	surface.SetDrawColor(0, 200, 0, 255)
	for _, childbone in ipairs(ent:GetChildBones(bone) or {}) do
		local pos = ent:GetBonePosition(childbone)
		pos = pos:ToScreen()

		surface.DrawLine(mainpos.x, mainpos.y, pos.x, pos.y)
	end

	if ent:GetBoneParent(bone) ~= -1 then
		surface.SetDrawColor(0, 0, 200, 255)
		local pos = ent:GetBonePosition(ent:GetBoneParent(bone))
		pos = pos:ToScreen()

		surface.DrawLine(mainpos.x, mainpos.y, pos.x, pos.y)
	end
end

local SkeletonData = {}

local function DrawRecursiveBones(ent, bone)
	local mainpos = ent:GetBonePosition(bone)
	mainpos = mainpos:ToScreen()

	for _, boneid in ipairs(ent:GetChildBones(bone)) do
		SkeletonData[boneid] = bone
		local pos = ent:GetBonePosition(boneid)
		pos = pos:ToScreen()

		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawLine(mainpos.x, mainpos.y, pos.x, pos.y)
		DrawRecursiveBones(ent, boneid)
		surface.DrawCircle(pos.x, pos.y, 2.5, COLOR_RGMGREEN)
	end
end

function DrawSkeleton(ent)
	if SkeletonData.ent ~= ent then
		SkeletonData = {}

		local num = ent:GetBoneCount() - 1
		for v = 0, num do
			if ent:GetBoneName(v) == "__INVALIDBONE__" then continue end

			if ent:GetBoneParent(v) == -1 then
				SkeletonData[v] = -1
				local pos = ent:GetBonePosition(v)
				if not pos then
					pos = ent:GetPos()
				end

				DrawRecursiveBones(ent, v)

				pos = pos:ToScreen()
				surface.DrawCircle(pos.x, pos.y, 2.5, COLOR_RGMGREEN)
			end
		end

		SkeletonData.ent = ent
	else
		for bone, parent in pairs(SkeletonData) do
			if type(bone) ~= "number" or parent == -1 then continue end
			local pos = ent:GetBonePosition(bone)
			pos = pos:ToScreen()

			local parentpos = ent:GetBonePosition(parent)
			parentpos = parentpos:ToScreen()
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawLine(parentpos.x, parentpos.y, pos.x, pos.y)
		end

		for bone, parent in pairs(SkeletonData) do
			if type(bone) ~= "number" then continue end
			local pos = ent:GetBonePosition(bone)
			pos = pos:ToScreen()

			surface.DrawCircle(pos.x, pos.y, 2.5, COLOR_RGMGREEN)
		end
	end

end

end
