
---
-- By default, ragdoll's bones are moved relatively to their parent bone.
-- Constraints are a way to change this behaviour to something else.
---

RGM.ConstraintTypes = {
	IK = 1,
	Spine = 2	
};

local CONST = {};
CONST.__index = CONST;

function CONST.New(skeleton, type, bones)

	local const = {};
	if type == RGM.ConstraintTypes.IK then
		const = setmetatable(const, RGM.IKConstraint);
	elseif type == RGM.ConstraintTypes.Spine then
		const = setmetatable(const, RGM.SpineConstraint);
	end

	const.Bones = bones;

	const:Init();
	return const;

end

function CONST:Init()

	-- To be overridden

end

function CONST:BeforeChange(bone)

	-- To be overridden

end

function CONST:AfterChange(bone)

	-- To be overridden

end

RGM.Constraint = CONST;
RGM.Constraints = {};

include("constraints/ik.lua");