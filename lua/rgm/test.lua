
-- Test utilities

function RGM.TestSelect(player, boneName)
	local entity = player.RGMSelectedEntity;
	local skeleton = entity.RGMSkeleton;
	local bone = entity:LookupBone(boneName);
	if not bone then
		error("Invalid bone");
	end
	bone = BoneToPhysBone(entity, bone);
	bone = table.First(skeleton.Bones, function(item) return item.Index == bone; end);
	return entity, skeleton, bone;
end

function RGM.TestConstraint(skeleton)

	local entity = skeleton.Entity;

	local hipBone = BoneToPhysBone(entity, entity:LookupBone("bip_upperArm_R"));
	local kneeBone = BoneToPhysBone(entity, entity:LookupBone("bip_lowerArm_R"));
	local footBone = BoneToPhysBone(entity, entity:LookupBone("bip_hand_R"));

	local hip = table.First(skeleton.Bones, function(item) return item.Index == hipBone; end);
	local knee = table.First(skeleton.Bones, function(item) return item.Index == kneeBone; end);
	local foot = table.First(skeleton.Bones, function(item) return item.Index == footBone; end);

	local c = RGM.Constraint.New(skeleton, RGM.ConstraintTypes.IK, {hip, knee, foot});
	skeleton:AddConstraint(c);
	return c;

end

function RGM.TestMove(skeleton, bone, vec)
	skeleton:OnGrab(bone);
	bone:SetPos(bone:GetPos() + vec);
	skeleton:OnMoveUpdate(bone);
	skeleton:OnRelease(bone);
end