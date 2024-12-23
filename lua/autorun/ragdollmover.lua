-- load dconstants
include("ragdollmover/constants.lua")
AddCSLuaFile("ragdollmover/constants.lua")

-- load gizmos library
include("ragdollmover/rgm_gizmos.lua")
AddCSLuaFile("ragdollmover/rgm_gizmos.lua")

-- create font for drawing functions that scales with screen size
local RGMFontSize

if CLIENT then

RGMFontSize = math.Round(12 * ScrH()/1080)

if RGMFontSize < 10 then RGMFontSize = 10 end

surface.CreateFont("RagdollMoverChangelogTitleFont", {
	font = "Roboto",
	size = 3 * RGMFontSize,
	weight = 300,
	antialias = true,
})

surface.CreateFont("RagdollMoverChangelogFont", {
	font = "Roboto",
	size = 1.5 * RGMFontSize,
	weight = 300,
	antialias = true,
})

surface.CreateFont("RagdollMoverFont", {
	font = "Verdana",
	size = RGMFontSize,
	weight = 700,
	antialias = true
})

surface.CreateFont("RagdollMoverAngleFont", {
	font = "Verdana",
	size = RGMFontSize * 1.5,
	weight = 700,
	antialias = true
})

end

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

local VECTOR_ONE = RGM_Constants.VECTOR_ONE

--Receives player eye position and eye angles.
--If cursor is visible, eye angles are based on cursor position.
function EyePosAng(pl, viewent)
	local eyepos = pl:EyePos()
	if not viewent then viewent = pl:GetViewEntity() end

	if IsValid(viewent) and viewent ~= pl then
		eyepos = viewent:GetPos()
		if viewent:GetClass() == "hl_camera" then -- adding support for Advanced Camera's view offset https://steamcommunity.com/sharedfiles/filedetails/?id=881605937&searchtext=advanced+camera
			eyepos = viewent:LocalToWorld(viewent:GetViewOffset())
		end
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

function SetScaleOffsets(ent, ostable, sbone, scale, plocks, slocks, scalechildren, nphysinfo, childrenbones)
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

local COLOR_RGMGREEN = RGM_Constants.COLOR_GREEN
local COLOR_RGMBLACK = RGM_Constants.COLOR_BLACK
local COLOR_WHITE = RGM_Constants.COLOR_WHITE
local COLOR_BLUE = RGM_Constants.COLOR_BLUE
local COLOR_BRIGHT_YELLOW = RGM_Constants.COLOR_BRIGHT_YELLOW
local OUTLINE_WIDTH = RGM_Constants.OUTLINE_WIDTH

local function gradient(startPoint, endPoint, points)
	local colors = {}
	for i = 0, points-1 do
		colors[i+1] = startPoint:Lerp(endPoint, i / points)
	end
	return colors
end

local NUM_GRADIENT_POINTS = 2

local BONETYPE_COLORS = { 
	gradient(RGM_Constants.COLOR_GREEN, RGM_Constants.COLOR_DARKGREEN, NUM_GRADIENT_POINTS), 
	gradient(RGM_Constants.COLOR_CYAN, RGM_Constants.COLOR_DARKCYAN, NUM_GRADIENT_POINTS), 
	gradient(RGM_Constants.COLOR_YELLOW, RGM_Constants.COLOR_DARKYELLOW, NUM_GRADIENT_POINTS), 
	gradient(RGM_Constants.COLOR_RED, RGM_Constants.COLOR_DARKRED, NUM_GRADIENT_POINTS) 
}

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
	draw.SimpleTextOutlined(name, "RagdollMoverFont", textpos.x, textpos.y, COLOR_RGMGREEN, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)
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
	draw.SimpleTextOutlined(name, "RagdollMoverFont", textpos.x, textpos.y, COLOR_RGMGREEN, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)
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

local LockGo = Material("icon16/lock_go.png", "alphatest")
local Lock = Material("icon16/lock.png", "alphatest")

local midw, midh = ScrW()/2, ScrH()/2
local divide540 = RGM_Constants.FLOAT_1DIVIDE540 -- aggressive microoptimizations

hook.Add("OnScreenSizeChanged", "RagdollMoverHUDUpdate", function(_, _, newWidth, newHeight)
	midw, midh = newWidth/2, newHeight/2
end)

local VERSION_PATH = "rgm/version.txt"
local RGM_VERSION = "3.0.0"

-- TODO: Do further testing in multiplayer for cases where the server has a different version of RGM compared to the client
local function versionMatches(currentVersion, versionPath)
	if not file.Exists("rgm", "DATA") then
		file.CreateDir("rgm")
	end

	local readVersion = file.Read(versionPath)
	local matches = readVersion and readVersion == currentVersion
	if matches then
		return true
	else
		file.Write(versionPath, currentVersion)
		return false
	end
end

-- Show the changelog if the stored version on this computer is different from RGM_VERSION
local function showChangelog()
	-- Notify the player of a new version
	local changelog = vgui.Create("rgm_changelog")
	local windowSizeRatio = midh * divide540
	local padding = 20 * windowSizeRatio
	local x, y = 500 * windowSizeRatio, 500 * windowSizeRatio
	changelog:SetSize(x, y)
	changelog:SetPos(midw - x * 0.5, midh - y * 0.5)
	changelog:DockPadding(2 * padding, 6 * padding, 2 * padding, 2 * padding)
end

-- When localplayer is valid, check if we should notify the user
hook.Add("InitPostEntity", "RagdollMoverNotifyOnStart", function()
	if not versionMatches(RGM_VERSION, VERSION_PATH) then
		local notice1 = language.GetPhrase("ui.ragdollmover.notice1")
		local notice2 = language.GetPhrase("ui.ragdollmover.notice2")
		chat.AddText(notice1)
		chat.AddText(notice2)
		print("\n" .. notice1 .."\n")
		print(notice2 .."\n")
	end
end)

-- Allow the user to see the changelog from GMod workshop
concommand.Add("ragdollmover_changelog", function()
	showChangelog()
end)

function AdvBoneSelectRender(ent, bonenodes)
	local mx, my = input.GetCursorPos() -- possible bug on mac https://wiki.facepunch.com/gmod/input.GetCursorPos
	local nodesExist = bonenodes and bonenodes[ent] and true
	local bonedistances = {}
	local plpos = LocalPlayer():EyePos()
	local mindist, maxdist = nil, nil

	for i = 0, ent:GetBoneCount() - 1 do
		local dist = plpos:DistToSqr( ent:GetBonePosition(i) )
		if not mindist or mindist > dist then mindist = dist end
		if not maxdist or maxdist < dist then maxdist = dist end
		bonedistances[i] = dist
	end

	local selectedBones = {}
	for i = 0, ent:GetBoneCount() - 1 do
		local name = ent:GetBoneName(i)
		if name == "__INVALIDBONE__" then continue end
		if nodesExist and (not bonenodes[ent][i]) or false then continue end
		local pos = ent:GetBonePosition(i)
		pos = pos:ToScreen()
		local x, y = pos.x, pos.y

		local dist = math.abs((mx - x)^2 + (my - y)^2)

		local circ = table.Copy(RGM_CIRCLE)
		for k, v in ipairs(circ) do
			v.x = v.x + x
			v.y = v.y + y
		end

		if dist < 576 then -- 24 pixels
			surface.SetDrawColor(COLOR_BRIGHT_YELLOW:Unpack())
			table.insert(selectedBones, {name, i})
		else
			if nodesExist and bonenodes[ent][i] and bonenodes[ent][i].Type then
				local fraction = ( bonedistances[i] - mindist ) / (maxdist - mindist)
				fraction = math.max(1, math.ceil(fraction * NUM_GRADIENT_POINTS))
				surface.SetDrawColor(BONETYPE_COLORS[bonenodes[ent][i].Type][fraction]:Unpack())
			else
				surface.SetDrawColor(COLOR_RGMGREEN:Unpack())
			end
		end

		draw.NoTexture()
		surface.DrawPoly(circ)

		if bonenodes[ent][i].bonelock then
			surface.SetMaterial(LockGo)
			surface.SetDrawColor(COLOR_WHITE:Unpack())
			surface.DrawTexturedRect(x - 12, y - 12, 24, 24)
		elseif bonenodes[ent][i].poslock or bonenodes[ent][i].anglock then
			surface.SetMaterial(Lock)
			surface.SetDrawColor(COLOR_WHITE:Unpack())
			surface.DrawTexturedRect(x - 12, y - 12, 24, 24)
		end
	end

	-- We use the average length of all bone names to ensure some names don't overlap each other
	local meanNameLength = 0
	-- Assume default font is about this wide
	local fontWidth = 7.5 * divide540 * midh
	if fontWidth < 6.5 then fontWidth = 6.5 end
	for i = 1, #selectedBones do
		meanNameLength = meanNameLength + #selectedBones[i][1] * fontWidth
	end
	meanNameLength = meanNameLength / #selectedBones

	local maxItemsPerColumn = 257 * (RGMFontSize + 3)
	local scrH = ScrH() - 100 -- Some padding to keep the bones centered
	local columns = 0

	-- List the selected bones. If they attempt to overflow through the screen, add the items to another column.
	for i = 0, #selectedBones - 1 do
		local yPos = my + (i % maxItemsPerColumn) * (RGMFontSize + 3)
		local xPos = mx + 5 + meanNameLength * columns
		if yPos > scrH then
			maxItemsPerColumn = i + 1
		end
		if i > 0 and i % maxItemsPerColumn == 0 then
			columns = columns + 1
			xPos = mx + 5 + meanNameLength * columns
		end

		local color
		if nodesExist then
			color = BONETYPE_COLORS[bonenodes[ent][selectedBones[i + 1][2]].Type][1]
		else
			color = COLOR_RGMGREEN
		end

		draw.SimpleTextOutlined(selectedBones[i + 1][1], "RagdollMoverFont", xPos, yPos, color, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)
	end
end

function AdvBoneSelectPick(ent, bonenodes)
	local selected = {}
	local mx, my = input.GetCursorPos()
	local nodesExist = bonenodes and bonenodes[ent] and true

	cam.Start3D()
	for i = 0, ent:GetBoneCount() - 1 do
		if ent:GetBoneName(i) == "__INVALIDBONE__" then continue end
		if nodesExist and (not bonenodes[ent][i]) or false then continue end

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

local SelectedBone = nil

local Colors = {
	Color(255, 140, 105), -- Orange, for Resets
	Color(100, 255, 255), -- Cyan (Blue is too dark), for Zeroing scale
	Color(100, 255, 0), -- Green, for Locks
	Color(255, 255, 255) -- White, for whatever
}

local FeaturesNPhys = {
	{ 1, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.reset")), 1 }, -- 1
	{ 5, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetchildren")), 1 }, -- 5
	{ 2, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetpos")), 1 }, -- 2
	{ 6, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetposchildren")), 1 }, -- 6
	{ 3, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetrot")), 1 }, -- 3
	{ 7, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetrotchildren")), 1 }, -- 7
	{ 4, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetscale")), 1 }, -- 4
	{ 8, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetscalechildren")), 1 }, -- 8
	{ 9, (language.GetPhrase("tool.ragdollmover.scalezero") .. " " .. language.GetPhrase("tool.ragdollmover.bone")), 2 }, -- 9
	{ 10, (language.GetPhrase("tool.ragdollmover.scalezero") .. " " .. language.GetPhrase("tool.ragdollmover.bonechildren")), 2 }, -- 10
	{ 15, { "#tool.ragdollmover.unlockscale", "#tool.ragdollmover.lockscale" }, 3 }, --15
	{ 17, "#tool.ragdollmover.putgizmopos", 4 }, -- 17
	{ 18, "#tool.ragdollmover.resetoffset", 4 } -- 18
}

local FeaturesPhys = {
	{ 1, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.reset")), 1 }, -- 1
	{ 5, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetchildren")), 1 }, -- 5
	{ 6, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetposchildren")), 1 }, -- 6
	{ 7, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetrotchildren")), 1 }, -- 7
	{ 8, (language.GetPhrase("tool.ragdollmover.resetmenu") .. " " .. language.GetPhrase("tool.ragdollmover.resetscalechildren")), 1 }, -- 8
	{ 9, (language.GetPhrase("tool.ragdollmover.scalezero") .. " " .. language.GetPhrase("tool.ragdollmover.bone")), 2 }, -- 9
	{ 10, (language.GetPhrase("tool.ragdollmover.scalezero") .. " " .. language.GetPhrase("tool.ragdollmover.bonechildren")), 2 }, -- 10
	{ 19, { "#tool.ragdollmover.unlockall", "#tool.ragdollmover.lockall" }, 3 }, -- 19
	{ 12, { "#tool.ragdollmover.unlockpos", "#tool.ragdollmover.lockpos" }, 3 }, -- 12
	{ 13, { "#tool.ragdollmover.unlockang", "#tool.ragdollmover.lockang" }, 3}, -- 13
	{ 15, { "#tool.ragdollmover.unlockscale", "#tool.ragdollmover.lockscale" }, 3 }, --15
	{ 14, "#tool.ragdollmover.lockbone", 3 }, -- 14
	{ 11, "#tool.ragdollmover.unlockbone", 3 }, -- 11
	{ 16, "#tool.ragdollmover.freezebone", 4 }, -- 16
	{ 17, "#tool.ragdollmover.putgizmopos", 4 }, -- 17
	{ 18, "#tool.ragdollmover.resetoffset", 4 } -- 18
}

function AdvBoneSelectRadialRender(ent, bones, bonenodes, isresetmode)
	local mx, my = input.GetCursorPos()
	local modifier = divide540 * midh

	if not isresetmode then
		local count = #bones
		local angborder = (360 / count) / 2

		for k, bone in ipairs(bones) do
			local name = ent:GetBoneName(bone)
			local thisang = (360 / count * (k - 1))
			local thisrad = thisang / 180 * math.pi
			local uix, uiy = (math.sin(thisrad) * 250 * modifier), (math.cos(thisrad) * -250 * modifier)
			local color = COLOR_WHITE
			if bonenodes and bonenodes[ent] and bonenodes[ent][bone] and bonenodes[ent][bone].Type then
				color = BONETYPE_COLORS[bonenodes[ent][bone].Type][1]
			end
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
				surface.SetDrawColor(COLOR_BRIGHT_YELLOW:Unpack())
				color = COLOR_BRIGHT_YELLOW
				SelectedBone = bone
			else
				if bonenodes and bonenodes[ent] and bonenodes[ent][bone] and bonenodes[ent][bone].Type then
					surface.SetDrawColor(BONETYPE_COLORS[bonenodes[ent][bone].Type][1]:Unpack())
				else
					surface.SetDrawColor(COLOR_RGMGREEN:Unpack())
				end
			end

			draw.NoTexture()
			surface.DrawPoly(circ)

			local ytextoffset = -14
			if uiy > (midh + 30) then ytextoffset = RGMFontSize + 14 end

			local xtextoffset = 0
			if uix > (midw + 5) then
				xtextoffset = 20
			elseif uix < (midw - 5) then
				xtextoffset = -20
			else
				ytextoffset = ytextoffset*1.5
			end

			surface.DrawCircle(uix, uiy, 3.5, color)
			draw.SimpleTextOutlined(name, "RagdollMoverFont", uix + xtextoffset, uiy + ytextoffset, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)
		end

	else
		local bone = bones[1]
		local btype = 2
		if bonenodes and bonenodes[ent] and bonenodes[ent][bone] and bonenodes[ent][bone].Type then
			btype = bonenodes[ent][bone].Type
		end

		local pos = ent:GetBonePosition(bone)
		pos = pos:ToScreen()

		local circ = table.Copy(RGM_CIRCLE)
		for k, v in ipairs(circ) do
			v.x = v.x + pos.x
			v.y = v.y + pos.y
		end

		surface.SetDrawColor(COLOR_WHITE:Unpack())

		draw.NoTexture()
		surface.DrawPoly(circ)

		local boneoptions = btype == 1 and FeaturesPhys or FeaturesNPhys
		local count = #boneoptions
		if btype == 1 then
			if not bonenodes[ent][bone].bonelock then
				count = count - 1
			else
				count = count - 2
			end
		end

		local angborder = (360 / count) / 2
		local k = 1
		local skipped = 0

		for i, option in pairs(boneoptions) do
			local id  = option[1]
			if ( id == 11 and not bonenodes[ent][bone].bonelock ) or ( (id == 12 or id == 13) and bonenodes[ent][bone].bonelock ) then continue end

			local name = option[2]
			if not isstring(option) then
				if id == 12 then
					name = bonenodes[ent][bone].poslock and name[1] or name[2]
				elseif id == 13 then
					name = bonenodes[ent][bone].anglock and name[1] or name[2]
				elseif id == 15 then
					name = bonenodes[ent][bone].scllock and name[1] or name[2]
				elseif id == 19 then
					name = ( bonenodes[ent][bone].poslock and bonenodes[ent][bone].anglock ) and name[1] or name[2]
				end
			end

			local thisang = (360 / count * (k - 1))
			local thisrad = thisang / 180 * math.pi
			local uix, uiy = (math.sin(thisrad) * 250 * modifier), (math.cos(thisrad) * -250 * modifier)
			local color = Colors[option[3]]

			uix, uiy = uix + midw, uiy + midh

			local selangle = 360 - (math.deg(math.atan2(mx - midw, my - midh)) + 180) -- took this one from overhauled radial menu, which took some of the inspiration from wiremod

			local diff = math.abs((thisang - selangle + 180) % 360 - 180)
			local isselected = diff < angborder and true or false

			if isselected then
				color = COLOR_BRIGHT_YELLOW
				SelectedBone = id
			end

			local ytextoffset = -14
			if uiy > (midh + 30) then ytextoffset = RGMFontSize + 14 end

			local xtextoffset = 0
			if uix > (midw + 5) then
				xtextoffset = 20
			elseif uix < (midw - 5) then
				xtextoffset = -20
			else
				ytextoffset = ytextoffset*1.5
			end

			surface.DrawCircle(uix, uiy, 3.5, color)
			draw.SimpleTextOutlined(name, "RagdollMoverFont", uix + xtextoffset, uiy + ytextoffset, color, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM, OUTLINE_WIDTH, COLOR_RGMBLACK)

			k = k + 1
		end

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

	surface.SetDrawColor(COLOR_RGMGREEN:Unpack())
	for _, childbone in ipairs(ent:GetChildBones(bone) or {}) do
		local pos = ent:GetBonePosition(childbone)
		pos = pos:ToScreen()

		surface.DrawLine(mainpos.x, mainpos.y, pos.x, pos.y)
	end

	if ent:GetBoneParent(bone) ~= -1 then
		surface.SetDrawColor(COLOR_BLUE:Unpack())
		local pos = ent:GetBonePosition(ent:GetBoneParent(bone))
		pos = pos:ToScreen()

		surface.DrawLine(mainpos.x, mainpos.y, pos.x, pos.y)
	end
end

local SkeletonData = {}

local function DrawRecursiveBones(ent, bone, bonenodes)
	local mainpos = ent:GetBonePosition(bone)
	mainpos = mainpos:ToScreen()
	local nodecache = bonenodes[ent]
	local nodeexist = nodecache and true or false

	for _, boneid in ipairs(ent:GetChildBones(bone)) do
		SkeletonData[boneid] = bone
		local pos = ent:GetBonePosition(boneid)
		pos = pos:ToScreen()

		surface.SetDrawColor(COLOR_WHITE:Unpack())
		surface.DrawLine(mainpos.x, mainpos.y, pos.x, pos.y)
		DrawRecursiveBones(ent, boneid, bonenodes)
		local color
		if nodeexist and nodecache[boneid] then
			color = BONETYPE_COLORS[nodecache[boneid].Type][1]
		else
			color = COLOR_RGMGREEN
		end
		surface.DrawCircle(pos.x, pos.y, 2.5, color)
	end
end

function DrawSkeleton(ent, bonenodes)
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

				DrawRecursiveBones(ent, v, bonenodes)

				pos = pos:ToScreen()
				local color
				if bonenodes then
					color = BONETYPE_COLORS[bonenodes[ent][v].Type][1]
				else
					color = COLOR_RGMGREEN
				end
				surface.DrawCircle(pos.x, pos.y, 2.5, color)
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
			surface.SetDrawColor(COLOR_WHITE:Unpack())
			surface.DrawLine(parentpos.x, parentpos.y, pos.x, pos.y)
		end

		for bone, parent in pairs(SkeletonData) do
			if type(bone) ~= "number" then continue end
			local pos = ent:GetBonePosition(bone)
			pos = pos:ToScreen()

			local color
			if bonenodes and bonenodes[ent] and bonenodes[ent][bone] and bonenodes[ent][bone].Type then
				color = BONETYPE_COLORS[bonenodes[ent][bone].Type][1]
			else
				color = COLOR_RGMGREEN
			end

			surface.DrawCircle(pos.x, pos.y, 2.5, color)
		end
	end

end

hook.Add("PopulateToolMenu", "RagdollMoverUtilities", function(form)
	spawnmenu.AddToolMenuOption("Utilities", "Ragdoll Mover", "RGM_PatchNotes", "#ui.ragdollmover.notes", "", "", function(form)
		---@cast form DForm

		form:SetLabel("#ui.ragdollmover.notes")
		form:Button("#ui.ragdollmover.notes.view", "ragdollmover_changelog")
	end)
end)

end
