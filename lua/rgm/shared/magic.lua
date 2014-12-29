
-- Math stuff

---
-- Key function for IK chains: finding the knee position (in case of arms, it's elbow position)
-- Got the math from this thread:
-- http://forum.unity3d.com/threads/40431-IK-Chain
---
function RGM.FindKnee(hipPosition, footPosition, thighLength, shinLength, kneeDirection)
	local vB = footPosition - hipPosition;
	local LB = vB:Length();
	local aa = (LB * LB + thighLength * thighLength - shinLength * shinLength) / 2 / LB;
	local bb = math.sqrt(thighLength * thighLength - aa * aa);
	local vF = vB:Cross(kneeDirection:Cross(vB));
	vB:Normalize();
	vF:Normalize();
	return hipPosition + (aa * vB) + (bb * vF);
end

---
-- Line-Plane intersection, and return the result vector
-- http://www.wiremod.com/forum/expression-2-discussion-help/19008-line-plane-intersection-tutorial.html
---
function RGM.IntersectRayWithPlane(planePoint, planeNormal, linePoint, lineNormal)
	local linePoint2 = linePoint + lineNormal;
	local x = planeNormal:Dot(planePoint - linePoint) / planeNormal:Dot(linePoint2 - linePoint);
	local vec = linePoint + x * (linePoint2 - linePoint);
	return vec;
end