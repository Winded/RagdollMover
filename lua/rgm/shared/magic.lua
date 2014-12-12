
-- Math stuff

---
-- Key function for IK chains: finding the knee position (in case of arms, it's elbow position)
-- Arguments in order are: hip position, ankle position, thigh length, shin length, knee vector direction.
-- 
-- Got the math from this thread:
-- http://forum.unity3d.com/threads/40431-IK-Chain
---
function RGM.FindKnee(pHip, pAnkle, fThigh, fShin, vKneeDir)
	local vB = pAnkle - pHip;
	local LB = vB:Length();
	local aa = (LB * LB + fThigh * fThigh - fShin * fShin) / 2 / LB;
	local bb = math.sqrt(fThigh * fThigh - aa * aa);
	local vF = vB:Cross(vKneeDir:Cross(vB));
	vB:Normalize();
	vF:Normalize();
	return pHip + (aa * vB) + (bb * vF);
end

---
-- Line-Plane intersection, and return the result vector
-- http://www.wiremod.com/forum/expression-2-discussion-help/19008-line-plane-intersection-tutorial.html
---
function RGM.IntersectRayWithPlane(planePoint, planeNormal, linePoint, lineNormal)
	local linePoint2 = linePoint + lineNormal;
	local x = (planeNormal:Dot(planePoint - linePoint)) / (planeNormal:Dot(linePoint2 - linePoint));
	local vec = linePoint + x * (linePoint2 - linePoint);
	return vec;
end