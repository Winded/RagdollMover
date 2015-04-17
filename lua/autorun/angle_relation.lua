
local function mod(value, n)
	return value - math.floor(value / n) * n;
end

local function diff(startAngle, endAngle)
	local a = endAngle - startAngle;
	a = mod(a + 180, 360) - 180;
	return a;
end

local ANGLE = FindMetaTable("Angle");
function ANGLE:Relation(otherAngle)
	local ra = Angle();
	ra.p = diff(otherAngle.p, self.p);
	ra.y = diff(otherAngle.y, self.y);
	ra.r = diff(otherAngle.r, self.r);
	return ra;
end
