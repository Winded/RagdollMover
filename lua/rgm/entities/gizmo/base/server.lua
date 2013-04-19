
function ENT:BuildAxes()
	self.m_Axes = {};
	
	net.Start("rgmGizmoSetAxes");
	
		net.WriteEntity(self);
		
		net.WriteInt(table.Count(axes), 32);
		for k,v in pairs(axes) do
			net.WriteString(k);
			net.WriteEntity(v);
		end
		
	net.Send(self:GetThread():GetPlayer());
end

function ENT:SendAxes()
	
	local msg = {};
	
	
end