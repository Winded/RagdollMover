
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
	RGM.SelectEntity(player, entity);
end

properties.Add("rgm_test", test);