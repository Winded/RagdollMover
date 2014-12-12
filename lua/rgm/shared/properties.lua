
local Move = {};
Move.MenuLabel = "Move ragdoll";
Move.Order = 1000;

function Move:Filter(entity)
	local player = LocalPlayer();
	return IsValid(entity) and not entity:IsPlayer() and player.RGMSelectedEntity ~= entity;
end

function Move:Action(entity)
	self:MsgStart();
	net.WriteEntity(entity);
	self:MsgEnd();
end

function Move:Receive(length, player)
	local entity = net.ReadEntity();
	RGM.SelectEntity(player, entity);
end

properties.Add("rgm_move", Move);

local Stop = {};
Stop.MenuLabel = "Stop moving";
Stop.Order = 1001;

function Stop:Filter(entity)
	local player = LocalPlayer();
	return IsValid(entity) and player.RGMSelectedEntity == entity;
end

function Stop:Action(entity)
	self:MsgStart();
	net.WriteEntity(entity);
	self:MsgEnd();
end

function Stop:Receive(length, player)
	if IsValid(player.RGMSelectedEntity) then
		RGM.SelectEntity(player, nil);
	end
end

properties.Add("rgm_stop", Stop);