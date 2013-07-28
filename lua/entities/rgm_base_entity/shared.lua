
ENT.Type = "anim";
ENT.Base = "base_entity";

function ENT:SharedInitialize()

	self:SetNoDraw(true);
	self:DrawShadow(false);
	self:SetCollisionBounds(Vector(-0.1,-0.1,-0.1),Vector(0.1,0.1,0.1));
	self:SetSolid(SOLID_VPHYSICS);
	self:SetNotSolid(true);
	
	self.m_AllowedFuncs = {};

end

---
--Send a net message. (To server in client, and to entity's player in server).
---
function ENT:SendMessage(func, ...)
	local args = {...};
	
	net.Start("rgmEntityMessage");
	
	net.WriteEntity(self);
	
	net.WriteString(func);
	
	net.WriteInt(#args, 32);
	for i, v in ipairs(args) do
		net.WriteType(v);
	end
	
	if SERVER then
		net.Send(self:GetPlayer());
	else
		net.SendToServer();
	end
end

---
--Gets called when the entity recieves a message.
---
function ENT:ReceiveMessage(func, args)
	
	--Its essential to have a filter of allowed functions on serverside,
	--because you wouldn't want clients to control the entity.
	if not table.HasValue(self.m_AllowedFuncs, func) then return; end
	
	if not self[func] then return; end
	self[func](unpack(args));
	
end

net.Receive("rgmEntityMessage", function(len, pl)
	if not pl then pl = NULL; end
	
	local ent = net.ReadEntity();
	
	local func = net.ReadString();
	
	local argc = net.ReadInt(32);
	local args = {};
	for i=1, argc do
		args[i] = net.ReadType();
	end
	
	ent:ReceiveMessage(func, args);
end);