
/*
	Other functionality that isn't part of the rgm module.
*/

local TYPE_ENTITY	 = 1;
local TYPE_NUMBER	 = 2;
local TYPE_VECTOR	 = 3;
local TYPE_ANGLE	 = 4;
local TYPE_BOOL		 = 5;

local function Sync(self)
	if CLIENT or !self.rgm then return end
	
	net.Start("rgmSync");
	
	local count = table.Count(self.rgm);
	net.WriteInt(count, 32);
	
	for k,v in pairs(self.rgm) do
		net.WriteString(k);
		
		local Type = string.lower(type(v));
		if Type == "entity" then
			net.WriteInt(TYPE_ENTITY, 8);
			net.WriteEntity(v);
		elseif Type == "number" then
			net.WriteInt(TYPE_NUMBER, 8);
			net.WriteFloat(v);
		elseif Type == "vector" then
			net.WriteInt(TYPE_VECTOR, 8);
			net.WriteVector(v);
		elseif Type == "angle" then
			net.WriteInt(TYPE_ANGLE, 8);
			net.WriteAngle(v);
		elseif Type == "boolean" then
			net.WriteInt(TYPE_BOOL, 8);
			net.WriteBit(v);
		end
	end
	
	net.Send(self);
end

local function SyncOne(self, name)
	if CLIENT or !self.rgm then return end
	
	local v = self.rgm[name];
	if v == nil then return end
	
	net.Start("rgmSync");
	
	local count = 1;
	net.WriteInt(count, 32);
	
	net.WriteString(name);
	
	local Type = string.lower(type(v));
	if Type == "entity" then
		net.WriteInt(TYPE_ENTITY, 8);
		net.WriteEntity(v);
	elseif Type == "number" then
		net.WriteInt(TYPE_NUMBER, 8);
		net.WriteFloat(v);
	elseif Type == "vector" then
		net.WriteInt(TYPE_VECTOR, 8);
		net.WriteVector(v);
	elseif Type == "angle" then
		net.WriteInt(TYPE_ANGLE, 8);
		net.WriteAngle(v);
	elseif Type == "boolean" then
		net.WriteInt(TYPE_BOOL, 8);
		net.WriteBit(v);
	end
	
	net.Send(self);
end

hook.Add("PlayerSpawn","rgmSpawn",function(pl)
	if pl.rgm == nil then
		pl.rgm = {};
		pl.rgmSync = Sync;
		pl.rgmSyncOne = SyncOne;
	end
end)

if SERVER then

util.AddNetworkString("rgmSync");

else

net.Receive("rgmSync",function(len)
	local pl = LocalPlayer();
	if !pl.rgm then pl.rgm = {}; end
	
	local count = net.ReadInt(32);
	
	for i=1, count do
		local name = net.ReadString();
		
		local type = net.ReadInt(8);
		local value = nil
		if type == TYPE_ENTITY then
			value = net.ReadEntity();
		elseif type == TYPE_NUMBER then
			value = net.ReadFloat();
		elseif type == TYPE_VECTOR then
			value = net.ReadVector();
		elseif type == TYPE_ANGLE then
			value = net.ReadAngle();
		elseif type == TYPE_BOOL then
			value = net.ReadBit() == 1;
		end
		pl.rgm[name] = value;
	end
end)

end