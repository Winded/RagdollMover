
local test = {};
test.MenuLabel = "RGM Test";
test.Order = 1000;

function test:Filter(entity)
	return IsValid(entity) and not entity:IsPlayer();
end

function test:Action(entity)
	self:MsgStart();
	net.WriteEntity(entity);
	self:MsgEnd();
end

function test:Receive(length, player)

	local entity = net.ReadEntity();
	local boneTest = table.First(RGM.Bones, function(item) return item.Entity == entity; end);
	if boneTest then
		return;
	end

	RGM.Bone.BuildBones(entity);

end

properties.Add("rgm_test", test);