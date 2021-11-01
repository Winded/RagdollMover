
/*
	rgm module
	Various functions used by Ragdoll Mover tool, and the axis entities.
*/

module("rgm",package.seeall);

/*	Line-Plane intersection, and return the result vector
	I honestly cannot explain this at all. I just followed this tutorial:
	http://www.wiremod.com/forum/expression-2-discussion-help/19008-line-plane-intersection-tutorial.html
	Lots of cookies for the guy who made it.*/
function IntersectRayWithPlane(planepoint,norm,line,linenormal)
	local linepoint = line*1
	local linepoint2 = linepoint+linenormal
	local x = (norm:Dot(planepoint-linepoint)) / (norm:Dot(linepoint2-linepoint))
	local vec = linepoint + x * (linepoint2-linepoint)
	return vec
end

//We need to receive from clientside if the middle mouse button is pressed.
//To get that, we need constant spam of console command sending.
//This is one of the reasons that the tool might not be healthy for multiplayer.

if CLIENT then

local lastkey = -1;

hook.Add("Think", "rgmToggleThink", function()
	local curkey = GetConVar("ragdollmover_rotatebutton"):GetInt();
	
	if curkey != lastkey then
		net.Start("rgmSetToggleKey");
		net.WriteEntity(LocalPlayer());
		net.WriteInt(curkey, 32);
		net.SendToServer();
	end
	
	lastkey = curkey;
end)

else

CurrentToggleKey = MOUSE_MIDDLE;

util.AddNetworkString("rgmSetToggleKey");

net.Receive("rgmSetToggleKey",function(len)
	local pl = net.ReadEntity();
	local key = net.ReadInt(32);
	if !key then return; end
	
	CurrentToggleKey = key;
	numpad.OnDown(pl, key, "rgmAxisChangeState", key);
end)

numpad.Register("rgmAxisChangeState", function(pl, key)
	if key != CurrentToggleKey then return false; end
	
	if !pl.rgm then pl.rgm = {}; end
	if pl.rgm.Rotate == nil then
		pl.rgm.Rotate = true;
	else
		pl.rgm.Rotate = !pl.rgm.Rotate;
	end
	pl:rgmSyncOne("Rotate");
	return true;
end)



end

//Receives player eye position and eye angles.
//If cursor is visible, eye angles are based on cursor position.
function EyePosAng(pl)
	local eyepos,eyeang = pl:EyePos(),pl:EyeAngles()
	local cursorvec = pl:GetAimVector()
	//local cursorvec = pl:EyeAngles();
	return eyepos,cursorvec:Angle()
end

function AbsVector(vec)
	return Vector(math.abs(vec.x),math.abs(vec.y),math.abs(vec.z))
end

//Default IK chain tables

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

//For simplicity, we'll just call the arm IK parts hip, knee and foot aswell.
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

//---
//Bone Movement library (functions to make ragdoll bones move relatively to their parent bones, or with IK chains)
//---

function BoneToPhysBone(ent,bone)
	for i=0,ent:GetPhysicsObjectCount()-1 do
		local b = ent:TranslatePhysBoneToBone(i)
		if bone == b then return i end
	end
	return nil;
end

function GetPhysBoneParent(ent,bone)
	if not bone then return nil; end
	local b = ent:TranslatePhysBoneToBone(bone)
	local pb
	local cont = false
	local i = 1
	while !cont do
		b = ent:GetBoneParent(b)
		local parent = BoneToPhysBone(ent,b)
		if parent and parent != bone then
			return parent
		end
		i = i + 1
		if i > 128 then //We've gone through all possible bones, so we get out.
			cont = true
		end
	end
	return nil;
end

local DefIKnames = {
	"ik_leg_L",
	"ik_leg_R",
	"ik_hand_L",
	"ik_hand_R"
}

//Get bone offsets from parent bones, and update IK data.
function GetOffsetTable(tool,ent,rotate)
	local RTable = {}
	if !ent.rgmIKChains then
		CreateDefaultIKs(tool,ent)
	end
	
	local bonestart
--------------------------------------------------------- gotta sort out the bones in case if there are genius sfm to gmod ports with roottransform as 0 bone, like wtf
	for a = 0, ent:GetBoneCount() - 1 do
		local phys;
		local IsPhysBone = false;
				
		for i = 0, ent:GetPhysicsObjectCount() - 1 do
			local b = ent:TranslatePhysBoneToBone(i)
			if a == b then 
				phys = i
			end
		end
			
		local count = ent:GetPhysicsObjectCount()
			
		if count == 0 then
			phys = -1
		elseif count == 1 then
			phys = 0
			IsPhysBone = true;
		end

		if phys and 0 <= phys and count > phys then
			if ent:GetPhysicsObjectNum(phys) then
				IsPhysBone = true
			end
		end
--------------------------------------------------------- wait until we get first physics bone, that'll be our parent bone, and not some non physical stuff like roottransform that causes stuff to freak out
		if IsPhysBone then
			bonestart = a
			a = ent:TranslateBoneToPhysBone(a)
			RTable[a] = {}
			RTable[a].pos = ent:GetPhysicsObjectNum(a):GetPos()
			RTable[a].ang = ent:GetPhysicsObjectNum(a):GetAngles()
			RTable[a].moving = ent:GetPhysicsObjectNum(a):IsMoveable()
			RTable["FirstBone"] = a
			RTable["FirstNPHys"] = bonestart
			break
		end
	end

	do
		local tableforreference = {}
---------------------------------------------- now we're sorting for case of ragdolls that "break" into several parts - they have several physbones parented to nonphysical root. we just give up on IK then.
		for a = 0, ent:GetBoneCount() - 1 do
			tableforreference[a] = {}
			tableforreference[a].phys = false
			local phys;
			local IsPhysBone = false;
					
			for i = 0, ent:GetPhysicsObjectCount() - 1 do
				local b = ent:TranslatePhysBoneToBone(i)
				if a == b then 
					phys = i
				end
			end
				
			local count = ent:GetPhysicsObjectCount()
				
			if count == 0 then
				phys = -1
			elseif count == 1 then
				phys = 0
				IsPhysBone = true;
			end

			if phys and 0 <= phys and count > phys then
				if ent:GetPhysicsObjectNum(phys) then
					IsPhysBone = true
				end
			end
			
			if IsPhysBone then
				tableforreference[a].phys = true
			end
			local parentbone = ent:GetBoneParent(a)
			tableforreference[a].parent = parentbone	
		end
---------------------------------------------- 
		local physroots = 0
		local nonphysroots = 0
		for i, value in pairs(tableforreference) do
			if value.parent == -1 then
				if value.phys then
					physroots = physroots + 1
					if physroots > 1 then
						RTable["fuckedup"] = true -- can ragdolls have more than 1 root physbone anyway?
						break
					end
				else
					local children = 0
					for _, bonestuff in pairs(tableforreference) do
						if i == bonestuff.parent then
							children = children + 1
							if children > 1 then
								RTable["fuckedup"] = true -- uh oh it's that breakable ragdoll thing, abort.
								break
							end
						end
					end
					if children ~= 0 then
						nonphysroots = nonphysroots + 1 -- no idea if this is possible
						if nonphysroots > 1 then
							RTable["fuckedup"] = true
						end
					end
					if RTable["fuckedup"] then break end
				end
			end
		end
	end
	
	for i=1+bonestart,ent:GetBoneCount()-1 do
		local pb = BoneToPhysBone(ent,i)
		local parent = GetPhysBoneParent(ent,pb)
		if pb and pb != RTable["FirstBone"] and parent and !RTable[pb] then
			local b = ent:TranslatePhysBoneToBone(pb)
			local bn = ent:GetBoneName(b)
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
		ent.rgmIKChains[k].ikhipparent = RTable[v.hip].parent*1
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

local function SetBoneOffsets(ent,ostable,sbone)
	local RTable = {}
	local firstbone = ostable["FirstBone"]
	local firstnphys = ostable["FirstNPHys"]

	if ostable["fuckedup"] then return nil end

	RTable[firstbone] = {}
	RTable[firstbone].pos = ostable[firstbone].pos
	RTable[firstbone].ang = ostable[firstbone].ang
	if sbone.b == firstbone then
		RTable[firstbone].pos = sbone.p
		RTable[firstbone].ang = sbone.a
	end
	for i=1 + firstnphys,ent:GetBoneCount()-1 do
		local pb = BoneToPhysBone(ent,i)
		if ostable[pb] then
			local parent = ostable[pb].parent
			local bn = ent:GetBoneName(i)
			local ppos,pang = RTable[parent].pos,RTable[parent].ang
			local pos,ang = LocalToWorld(ostable[pb].pos,ostable[pb].ang,ppos,pang)
			if pb == sbone.b then
				pos = sbone.p
				ang = sbone.a
			end
			RTable[pb] = {}
			RTable[pb].pos = pos*1
			RTable[pb].ang = ang*1
		end
	end
	return RTable
end

//Set bone positions from the local positions on the offset table.
//And process IK chains.
function SetOffsets(tool,ent,ostable,sbone)
	local RTable = SetBoneOffsets(ent,ostable,sbone)
	
	if RTable then
		for k,v in pairs(ent.rgmIKChains) do
			if tobool(tool:GetClientNumber(DefIKnames[v.type],0)) then
				local RT = ProcessIK(ent,v,sbone,RTable)
				table.Merge(RTable,RT)
			end
		end
	end

	return RTable
	
end

//---
//Inverse kinematics library
//---

/*	Key function for IK chains: finding the knee position (in case of arms, it's elbow position)
	Once again, a math function, which I didn't fully make myself, and cannot explain much.
	Only that the arguments in order are: hip position, ankle position, thigh length, shin length, knee vector direction.
	
	Got the math from this thread:
	http://forum.unity3d.com/threads/40431-IK-Chain
*/
function FindKnee(pHip,pAnkle,fThigh,fShin,vKneeDir)
	local vB = pAnkle-pHip
    local LB = vB:Length()
    local aa = (LB*LB+fThigh*fThigh-fShin*fShin)/2/LB
    local bb = math.sqrt(fThigh*fThigh-aa*aa)
    local vF = vB:Cross(vKneeDir:Cross(vB))
	vB:Normalize()
	vF:Normalize()
    return pHip+(aa*vB)+(bb*vF)
end

//Process one IK chain, and set it's positions.
function ProcessIK(ent,IKTable,sbone,RT)

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
	
	local obj = RT[IKTable.ikhipparent]
	local hpos,hang = LocalToWorld(hippos,Angle(0,0,0),obj.pos,obj.ang)
	local HipPos = hpos*1
	
	local AnklePos,AnkleAng
	if IKTable.foot != sbone.b then
		AnklePos,AnkleAng = footpos*1,footang*1
	else
		AnklePos,AnkleAng = sbone.p,sbone.a
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

//Get IK chain's knee direction.
function GetKneeDir(ent,bHip,bKnee,bAnkle)
	local obj1 = ent:GetPhysicsObjectNum(bHip)
	local obj2 = ent:GetPhysicsObjectNum(bKnee)
	local obj3 = ent:GetPhysicsObjectNum(bAnkle)
	-- print(( obj2:GetPos()- ( obj3:GetPos() + ( ( obj1:GetPos() - obj3:GetPos() ) / 2 ) ) ):Normalize())
	local r = ( obj2:GetPos()- ( obj3:GetPos() + ( ( obj1:GetPos() - obj3:GetPos() ) / 2 ) ) )
	r:Normalize()
	return r
end

//Create the default IK chains for a ragdoll.
function CreateDefaultIKs(tool,ent)
	if !ent.rgmIKChains then ent.rgmIKChains = {} end
	for k,v in pairs(DefaultIK) do
		local b = BoneToPhysBone(ent,ent:LookupBone(v.hip))
		local b2 = BoneToPhysBone(ent,ent:LookupBone(v.knee))
		local b3 = BoneToPhysBone(ent,ent:LookupBone(v.foot))
		if (b and b > -1) and (b2 and b2 > -1) and (b3 and b3 > -1) then
			table.insert(ent.rgmIKChains,{hip = b,knee = b2,foot = b3,type = v.type})
		end
	end
end

//Returns true if given bone is part of an active IK chain. Also returns it's position on the chain.
function IsIKBone(tool,ent,bone)
	if !ent.rgmIKChains then return false end
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
	local _pos,_ang = ent:GetBonePosition(bone)
	if !_pos or !_ang then
		_pos,_ang = ent:GetPos(),ent:GetAngles()
	end
	_pos = _pos:ToScreen()
	local textpos = {x = _pos.x+5,y = _pos.y-5}
	surface.DrawCircle(_pos.x,_pos.y,2.5,Color(0,200,0,255))
	draw.SimpleText(name,"Default",textpos.x,textpos.y,Color(0,200,0,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_BOTTOM)
end