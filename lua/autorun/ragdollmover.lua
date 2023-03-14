
--[[
	rgm module
	Various functions used by Ragdoll Mover tool, and the axis entities.
]]

module("rgm",package.seeall)

--[[	Line-Plane intersection, and return the result vector
	I honestly cannot explain this at all. I just followed this tutorial:
	http://www.wiremod.com/forum/expression-2-discussion-help/19008-line-plane-intersection-tutorial.html
	Lots of cookies for the guy who made it]]
function IntersectRayWithPlane(planepoint,norm,line,linenormal)
	local linepoint = line*1
	local linepoint2 = linepoint+linenormal
	local x = (norm:Dot(planepoint-linepoint)) / (norm:Dot(linepoint2-linepoint))
	local vec = linepoint + x * (linepoint2-linepoint)
	return vec
end

if SERVER then

local NumpadBindRot, NumpadBindScale = {}, {}
local RotKey, ScaleKey = {}, {}
local rgmMode = {}

if game.SinglePlayer() then


saverestore.AddSaveHook("RGMbinds", function(save)
	saverestore.WriteTable(NumpadBindRot, save)
	saverestore.WriteTable(NumpadBindScale, save)
end)

saverestore.AddRestoreHook("RGMbinds", function(save)
	NumpadBindRot = saverestore.ReadTable(save)
	NumpadBindScale = saverestore.ReadTable(save)
end)

end

util.AddNetworkString("rgmSetToggleRot")
util.AddNetworkString("rgmSetToggleScale")

net.Receive("rgmSetToggleRot",function(len, pl)
	local key = net.ReadInt(32)
	if not key then return end

	RotKey[pl] = key
	if NumpadBindRot[pl] then numpad.Remove(NumpadBindRot[pl]) end
	NumpadBindRot[pl] = numpad.OnDown(pl, key, "rgmAxisChangeStateRot")
end)

numpad.Register("rgmAxisChangeStateRot", function(pl)
	if not pl.rgm then pl.rgm = {} end
	if not rgmMode[pl] then rgmMode[pl] = 1 end

	if not pl:GetTool() then return end
	if pl:GetTool().Mode ~= "ragdollmover" or pl:GetActiveWeapon():GetClass() ~= "gmod_tool" then return end
	if RotKey[pl] == ScaleKey[pl] then
		rgmMode[pl] = rgmMode[pl] + 1
		if rgmMode[pl] > 3 then rgmMode[pl] = 1 end

		pl.rgm.Rotate = rgmMode[pl] == 2
		pl.rgm.Scale = rgmMode[pl] == 3
	else
		pl.rgm.Rotate = not pl.rgm.Rotate
		pl.rgm.Scale = false
	end

	pl:rgmSyncOne("Rotate")
	pl:rgmSyncOne("Scale")
	return true
end)


net.Receive("rgmSetToggleScale",function(len, pl)
	local key = net.ReadInt(32)
	if not key then return end

	ScaleKey[pl] = key
	if NumpadBindScale[pl] then numpad.Remove(NumpadBindScale[pl]) end
	NumpadBindScale[pl] = numpad.OnDown(pl, key, "rgmAxisChangeStateScale")
end)

numpad.Register("rgmAxisChangeStateScale", function(pl)
	if not pl.rgm then pl.rgm = {} end

	if not pl:GetTool() then return end
	if pl:GetTool().Mode ~= "ragdollmover" or pl:GetActiveWeapon():GetClass() ~= "gmod_tool" then return end
	if RotKey[pl] == ScaleKey[pl] then return end
	pl.rgm.Scale = not pl.rgm.Scale
	pl.rgm.Rotate = false

	pl:rgmSyncOne("Rotate")
	pl:rgmSyncOne("Scale")
	return true
end)

end

--Receives player eye position and eye angles.
--If cursor is visible, eye angles are based on cursor position.
function EyePosAng(pl)
	local eyepos,eyeang = pl:EyePos(),pl:EyeAngles()
	local cursorvec = pl:GetAimVector()
	--local cursorvec = pl:EyeAngles()
	return eyepos,cursorvec:Angle()
end

function AbsVector(vec)
	return Vector(math.abs(vec.x),math.abs(vec.y),math.abs(vec.z))
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

function BoneToPhysBone(ent,bone)
	for i=0,ent:GetPhysicsObjectCount()-1 do
		local b = ent:TranslatePhysBoneToBone(i)
		if bone == b then return i end
	end
	return nil
end

function GetPhysBoneParent(ent,bone)
	if not bone then return nil end
	local b = ent:TranslatePhysBoneToBone(bone)
	local cont = false
	local i = 1
	while not cont do
		b = ent:GetBoneParent(b)
		local parent = BoneToPhysBone(ent,b)
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
	"ik_hand_R"
}

--Get bone offsets from parent bones, and update IK data.
function GetOffsetTable(tool,ent,rotate, bonelocks)
	local RTable = {}
	if not ent.rgmIKChains then
		CreateDefaultIKs(tool,ent)
	end

	for a = 0, ent:GetPhysicsObjectCount() - 1 do -- getting all "root" bones - so it'll work for ragdoll with detached stuffs
		local Bone = ent:TranslatePhysBoneToBone(a)
		local Parent = ent:GetBoneParent(Bone)
		if ent:TranslateBoneToPhysBone(Parent) == -1 or not GetPhysBoneParent(ent, a) then -- root physbones seem to be "parented" to the -1. and the physboneparent function will not find the thing for it.
			RTable[a] = {}
			if bonelocks[a] then
				local obj1 = ent:GetPhysicsObjectNum(a)
				local obj2 = ent:GetPhysicsObjectNum(bonelocks[a])
				local pos1,ang1 = obj1:GetPos(),obj1:GetAngles()
				local pos2,ang2 = obj2:GetPos(),obj2:GetAngles()
				local pos3,ang3 = WorldToLocal(pos1,ang1,pos2,ang2)
				RTable[a] = {pos = pos3,ang = ang3,parent = bonelocks[a]}
			else
				RTable[a].pos = ent:GetPhysicsObjectNum(a):GetPos()
				RTable[a].ang = ent:GetPhysicsObjectNum(a):GetAngles()
				RTable[a].root = true
			end
			RTable[a].moving = ent:GetPhysicsObjectNum(a):IsMoveable()
		end
	end

	for i=0,ent:GetBoneCount()-1 do
		local pb = BoneToPhysBone(ent,i)
		local parent = bonelocks[pb] or GetPhysBoneParent(ent,pb)
		if pb and parent and not RTable[pb] then
			local b = ent:TranslatePhysBoneToBone(pb)
			local obj1 = ent:GetPhysicsObjectNum(pb)
			local obj2 = ent:GetPhysicsObjectNum(parent)
			local pos1,ang1 = obj1:GetPos(),obj1:GetAngles()
			local pos2,ang2 = obj2:GetPos(),obj2:GetAngles()
			local pos3,ang3 = WorldToLocal(pos1,ang1,pos2,ang2)
			local mov = obj1:IsMoveable()
			RTable[pb] = {pos = pos3,ang = ang3,moving = mov,parent = parent}
			local iktable = IsIKBone(tool,ent,pb)
			if iktable then
				RTable[pb].isik = true
			end
		end
	end

	for k,v in pairs(ent.rgmIKChains) do

		local obj1 = ent:GetPhysicsObjectNum(v.hip)
		local obj2 = ent:GetPhysicsObjectNum(v.knee)
		local obj3 = ent:GetPhysicsObjectNum(v.foot)

		ent.rgmIKChains[k].rotate = rotate

		local kneedir = GetKneeDir(ent,v.hip,v.knee,v.foot)

		ent.rgmIKChains[k].ikhippos = RTable[v.hip].pos*1
		if RTable[v.hip].parent then
			ent.rgmIKChains[k].ikhipparent = RTable[v.hip].parent*1
		end
		local ang,offang = GetAngleOffset(ent,v.hip,v.knee)
		ent.rgmIKChains[k].ikhipang = ang*1
		ent.rgmIKChains[k].ikhipoffang = offang*1

		ent.rgmIKChains[k].ikkneedir = kneedir
		ang,offang = GetAngleOffset(ent,v.knee,v.foot)
		ent.rgmIKChains[k].ikkneeang = ang*1
		ent.rgmIKChains[k].ikkneeoffang = offang*1

		ent.rgmIKChains[k].ikfootpos = obj3:GetPos()
		ent.rgmIKChains[k].ikfootang = obj3:GetAngles()

		ent.rgmIKChains[k].thighlength = obj1:GetPos():Distance(obj2:GetPos())
		ent.rgmIKChains[k].shinlength = obj2:GetPos():Distance(obj3:GetPos())

	end

	return RTable
end

local function RecursiveSetParent(ostable, sbone, rlocks, plocks, RTable, bone)

	local parent = ostable[bone].parent
	if not RTable[parent] then RecursiveSetParent(ostable, sbone, rlocks, plocks, RTable, parent) end

	local ppos,pang = RTable[parent].pos,RTable[parent].ang
	local pos,ang = LocalToWorld(ostable[bone].pos,ostable[bone].ang,ppos,pang)
	if bone == sbone.b then
		pos = sbone.p
		ang = sbone.a
	else
		if IsValid(rlocks[bone]) then
			ang = rlocks[bone]:GetAngles()
		end
		if IsValid(plocks[bone]) then
			pos = plocks[bone]:GetPos()
		end
	end
	RTable[bone] = {}
	RTable[bone].pos = pos*1
	RTable[bone].ang = ang*1
end

local function SetBoneOffsets(tool, ent,ostable,sbone, rlocks, plocks)
	local RTable = {}

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

	for k,v in pairs(ent.rgmIKChains) do
		if tobool(tool:GetClientNumber(DefIKnames[v.type],0)) then
			if v.ikhipparent then
				if not RTable[v.ikhipparent] then RecursiveSetParent(ostable, sbone, rlocks, plocks, RTable, v.ikhipparent) end
			end

			local footdata = ostable[v.foot]
			if footdata ~= nil and (footdata.parent ~= v.knee and footdata.parent ~= v.hip) and not RTable[footdata.parent] then 
				RecursiveSetParent(ostable, sbone, rlocks, plocks, RTable, footdata.parent)
			end

			local RT = ProcessIK(ent,v,sbone,RTable, footdata)
			table.Merge(RTable,RT)
		end
	end

	for k,v in pairs(ent.rgmIKChains) do -- calculating IKs twice for proper bone locking stuff to IKs, perhaps there is a simpler way to do these
		if tobool(tool:GetClientNumber(DefIKnames[v.type],0)) then

			local footdata = ostable[v.foot]
			if not RTable[footdata.parent] then
				RecursiveSetParent(ostable, sbone, rlocks, plocks, RTable, footdata.parent)
			end

			local RT = ProcessIK(ent,v,sbone,RTable, footdata)
			table.Merge(RTable,RT)
		end
	end

	for i=0,ent:GetBoneCount()-1 do
		local pb = BoneToPhysBone(ent,i)
		if ostable[pb] and not RTable[pb] then
			RecursiveSetParent(ostable, sbone, rlocks, plocks, RTable, pb)
		end
	end
	return RTable
end

--Set bone positions from the local positions on the offset table.
--And process IK chains (In SetBoneOffsets).
function SetOffsets(tool,ent,ostable,sbone, rlocks, plocks)
	local RTable = SetBoneOffsets(tool, ent,ostable,sbone, rlocks, plocks)

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
function FindKnee(pHip,pAnkle,fThigh,fShin,vKneeDir)
	local vB = pAnkle-pHip
    local LB = vB:Length()
    local aa = (LB*LB+fThigh*fThigh-fShin*fShin)/2/LB
    local bb = math.sqrt(math.abs(fThigh*fThigh-aa*aa))
    local vF = vB:Cross(vKneeDir:Cross(vB))
	vB:Normalize()
	vF:Normalize()
    return pHip+(aa*vB)+(bb*vF)
end

--Process one IK chain, and set it's positions.
function ProcessIK(ent,IKTable,sbone,RT,footlock)

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

	local hpos,hang

	if IKTable.ikhipparent then
		obj = RT[IKTable.ikhipparent]
		hpos,hang = LocalToWorld(hippos,Angle(0,0,0),obj.pos,obj.ang)
	else
		hpos,hang = LocalToWorld(hippos,Angle(0,0,0),Vector(0,0,0), Angle(0,0,0))
	end
	local HipPos = hpos*1

	local AnklePos,AnkleAng
	if IKTable.foot == sbone.b then
		AnklePos,AnkleAng = sbone.p,sbone.a
	elseif footlock ~= nil and IKTable.knee ~= footlock.parent and IKTable.hip ~= footlock.parent then
		AnklePos,AnkleAng = LocalToWorld(footlock.pos, footlock.ang, RT[footlock.parent].pos, RT[footlock.parent].ang)
	else
		AnklePos,AnkleAng = footpos*1,footang*1
	end
	local ankledist = AnklePos:Distance(HipPos)
	if ankledist > (thighlength + shinlength) then
		local anklenorm = (AnklePos - HipPos)
		anklenorm:Normalize()
		AnklePos = HipPos + (anklenorm * (thighlength + shinlength))
	end

	local KneePos = FindKnee(HipPos,AnklePos,thighlength,shinlength,kneedir)
	hang = SetAngleOffset(ent,HipPos,(KneePos-HipPos):Angle(),hipang,hipoffang)
	local HipAng = hang*1
	hang = SetAngleOffset(ent,KneePos,(AnklePos-KneePos):Angle(),kneeang,kneeoffang)
	local KneeAng = hang*1

	RTable[IKTable.hip] = {pos = HipPos,ang = HipAng}
	RTable[IKTable.knee] = {pos = KneePos,ang = KneeAng}
	if IKTable.rotate and sbone.b == IKTable.hip then
		RTable[IKTable.hip].dontset = true
	elseif IKTable.rotate and sbone.b == IKTable.knee then
		RTable[IKTable.knee].dontset = true
	end
	RTable[IKTable.foot] = {pos = AnklePos,ang = AnkleAng}

	return RTable

end

function NormalizeAngle(ang)
	local RAng = Angle()
	RAng.p = math.NormalizeAngle(ang.p)
	RAng.y = math.NormalizeAngle(ang.y)
	RAng.r = math.NormalizeAngle(ang.r)
	return RAng
end

function GetAngleOffset(ent,b1,b2)
	local obj1 = ent:GetPhysicsObjectNum(b1)
	local obj2 = ent:GetPhysicsObjectNum(b2)
	local ang = (obj2:GetPos()-obj1:GetPos()):Angle()
	local p,offang = WorldToLocal(obj1:GetPos(),obj1:GetAngles(),obj1:GetPos(),ang)
	return ang,offang
end

function SetAngleOffset(ent,pos,ang,ang2,offang)
	local _p,_a = WorldToLocal(pos,ang2,pos,ang)
	_a.p = 0
	_a.y = 0
	_p,_a = LocalToWorld(Vector(0,0,0),_a,pos,ang)
	_p,_a = LocalToWorld(Vector(0,0,0),offang,pos,_a)
	return _a
end

--Get IK chain's knee direction.
function GetKneeDir(ent,bHip,bKnee,bAnkle)
	local obj1 = ent:GetPhysicsObjectNum(bHip)
	local obj2 = ent:GetPhysicsObjectNum(bKnee)
	local obj3 = ent:GetPhysicsObjectNum(bAnkle)
	-- print(( obj2:GetPos()- ( obj3:GetPos() + ( ( obj1:GetPos() - obj3:GetPos() ) / 2 ) ) ):Normalize())
	local r = ( obj2:GetPos()- ( obj3:GetPos() + ( ( obj1:GetPos() - obj3:GetPos() ) / 2 ) ) )
	r:Normalize()
	return r
end

--Create the default IK chains for a ragdoll.
function CreateDefaultIKs(tool,ent)
	if not ent.rgmIKChains then ent.rgmIKChains = {} end
	for k,v in pairs(DefaultIK) do
		local b = BoneToPhysBone(ent,ent:LookupBone(v.hip))
		local b2 = BoneToPhysBone(ent,ent:LookupBone(v.knee))
		local b3 = BoneToPhysBone(ent,ent:LookupBone(v.foot))
		if (b and b > -1) and (b2 and b2 > -1) and (b3 and b3 > -1) then
			table.insert(ent.rgmIKChains,{hip = b,knee = b2,foot = b3,type = v.type})
		end
	end
end

--Returns true if given bone is part of an active IK chain. Also returns it's position on the chain.
function IsIKBone(tool,ent,bone)
	if not ent.rgmIKChains then return false end
	for k,v in pairs(ent.rgmIKChains) do
		if tobool(tool:GetClientNumber(DefIKnames[v.type],0)) then
			if bone == v.hip then
				return true,1
			elseif bone == v.knee then
				return true,2
			elseif bone == v.foot then
				return true,3
			end
		end
	end
	return false
end

function DrawBoneName(ent,bone)
	local name = ent:GetBoneName(bone)
	local _pos = ent:GetBonePosition(bone)
	if not _pos then
		_pos = ent:GetPos()
	end
	_pos = _pos:ToScreen()
	local textpos = {x = _pos.x+5,y = _pos.y-5}
	surface.DrawCircle(_pos.x,_pos.y,3.5,Color(0,200,0,255))
	draw.SimpleText(name,"Default",textpos.x,textpos.y,Color(0,200,0,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
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
	local textpos = { x = pos.x+5, y = pos.y-5 }
	surface.DrawCircle(pos.x, pos.y, 3.5, Color(0, 200, 0, 255))
	draw.SimpleText(name,"Default",textpos.x,textpos.y,Color(0,200,0,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
end

function DrawBoneConnections(ent, bone)
	local mainpos = ent:GetBonePosition(bone)
	if not mainpos then
		mainpos = ent:GetPos()
	end
	mainpos = mainpos:ToScreen()

	surface.SetDrawColor( 0, 200, 0, 255 )
	for _, childbone in ipairs(ent:GetChildBones(bone) or {}) do
		local pos = ent:GetBonePosition(childbone)
		pos = pos:ToScreen()

		surface.DrawLine(mainpos.x, mainpos.y, pos.x, pos.y)
	end

	if ent:GetBoneParent(bone) ~= -1 then
		surface.SetDrawColor( 0, 0, 200, 255 )
		local pos = ent:GetBonePosition(ent:GetBoneParent(bone))
		pos = pos:ToScreen()

		surface.DrawLine(mainpos.x, mainpos.y, pos.x, pos.y)
	end
end

local function DrawRecursiveBones(ent, bone)
	local mainpos = ent:GetBonePosition(bone)
	mainpos = mainpos:ToScreen()

	for _, boneid in ipairs(ent:GetChildBones(bone)) do
		local pos = ent:GetBonePosition(boneid)
		pos = pos:ToScreen()

		surface.SetDrawColor( 255, 255, 255, 255 )
		surface.DrawLine(mainpos.x, mainpos.y, pos.x, pos.y)
		DrawRecursiveBones(ent, boneid)
		surface.DrawCircle(pos.x, pos.y, 2.5, Color(0, 200, 0, 255))
	end
end

function DrawSkeleton(ent)
	local num = ent:GetBoneCount() - 1
	for v = 0, num do
		if ent:GetBoneName(v) == "__INVALIDBONE__" then continue end

		if ent:GetBoneParent(v) == -1 then
			local pos = ent:GetBonePosition(v)
			if not pos then
				pos = ent:GetPos()
			end

			DrawRecursiveBones(ent, v)

			pos = pos:ToScreen()
			surface.DrawCircle(pos.x, pos.y, 2.5, Color(0, 200, 0, 255))
		end
	end

end
